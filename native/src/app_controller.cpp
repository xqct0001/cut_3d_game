#include "app_controller.h"
#include "display_state.h"
#include "profile_binding.h"
#include "status_text.h"

#include <QAction>
#include <QApplication>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMenu>
#include <QQuickWindow>
#include <QStyle>
#include <QSystemTrayIcon>
#include <QTimer>

#include <cmath>

namespace {

constexpr float kTau = 6.28318530717958647692f;
constexpr int kBindScanAttempts = 25;
constexpr int kBindScanInitialDelayMs = 350;
constexpr int kBindScanIntervalMs = 200;

QString legacyAppStatePath()
{
    return QDir(QCoreApplication::applicationDirPath()).filePath("profiles/app-state.json");
}

QString normalizePattern(const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    if (normalized == "dynamic" || normalized == "regular") {
        return normalized;
    }
    return "dynamic";
}

QString normalizeVisibility(const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    if (normalized == "standard" || normalized == "larger_dots" || normalized == "more_dots") {
        return normalized;
    }
    return "standard";
}

QIcon resolveAppIcon(QApplication *app)
{
    QIcon icon(":/src/comfort_cues/ui/assets/comfort-cues.ico");
    if (!icon.isNull()) {
        return icon;
    }
    icon = QIcon(":/src/comfort_cues/ui/assets/tray-dog.ico");
    if (!icon.isNull()) {
        return icon;
    }
    return app != nullptr ? app->style()->standardIcon(QStyle::SP_ComputerIcon) : QIcon();
}

QString windowDebugLine(const WindowInfo &window)
{
    return QString("%1 title=\"%2\" mode=%3 supported=%4 rect=%5,%6 %7x%8 reason=\"%9\"")
        .arg(window.exeName,
             window.title.left(80),
             window.mode,
             window.supported ? QStringLiteral("true") : QStringLiteral("false"))
        .arg(window.rect.x)
        .arg(window.rect.y)
        .arg(window.rect.width)
        .arg(window.rect.height)
        .arg(window.reason);
}

QString smokeProgressPath()
{
    const QString runtimePath = qEnvironmentVariable("CC_RUNTIME_PROGRESS_PATH");
    if (!runtimePath.isEmpty()) {
        return runtimePath;
    }
    return qEnvironmentVariable("CC_SMOKE_PROGRESS_PATH");
}

void appendRuntimeProgress(const QString &message)
{
    const QString path = smokeProgressPath();
    if (path.isEmpty()) {
        return;
    }

    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        return;
    }

    file.write(message.toUtf8());
    file.write("\n");
    file.close();
}

} // namespace

AppController::AppController(QApplication *app, const QString &dataRoot, const QString &statePath, QObject *parent)
    : QObject(parent)
    , m_dataRoot(dataRoot.isEmpty() ? defaultDataRoot() : dataRoot)
    , m_profilesDir(QDir(m_dataRoot).filePath("profiles"))
    , m_appStatePath(statePath.isEmpty() ? defaultAppStatePath() : statePath)
    , m_profileStore(m_profilesDir)
    , m_app(app)
    , m_inputSource(this)
    , m_runtime(&m_tracker, &m_inputSource, &m_profileStore)
{
    const bool smokeMode = !qEnvironmentVariable("CC_SMOKE_TEST_OUTPUT").isEmpty();
    appendRuntimeProgress("app_controller: constructor entered");
    const QString legacyState = legacyAppStatePath();
    if (QFileInfo::exists(m_appStatePath)) {
        m_appState = loadAppState(m_appStatePath);
    } else if (QFileInfo::exists(legacyState)) {
        m_appState = loadAppState(legacyState);
        saveAppState(m_appStatePath, m_appState);
    } else {
        m_appState = loadAppState(m_appStatePath);
    }
    appendRuntimeProgress("app_controller: app state ready");

    ensureProfileTemplates(m_profilesDir);
    appendRuntimeProgress("app_controller: profile templates ensured");
    m_profileStore = ProfileStore::load(m_profilesDir);
    appendRuntimeProgress("app_controller: profile store loaded");
    m_selectedProfile = m_profileStore.defaultProfile();
    appendRuntimeProgress(QString("app_controller: selected profile resolved (%1)").arg(m_selectedProfile.name));

    if (!smokeMode) {
        m_inputSource.start();
    }
    m_timer = new QTimer(this);
    m_timer->setInterval(16);
    connect(m_timer, &QTimer::timeout, this, &AppController::tick);

    if (m_app != nullptr && !smokeMode) {
        m_tray = new QSystemTrayIcon(resolveAppIcon(m_app), m_app);
        auto *menu = new QMenu();
        m_enableAction = menu->addAction("Enable");
        m_disableAction = menu->addAction("Disable");
        menu->addSeparator();
        m_quitAction = menu->addAction("Quit");

        connect(m_enableAction, &QAction::triggered, this, &AppController::enableApp);
        connect(m_disableAction, &QAction::triggered, this, &AppController::disableApp);
        connect(m_quitAction, &QAction::triggered, this, &AppController::quitApplication);
        connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
            if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
                appendRuntimeProgress("app_controller: tray icon activated");
                openSettings();
            }
        });
        m_tray->setContextMenu(menu);
        m_tray->show();
    }

    m_appEnabled = m_appState.appEnabled;
    if (m_appEnabled) {
        m_statusText = "Comfort Cues running in background.";
    } else {
        setDisabledView();
    }
    refreshTrayIcon();
    m_elapsedTimer.start();
    appendRuntimeProgress("app_controller: constructor complete");
}

