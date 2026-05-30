#ifndef APP_CONTROLLER_H
#define APP_CONTROLLER_H

#include "app_state.h"
#include "overlay_utils.h"
#include "profile_store.h"
#include "runtime_service.h"

#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QStringList>
#include <QVariantList>

class QAction;
class QApplication;
class QQuickWindow;
class QSystemTrayIcon;
class QTimer;

class AppController : public QObject {
    Q_OBJECT

    Q_PROPERTY(QStringList profileOptions READ profileOptions NOTIFY profilesChanged)
    Q_PROPERTY(QString selectedProfileName READ selectedProfileName WRITE setSelectedProfileName NOTIFY profileChanged)
    Q_PROPERTY(bool overlayVisible READ overlayVisible NOTIFY stateChanged)
    Q_PROPERTY(int overlayX READ overlayX NOTIFY stateChanged)
    Q_PROPERTY(int overlayY READ overlayY NOTIFY stateChanged)
    Q_PROPERTY(int overlayWidth READ overlayWidth NOTIFY stateChanged)
    Q_PROPERTY(int overlayHeight READ overlayHeight NOTIFY stateChanged)
    Q_PROPERTY(float leftAlpha READ leftAlpha NOTIFY cueChanged)
    Q_PROPERTY(float rightAlpha READ rightAlpha NOTIFY cueChanged)
    Q_PROPERTY(float topAlpha READ topAlpha NOTIFY cueChanged)
    Q_PROPERTY(float bottomAlpha READ bottomAlpha NOTIFY cueChanged)
    Q_PROPERTY(float centerBias READ centerBias NOTIFY cueChanged)
    Q_PROPERTY(float leftDensity READ leftDensity NOTIFY cueChanged)
    Q_PROPERTY(float rightDensity READ rightDensity NOTIFY cueChanged)
    Q_PROPERTY(float topDensity READ topDensity NOTIFY cueChanged)
    Q_PROPERTY(float bottomDensity READ bottomDensity NOTIFY cueChanged)
    Q_PROPERTY(float centerSafeRatio READ centerSafeRatio NOTIFY cueChanged)
    Q_PROPERTY(float cueMotionX READ cueMotionX NOTIFY cueChanged)
    Q_PROPERTY(float cueMotionY READ cueMotionY NOTIFY cueChanged)
    Q_PROPERTY(float cueEnergy READ cueEnergy NOTIFY cueChanged)
    Q_PROPERTY(float flowPhase READ flowPhase NOTIFY cueChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY stateChanged)
    Q_PROPERTY(QString activeWindowTitle READ activeWindowTitle NOTIFY stateChanged)
    Q_PROPERTY(QString activeProfileName READ activeProfileName NOTIFY stateChanged)
    Q_PROPERTY(QString activeWindowMode READ activeWindowMode NOTIFY stateChanged)
    Q_PROPERTY(QString activeExeName READ activeExeName NOTIFY stateChanged)
    Q_PROPERTY(QString boundWindowTitle READ boundWindowTitle NOTIFY stateChanged)
    Q_PROPERTY(QString boundExeName READ boundExeName NOTIFY stateChanged)
    Q_PROPERTY(bool bindInProgress READ bindInProgress NOTIFY stateChanged)
    Q_PROPERTY(QVariantList bindWindowCandidates READ bindWindowCandidates NOTIFY bindCandidatesChanged)
    Q_PROPERTY(int selectedBindWindowIndex READ selectedBindWindowIndex WRITE setSelectedBindWindowIndex NOTIFY bindCandidatesChanged)
    Q_PROPERTY(bool appEnabled READ appEnabled NOTIFY stateChanged)
    Q_PROPERTY(QString uiLanguage READ uiLanguage WRITE setUiLanguage NOTIFY stateChanged)
    Q_PROPERTY(float yawGain READ yawGain WRITE setYawGain NOTIFY profileChanged)
    Q_PROPERTY(float pitchGain READ pitchGain WRITE setPitchGain NOTIFY profileChanged)
    Q_PROPERTY(float deadzone READ deadzone WRITE setDeadzone NOTIFY profileChanged)
    Q_PROPERTY(float maxOpacity READ maxOpacity WRITE setMaxOpacity NOTIFY profileChanged)
    Q_PROPERTY(float fadeInMs READ fadeInMs WRITE setFadeInMs NOTIFY profileChanged)
    Q_PROPERTY(float fadeOutMs READ fadeOutMs WRITE setFadeOutMs NOTIFY profileChanged)
    Q_PROPERTY(bool enableMouse READ enableMouse WRITE setEnableMouse NOTIFY profileChanged)
    Q_PROPERTY(bool enableGamepad READ enableGamepad WRITE setEnableGamepad NOTIFY profileChanged)
    Q_PROPERTY(bool safeMode READ safeMode WRITE setSafeMode NOTIFY profileChanged)
    Q_PROPERTY(QString cuePattern READ cuePattern WRITE setCuePattern NOTIFY profileChanged)
    Q_PROPERTY(QString cueVisibility READ cueVisibility WRITE setCueVisibility NOTIFY profileChanged)
    Q_PROPERTY(bool debugOverlayEnabled READ debugOverlayEnabled WRITE setDebugOverlayEnabled NOTIFY stateChanged)
    Q_PROPERTY(bool advancedVisible READ advancedVisible WRITE setAdvancedVisible NOTIFY stateChanged)
    Q_PROPERTY(bool simulatorEnabled READ simulatorEnabled WRITE setSimulatorEnabled NOTIFY stateChanged)
    Q_PROPERTY(float simYaw READ simYaw WRITE setSimYaw NOTIFY stateChanged)
    Q_PROPERTY(float simPitch READ simPitch WRITE setSimPitch NOTIFY stateChanged)
    Q_PROPERTY(float simLateral READ simLateral WRITE setSimLateral NOTIFY stateChanged)
    Q_PROPERTY(QStringList cuePatternOptions READ cuePatternOptions CONSTANT)
    Q_PROPERTY(QStringList cueVisibilityOptions READ cueVisibilityOptions CONSTANT)

public:
    explicit AppController(QApplication *app, const QString &dataRoot = QString(), const QString &statePath = QString(),
                           QObject *parent = nullptr);