void AppController::attachWindows(QQuickWindow *overlayWindow, QQuickWindow *settingsWindow)
{
    const bool smokeMode = !qEnvironmentVariable("CC_SMOKE_TEST_OUTPUT").isEmpty();
    m_overlayWindow = overlayWindow;
    m_settingsWindow = settingsWindow;
    if (m_app != nullptr) {
        const QIcon icon = resolveAppIcon(m_app);
        m_app->setWindowIcon(icon);
        if (m_settingsWindow != nullptr) {
            m_settingsWindow->setIcon(icon);
        }
    }
    if (!smokeMode) {
        configureOverlayWindow(m_overlayWindow);
    }
    if (m_timer != nullptr && !smokeMode) {
        m_timer->start();
    }
    if (m_settingsWindow != nullptr && !smokeMode) {
        connect(m_settingsWindow, &QQuickWindow::visibleChanged, this, [this]() {
            appendRuntimeProgress(QString("app_controller: settings window visible=%1")
                                      .arg(m_settingsWindow != nullptr && m_settingsWindow->isVisible() ? "true" : "false"));
        });
    }
    appendRuntimeProgress("app_controller: windows attached");
}

bool AppController::shouldShowWindowOnLaunch() const
{
    return !m_appState.launchToTray;
}

void AppController::completeFirstRun()
{
    if (m_appState.launchToTray) {
        return;
    }
    m_appState.launchToTray = true;
    persistAppState();
    appendRuntimeProgress("app_controller: completed first-run persistence");
}

void AppController::setSelectedProfileName(const QString &value)
{
    if (!m_profileStore.hasProfile(value)) {
        return;
    }
    m_selectedProfile = m_profileStore.cloneProfile(value);
    emit profileChanged();
}

void AppController::setYawGain(float value)
{
    m_selectedProfile.yawGain = value;
    emit profileChanged();
}

void AppController::setUiLanguage(const QString &value)
{
    const QString normalized = normalizeLanguageCode(value);
    if (m_appState.uiLanguage == normalized) {
        return;
    }
    m_appState.uiLanguage = normalized;
    persistAppState();
    refreshTrayIcon();
    emit stateChanged();
    appendRuntimeProgress(QString("app_controller: ui language=%1").arg(normalized));
}

void AppController::setPitchGain(float value)
{
    m_selectedProfile.pitchGain = value;
    emit profileChanged();
}

void AppController::setDeadzone(float value)
{
    m_selectedProfile.deadzone = value;
    emit profileChanged();
}

void AppController::setMaxOpacity(float value)
{
    m_selectedProfile.maxOpacity = value;
    emit profileChanged();
}

void AppController::setFadeInMs(float value)
{
    m_selectedProfile.fadeInMs = value;
    emit profileChanged();
}

void AppController::setFadeOutMs(float value)
{
    m_selectedProfile.fadeOutMs = value;
    emit profileChanged();
}

void AppController::setEnableMouse(bool value)
{
    m_selectedProfile.enableMouse = value;
    emit profileChanged();
}

void AppController::setEnableGamepad(bool value)
{
    m_selectedProfile.enableGamepad = value;
    emit profileChanged();
}

void AppController::setSafeMode(bool value)
{
    m_selectedProfile.safeMode = value;
    emit profileChanged();
}

void AppController::setCuePattern(const QString &value)
{
    m_selectedProfile.cuePattern = normalizePattern(value);
    emit profileChanged();
}

void AppController::setCueVisibility(const QString &value)
{
    m_selectedProfile.cueVisibility = normalizeVisibility(value);
    emit profileChanged();
}

void AppController::setDebugOverlayEnabled(bool value)
{
    m_debugOverlayEnabled = value;
    emit stateChanged();
    emit cueChanged();
    appendRuntimeProgress(QString("app_controller: debug overlay=%1").arg(value ? "true" : "false"));
}

void AppController::setAdvancedVisible(bool value)
{
    m_advancedVisible = value;
    emit stateChanged();
    appendRuntimeProgress(QString("app_controller: advanced visible=%1").arg(value ? "true" : "false"));
}

void AppController::setSimulatorEnabled(bool value)
{
    m_runtime.simulation().enabled = value;
    emit stateChanged();
}

void AppController::setSimYaw(float value)
{
    m_runtime.simulation().yaw = value;
    emit stateChanged();
}

void AppController::setSimPitch(float value)
{
    m_runtime.simulation().pitch = value;
    emit stateChanged();
}

void AppController::setSimLateral(float value)
{
    m_runtime.simulation().lateral = value;
    emit stateChanged();
}

void AppController::openSettings()
{
    if (m_settingsWindow == nullptr) {
        appendRuntimeProgress("app_controller: openSettings skipped (no settings window)");
        return;
    }
    m_settingsWindow->show();
    m_settingsWindow->raise();
    m_settingsWindow->requestActivate();
    appendRuntimeProgress("app_controller: settings window opened");
}

void AppController::reloadProfiles()
{
    const QString targetName = m_profileStore.hasProfile(m_selectedProfile.name)
        ? m_selectedProfile.name
        : m_profileStore.defaultProfile().name;
    m_profileStore = ProfileStore::load(m_profilesDir);
    m_selectedProfile = m_profileStore.cloneProfile(
        m_profileStore.hasProfile(targetName) ? targetName : m_profileStore.defaultProfile().name
    );
    emit profilesChanged();
    emit profileChanged();
}

void AppController::enableApp()
{
    m_appEnabled = true;
    m_statusText = "Comfort Cues running in background.";
    persistAppState();
    refreshTrayIcon();
    emit stateChanged();
    appendRuntimeProgress("app_controller: app enabled");
}

void AppController::disableApp()
{
    m_appEnabled = false;
    m_runtime.reset();
    setDisabledView();
    persistAppState();
    refreshTrayIcon();
    emit stateChanged();
    emit cueChanged();
    appendRuntimeProgress("app_controller: app disabled");
}

void AppController::saveSelectedProfile()
{
    const QString saved = m_profileStore.saveProfile(m_selectedProfile);
    m_statusText = QString("Saved profile to %1").arg(QFileInfo(saved).fileName());
    emit stateChanged();
    emit profilesChanged();
    appendRuntimeProgress(QString("app_controller: profile saved (%1)").arg(QFileInfo(saved).fileName()));
}

void AppController::bindCurrentWindow()
{
    if (m_bindInProgress) {
        return;
    }

    if (m_settingsWindow != nullptr) {
        m_bindInProgress = true;
        m_bindScanAttemptsRemaining = kBindScanAttempts;
        m_statusText = "Binding: scanning visible windows for a game.";
        emit stateChanged();
        appendRuntimeProgress("app_controller: bind scan started");
        QTimer::singleShot(kBindScanInitialDelayMs, this, &AppController::scanForBindableWindow);
        return;
    }

    const std::optional<WindowInfo> window = m_runtime.bestVisibleWindow();
    if (!window.has_value()) {
        failBindWindow("Bind failed: no visible game window found.",
                       "app_controller: bind failed (no visible window)");
        return;
    }

    finishBindWindow(*window);
}

void AppController::scanForBindableWindow()
{
    if (!m_bindInProgress) {
        return;
    }

    const bool shouldLogCandidates = m_bindScanAttemptsRemaining == kBindScanAttempts;
    if (shouldLogCandidates) {
        const QVector<WindowInfo> windows = m_runtime.visibleWindows();
        appendRuntimeProgress(QString("app_controller: bind scan candidates=%1").arg(windows.size()));
        const int limit = qMin(windows.size(), 12);
        for (int i = 0; i < limit; ++i) {
            appendRuntimeProgress(QString("app_controller: candidate[%1] %2").arg(i).arg(windowDebugLine(windows.at(i))));
        }
    }

    const std::optional<WindowInfo> window = m_runtime.bestVisibleWindow();
    if (window.has_value() && window->supported) {
        appendRuntimeProgress(QString("app_controller: bind selected %1").arg(windowDebugLine(*window)));
        finishBindWindow(*window);
        return;
    }

    --m_bindScanAttemptsRemaining;
    if (m_bindScanAttemptsRemaining > 0) {
        QTimer::singleShot(kBindScanIntervalMs, this, &AppController::scanForBindableWindow);
        return;
    }

    if (window.has_value()) {
        m_activeWindowTitle = window->title;
        m_activeWindowMode = window->mode;
        m_activeExeName = window->exeName;
        appendRuntimeProgress(QString("app_controller: bind best unsupported %1").arg(windowDebugLine(*window)));
        failBindWindow(QString("Bind failed: detected window is too small or unavailable (%1).").arg(window->exeName),
                       QString("app_controller: bind scan failed (unsupported visible window: %1 - %2)")
                           .arg(window->exeName, window->reason));
        return;
    }

    failBindWindow("Bind failed: no visible game window found.",
                   "app_controller: bind scan failed (no visible window)");
}