    void attachWindows(QQuickWindow *overlayWindow, QQuickWindow *settingsWindow);
    bool shouldShowWindowOnLaunch() const;
    void completeFirstRun();

    QStringList profileOptions() const { return m_profileStore.profileNames(); }
    QString selectedProfileName() const { return m_selectedProfile.name; }
    bool overlayVisible() const { return m_overlayVisible; }
    int overlayX() const { return m_overlayX; }
    int overlayY() const { return m_overlayY; }
    int overlayWidth() const { return m_overlayWidth; }
    int overlayHeight() const { return m_overlayHeight; }
    float leftAlpha() const { return m_leftAlpha; }
    float rightAlpha() const { return m_rightAlpha; }
    float topAlpha() const { return m_topAlpha; }
    float bottomAlpha() const { return m_bottomAlpha; }
    float centerBias() const { return m_centerBias; }
    float leftDensity() const { return m_leftDensity; }
    float rightDensity() const { return m_rightDensity; }
    float topDensity() const { return m_topDensity; }
    float bottomDensity() const { return m_bottomDensity; }
    float centerSafeRatio() const { return m_centerSafeRatio; }
    float cueMotionX() const { return m_cueMotionX; }
    float cueMotionY() const { return m_cueMotionY; }
    float cueEnergy() const { return m_cueEnergy; }
    float flowPhase() const { return m_flowPhase; }
    QString statusText() const { return m_statusText; }
    QString activeWindowTitle() const { return m_activeWindowTitle; }
    QString activeProfileName() const { return m_activeProfileName; }
    QString activeWindowMode() const { return m_activeWindowMode; }
    QString activeExeName() const { return m_activeExeName; }
    QString boundWindowTitle() const { return m_boundWindowTitle; }
    QString boundExeName() const { return m_boundExeName; }
    bool bindInProgress() const { return m_bindInProgress; }
    QVariantList bindWindowCandidates() const { return m_bindWindowCandidates; }
    int selectedBindWindowIndex() const { return m_selectedBindWindowIndex; }
    bool appEnabled() const { return m_appEnabled; }
    QString uiLanguage() const { return m_appState.uiLanguage; }
    float yawGain() const { return static_cast<float>(m_selectedProfile.yawGain); }
    float pitchGain() const { return static_cast<float>(m_selectedProfile.pitchGain); }
    float deadzone() const { return static_cast<float>(m_selectedProfile.deadzone); }
    float maxOpacity() const { return static_cast<float>(m_selectedProfile.maxOpacity); }
    float fadeInMs() const { return static_cast<float>(m_selectedProfile.fadeInMs); }
    float fadeOutMs() const { return static_cast<float>(m_selectedProfile.fadeOutMs); }
    bool enableMouse() const { return m_selectedProfile.enableMouse; }
    bool enableGamepad() const { return m_selectedProfile.enableGamepad; }
    bool safeMode() const { return m_selectedProfile.safeMode; }
    QString cuePattern() const { return m_selectedProfile.cuePattern; }
    QString cueVisibility() const { return m_selectedProfile.cueVisibility; }
    bool debugOverlayEnabled() const { return m_debugOverlayEnabled; }
    bool advancedVisible() const { return m_advancedVisible; }
    bool simulatorEnabled() const { return m_runtime.simulation().enabled; }
    float simYaw() const { return static_cast<float>(m_runtime.simulation().yaw); }
    float simPitch() const { return static_cast<float>(m_runtime.simulation().pitch); }
    float simLateral() const { return static_cast<float>(m_runtime.simulation().lateral); }
    QStringList cuePatternOptions() const { return {"dynamic", "regular"}; }
    QStringList cueVisibilityOptions() const { return {"standard", "larger_dots", "more_dots"}; }