void AppController::finishBindWindow(const WindowInfo &window)
{
    m_activeWindowTitle = window.title;
    m_activeWindowMode = window.mode;
    m_activeExeName = window.exeName;
    if (!window.supported) {
        failBindWindow(QString("Bind failed: %1 - %2").arg(window.exeName, window.reason),
                       QString("app_controller: bind failed (%1 - %2)").arg(window.exeName, window.reason));
        return;
    }

    Profile profile = bindingProfileForWindow(m_selectedProfile, window);
    appendUniqueNormalized(profile.matchExe, window.exeName);
    for (const QString &token : titleTokens(window.title)) {
        appendUniqueNormalized(profile.matchTitle, token);
    }
    profile.lastBoundExe = window.exeName.toLower();
    profile.lastBoundTitle = window.title.toLower();
    const QString savedProfileName = profile.name;
    m_profileStore.saveProfile(profile);
    m_profileStore = ProfileStore::load(m_profilesDir);
    m_selectedProfile = m_profileStore.hasProfile(savedProfileName)
        ? m_profileStore.cloneProfile(savedProfileName)
        : m_profileStore.defaultProfile();
    m_statusText = QString("Bound current window to %1 profile: %2").arg(savedProfileName, window.exeName);
    m_activeProfileName = savedProfileName;
    m_bindInProgress = false;
    restoreSettingsWindow();
    emit profilesChanged();
    emit profileChanged();
    emit stateChanged();
    appendRuntimeProgress(QString("app_controller: bind succeeded (%1)").arg(window.exeName));
}

void AppController::failBindWindow(const QString &statusText, const QString &progressText)
{
    m_statusText = statusText;
    m_bindInProgress = false;
    restoreSettingsWindow();
    emit stateChanged();
    appendRuntimeProgress(progressText);
}

void AppController::restoreSettingsWindow()
{
    if (m_settingsWindow == nullptr) {
        return;
    }
    m_settingsWindow->show();
    m_settingsWindow->raise();
    m_settingsWindow->requestActivate();
}

void AppController::quitApplication()
{
    if (m_tray != nullptr) {
        m_tray->hide();
    }
    if (m_app != nullptr) {
        m_app->quit();
    }
    appendRuntimeProgress("app_controller: quit requested");
}

void AppController::resetSimulator()
{
    m_runtime.simulation().yaw = 0.0;
    m_runtime.simulation().pitch = 0.0;
    m_runtime.simulation().lateral = 0.0;
    emit stateChanged();
}

void AppController::tick()
{
    if (!m_appEnabled) {
        setDisabledView();
        emit stateChanged();
        emit cueChanged();
        return;
    }

    const double timestampMs = m_elapsedTimer.nsecsElapsed() / 1000000.0;
    RuntimeViewState view = m_runtime.tick(timestampMs, m_selectedProfile);
    Rect overlayRect = view.overlayRect;
    if (m_overlayWindow != nullptr) {
        overlayRect = resolveOverlayRect(m_overlayWindow, overlayRect);
    }

    const float baseCueEnergy = view.cueState.energy;
    advanceFlowPhase(timestampMs, baseCueEnergy);
    m_statusText = view.statusText;
    m_activeProfileName = view.activeProfileName;
    m_activeWindowTitle = view.activeWindowTitle;
    m_activeWindowMode = view.supportMode;
    m_activeExeName = extractExeNameFromStatus(view.statusText);
    m_overlayVisible = view.overlayVisible;
    m_overlayX = overlayRect.x;
    m_overlayY = overlayRect.y;
    m_overlayWidth = overlayRect.width;
    m_overlayHeight = overlayRect.height;
    m_leftAlpha = view.cueState.left_alpha;
    m_rightAlpha = view.cueState.right_alpha;
    m_topAlpha = view.cueState.top_alpha;
    m_bottomAlpha = view.cueState.bottom_alpha;
    m_centerBias = view.cueState.center_bias;
    m_leftDensity = view.cueState.left_density;
    m_rightDensity = view.cueState.right_density;
    m_topDensity = view.cueState.top_density;
    m_bottomDensity = view.cueState.bottom_density;
    m_centerSafeRatio = view.cueState.center_safe_ratio;
    m_cueMotionX = view.cueState.motion_x;
    m_cueMotionY = view.cueState.motion_y;
    m_cueEnergy = scaledCueEnergy(baseCueEnergy, m_debugOverlayEnabled, m_selectedProfile.debugOpacityMultiplier);
    CueDisplayValues cueValues;
    cueValues.overlayVisible = m_overlayVisible;
    cueValues.leftAlpha = m_leftAlpha;
    cueValues.rightAlpha = m_rightAlpha;
    cueValues.topAlpha = m_topAlpha;
    cueValues.bottomAlpha = m_bottomAlpha;
    cueValues.leftDensity = m_leftDensity;
    cueValues.rightDensity = m_rightDensity;
    cueValues.topDensity = m_topDensity;
    cueValues.bottomDensity = m_bottomDensity;
    applyDebugCueVisibility(cueValues, m_debugOverlayEnabled, m_selectedProfile.debugOpacityMultiplier);
    m_leftAlpha = cueValues.leftAlpha;
    m_rightAlpha = cueValues.rightAlpha;
    m_topAlpha = cueValues.topAlpha;
    m_bottomAlpha = cueValues.bottomAlpha;
    m_leftDensity = cueValues.leftDensity;
    m_rightDensity = cueValues.rightDensity;
    m_topDensity = cueValues.topDensity;
    m_bottomDensity = cueValues.bottomDensity;

    if (m_overlayWindow != nullptr) {
        applyOverlayGeometry(m_overlayWindow, overlayRect);
    }

    emit stateChanged();
    emit cueChanged();
}

void AppController::persistAppState()
{
    m_appState.appEnabled = m_appEnabled;
    saveAppState(m_appStatePath, m_appState);
}

void AppController::advanceFlowPhase(double timestampMs, float cueEnergy)
{
    const double previous = m_lastFlowTimestampMs;
    const double dtMs = previous < 0.0 ? 16.0 : qMax(1.0, timestampMs - previous);
    const QByteArray pattern = m_selectedProfile.cuePattern.toUtf8();
    const float speed = cc_flow_speed(pattern.constData(), cueEnergy);

    m_lastFlowTimestampMs = timestampMs;
    if (speed <= 0.0f) {
        return;
    }
    m_flowPhase = std::fmod(m_flowPhase + static_cast<float>(dtMs / 1000.0 * speed), kTau);
}

void AppController::setDisabledView()
{
    m_statusText = "Comfort Cues disabled.";
    m_activeWindowTitle.clear();
    m_activeProfileName.clear();
    m_activeWindowMode = "disabled";
    m_activeExeName.clear();
    m_overlayVisible = false;
    m_leftAlpha = 0.0f;
    m_rightAlpha = 0.0f;
    m_topAlpha = 0.0f;
    m_bottomAlpha = 0.0f;
    m_centerBias = 0.0f;
    m_leftDensity = 0.0f;
    m_rightDensity = 0.0f;
    m_topDensity = 0.0f;
    m_bottomDensity = 0.0f;
    m_centerSafeRatio = 0.74f;
    m_cueMotionX = 0.0f;
    m_cueMotionY = 0.0f;
    m_cueEnergy = 0.0f;
    m_flowPhase = 0.0f;
    m_lastFlowTimestampMs = -1.0;
}

void AppController::refreshTrayIcon()
{
    if (m_tray == nullptr) {
        return;
    }
    const TrayText text = trayTextForLanguage(m_appState.uiLanguage);
    m_tray->setToolTip(QString("Comfort Cues\n%1\n%2\n%3")
                           .arg(m_appEnabled ? text.enabledText : text.disabledText, text.modeText, text.clickHint));
    if (m_enableAction != nullptr) {
        m_enableAction->setText(text.enableAction);
        m_enableAction->setEnabled(!m_appEnabled);
    }
    if (m_disableAction != nullptr) {
        m_disableAction->setText(text.disableAction);
        m_disableAction->setEnabled(m_appEnabled);
    }
    if (m_quitAction != nullptr) {
        m_quitAction->setText(text.quitAction);
    }
}