    void setSelectedProfileName(const QString &value);
    void setUiLanguage(const QString &value);
    void setYawGain(float value);
    void setPitchGain(float value);
    void setDeadzone(float value);
    void setMaxOpacity(float value);
    void setFadeInMs(float value);
    void setFadeOutMs(float value);
    void setEnableMouse(bool value);
    void setEnableGamepad(bool value);
    void setSafeMode(bool value);
    void setCuePattern(const QString &value);
    void setCueVisibility(const QString &value);
    void setDebugOverlayEnabled(bool value);
    void setAdvancedVisible(bool value);
    void setSimulatorEnabled(bool value);
    void setSimYaw(float value);
    void setSimPitch(float value);
    void setSimLateral(float value);
    void setSelectedBindWindowIndex(int value);

public slots:
    void openSettings();
    void reloadProfiles();
    void enableApp();
    void disableApp();
    void saveSelectedProfile();
    void bindCurrentWindow();
    void refreshBindableWindows();
    void bindSelectedWindow();
    void cancelBindWindow();
    void quitApplication();
    void resetSimulator();

signals:
    void stateChanged();
    void cueChanged();
    void profileChanged();
    void profilesChanged();
    void bindCandidatesChanged();

private:
    void tick();
    void persistAppState();
    void advanceFlowPhase(double timestampMs, float cueEnergy);
    void refreshBoundWindowFromSelectedProfile();
    void finishBindWindow(const WindowInfo &window);
    void failBindWindow(const QString &statusText, const QString &progressText);
    void restoreSettingsWindow();
    void setDisabledView();
    void refreshTrayIcon();

    QString m_dataRoot;
    QString m_profilesDir;
    QString m_appStatePath;
    AppState m_appState;
    ProfileStore m_profileStore;
    Profile m_selectedProfile;
    QApplication *m_app = nullptr;
    ForegroundWindowTracker m_tracker;
    Win32InputSource m_inputSource;
    RuntimeService m_runtime;
    QPointer<QQuickWindow> m_overlayWindow;
    QPointer<QQuickWindow> m_settingsWindow;
    QSystemTrayIcon *m_tray = nullptr;
    QAction *m_enableAction = nullptr;
    QAction *m_disableAction = nullptr;
    QAction *m_quitAction = nullptr;
    QTimer *m_timer = nullptr;
    QElapsedTimer m_elapsedTimer;
    QString m_statusText = QStringLiteral("Ready.");
    QString m_activeWindowTitle;
    QString m_activeProfileName;
    QString m_activeWindowMode = QStringLiteral("idle");
    QString m_activeExeName;
    QString m_boundWindowTitle;
    QString m_boundExeName;
    QVector<WindowInfo> m_bindCandidateWindows;
    QVariantList m_bindWindowCandidates;
    int m_selectedBindWindowIndex = -1;
    bool m_overlayVisible = false;
    int m_overlayX = 0;
    int m_overlayY = 0;
    int m_overlayWidth = 1280;
    int m_overlayHeight = 720;
    float m_leftAlpha = 0.0f;
    float m_rightAlpha = 0.0f;
    float m_topAlpha = 0.0f;
    float m_bottomAlpha = 0.0f;
    float m_centerBias = 0.0f;
    float m_leftDensity = 0.0f;
    float m_rightDensity = 0.0f;
    float m_topDensity = 0.0f;
    float m_bottomDensity = 0.0f;
    float m_centerSafeRatio = 0.74f;
    float m_cueMotionX = 0.0f;
    float m_cueMotionY = 0.0f;
    float m_cueEnergy = 0.0f;
    float m_flowPhase = 0.0f;
    double m_lastFlowTimestampMs = -1.0;
    bool m_debugOverlayEnabled = false;
    bool m_appEnabled = true;
    bool m_advancedVisible = false;
    bool m_bindInProgress = false;
};

#endif
