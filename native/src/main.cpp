#include "app_controller.h"

#include <QApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTextStream>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickWindow>
namespace {

struct LaunchOverrides {
    QString dataRoot;
    QString appStatePath;
    QString runtimeProgressPath;
    bool forceShowSettings = false;
};

QString progressLogPath()
{
    const QString runtimePath = qEnvironmentVariable("CC_RUNTIME_PROGRESS_PATH");
    if (!runtimePath.isEmpty()) {
        return runtimePath;
    }
    return qEnvironmentVariable("CC_SMOKE_PROGRESS_PATH");
}

QString effectiveDataRoot(const QString &configuredDataRoot)
{
    return configuredDataRoot.isEmpty() ? defaultDataRoot() : configuredDataRoot;
}

QString effectiveAppStatePath(const QString &configuredStatePath)
{
    return configuredStatePath.isEmpty() ? defaultAppStatePath() : configuredStatePath;
}

bool writeJsonReport(const QString &path, const QJsonObject &report)
{
    if (path.isEmpty()) {
        return false;
    }

    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        return false;
    }

    QByteArray payload = QJsonDocument(report).toJson(QJsonDocument::Indented);
    if (!payload.endsWith('\n')) {
        payload.append('\n');
    }
    file.write(payload);
    return true;
}

void appendProgressLine(const QString &path, const QString &message)
{
    if (path.isEmpty()) {
        return;
    }

    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        return;
    }

    QTextStream stream(&file);
    stream << message << '\n';
    stream.flush();
}

int runStateOnlySmokeTest(const QString &dataRoot, const QString &statePath, const QString &outputPath,
                          const QString &progressPath)
{
    appendProgressLine(progressPath, "runSmokeTest: begin");

    const QString profilesDir = QDir(dataRoot).filePath("profiles");
    const QString defaultProfilePath = QDir(profilesDir).filePath("default.toml");
    const QString sampleProfilePath = QDir(profilesDir).filePath("sample-third-person.toml");
    ProfileStore profileStore = ProfileStore::load(profilesDir);
    const Profile selectedProfile = profileStore.hasProfile("CS2")
        ? profileStore.cloneProfile("CS2")
        : profileStore.defaultProfile();

    QJsonObject report;

    report.insert("mode", "native_runtime_smoke");
    report.insert("smoke_scope", "state_only");
    report.insert("data_root", QDir::toNativeSeparators(dataRoot));
    report.insert("app_state_path", QDir::toNativeSeparators(statePath));
    report.insert("profiles_dir", QDir::toNativeSeparators(profilesDir));
    report.insert("profiles_dir_exists", QFileInfo::exists(profilesDir));
    report.insert("default_profile_exists", QFileInfo::exists(defaultProfilePath));
    report.insert("sample_profile_exists", QFileInfo::exists(sampleProfilePath));
    report.insert("selected_profile_name", selectedProfile.name);
    appendProgressLine(progressPath, "runSmokeTest: captured startup state");

    const AppState initialState = loadAppState(statePath);
    const bool shouldShowWindowOnLaunch = !initialState.launchToTray;
    report.insert("should_show_window_on_launch", shouldShowWindowOnLaunch);
    AppState firstRunState = initialState;
    firstRunState.launchToTray = true;
    saveAppState(statePath, firstRunState);
    appendProgressLine(progressPath, "runSmokeTest: completed first-run persistence");

    const AppState persistedAfterStartup = loadAppState(statePath);
    report.insert("launch_to_tray_persisted", persistedAfterStartup.launchToTray);
    report.insert("app_enabled_persisted", persistedAfterStartup.appEnabled);

    const QString savedProfilePath = profileStore.saveProfile(selectedProfile);
    appendProgressLine(progressPath, "runSmokeTest: saved selected profile");
    const QString savedProfileFile = QFileInfo(savedProfilePath).fileName();
    const QString saveStatus = QStringLiteral("Saved profile to %1").arg(savedProfileFile);
    report.insert("save_status_text", saveStatus);
    report.insert("saved_profile_file", savedProfileFile);
    report.insert("profile_save_succeeded",
                  !savedProfileFile.isEmpty() && QFileInfo::exists(QDir(profilesDir).filePath(savedProfileFile)));

    AppState disabledState = persistedAfterStartup;
    disabledState.appEnabled = false;
    saveAppState(statePath, disabledState);
    const bool disableOk = !loadAppState(statePath).appEnabled;
    report.insert("disable_roundtrip_ok", disableOk);

    AppState enabledState = loadAppState(statePath);
    enabledState.appEnabled = true;
    saveAppState(statePath, enabledState);
    const bool enableOk = loadAppState(statePath).appEnabled;
    report.insert("enable_roundtrip_ok", enableOk);
    appendProgressLine(progressPath, "runSmokeTest: enable/disable roundtrip complete");

    const bool wroteReport = writeJsonReport(outputPath, report);
    appendProgressLine(progressPath, wroteReport ? "runSmokeTest: wrote json report" : "runSmokeTest: failed to write json report");
    return wroteReport ? 0 : 2;
}

LaunchOverrides parseLaunchOverrides(const QStringList &arguments)
{
    LaunchOverrides overrides;

    for (int index = 1; index < arguments.size(); ++index) {
        const QString &argument = arguments.at(index);
        auto takeValue = [&](QString &target) {
            if (index + 1 < arguments.size()) {
                target = arguments.at(++index);
            }
        };

        if (argument == "--cc-data-root") {
            takeValue(overrides.dataRoot);
        } else if (argument == "--cc-app-state-path") {
            takeValue(overrides.appStatePath);
        } else if (argument == "--cc-runtime-progress-path") {
            takeValue(overrides.runtimeProgressPath);
        } else if (argument == "--cc-force-show-settings") {
            overrides.forceShowSettings = true;
        }
    }

    return overrides;
}

} // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);

    const LaunchOverrides launchOverrides = parseLaunchOverrides(QCoreApplication::arguments());
    const QString configuredDataRoot = !launchOverrides.dataRoot.isEmpty()
        ? launchOverrides.dataRoot
        : qEnvironmentVariable("CC_DATA_ROOT");
    const QString configuredStatePath = !launchOverrides.appStatePath.isEmpty()
        ? launchOverrides.appStatePath
        : qEnvironmentVariable("CC_APP_STATE_PATH");
    const QString configuredRuntimeProgressPath = !launchOverrides.runtimeProgressPath.isEmpty()
        ? launchOverrides.runtimeProgressPath
        : qEnvironmentVariable("CC_RUNTIME_PROGRESS_PATH");
    const QString smokeOutputPath = qEnvironmentVariable("CC_SMOKE_TEST_OUTPUT");
    if (!configuredRuntimeProgressPath.isEmpty()) {
        qputenv("CC_RUNTIME_PROGRESS_PATH", configuredRuntimeProgressPath.toUtf8());
    }
    const QString smokeProgressPath = progressLogPath();
    const bool forceShowSettings = launchOverrides.forceShowSettings
        || qEnvironmentVariableIntValue("CC_FORCE_SHOW_SETTINGS") != 0;
    appendProgressLine(smokeProgressPath, "main: application started");
    appendProgressLine(smokeProgressPath,
                       QString("main: launch overrides data_root=%1 state_path=%2 force_show=%3")
                           .arg(effectiveDataRoot(configuredDataRoot),
                                effectiveAppStatePath(configuredStatePath),
                                forceShowSettings ? "true" : "false"));

    if (!smokeOutputPath.isEmpty()) {
        appendProgressLine(smokeProgressPath, "main: state-only smoke mode active");
        return runStateOnlySmokeTest(effectiveDataRoot(configuredDataRoot), effectiveAppStatePath(configuredStatePath),
                                     smokeOutputPath, smokeProgressPath);
    }

    AppController controller(&app, configuredDataRoot, configuredStatePath);
    appendProgressLine(smokeProgressPath, "main: controller constructed");
    QQmlApplicationEngine engine;
    engine.addImportPath(QDir(QCoreApplication::applicationDirPath()).filePath("qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app, [&](const QList<QQmlError> &warnings) {
        for (const QQmlError &warning : warnings) {
            appendProgressLine(smokeProgressPath, QString("qml warning: %1").arg(warning.toString()));
        }
    });
    engine.rootContext()->setContextProperty("controller", &controller);
    appendProgressLine(smokeProgressPath, "main: controller set on qml context");
    engine.load(QUrl("qrc:/src/comfort_cues/ui/qml/OverlayWindow.qml"));
    appendProgressLine(smokeProgressPath, QString("main: overlay qml loaded (%1 root objects)").arg(engine.rootObjects().size()));
    engine.load(QUrl("qrc:/src/comfort_cues/ui/qml/SettingsWindow.qml"));
    appendProgressLine(smokeProgressPath, QString("main: settings qml loaded (%1 root objects)").arg(engine.rootObjects().size()));

    QQuickWindow *overlayWindow = nullptr;
    QQuickWindow *settingsWindow = nullptr;
    for (QObject *root : engine.rootObjects()) {
        if (root->objectName() == "overlayWindow") {
            overlayWindow = qobject_cast<QQuickWindow *>(root);
        } else if (root->objectName() == "settingsWindow") {
            settingsWindow = qobject_cast<QQuickWindow *>(root);
        }
    }

    if (overlayWindow == nullptr || settingsWindow == nullptr) {
        appendProgressLine(smokeProgressPath, "main: failed to resolve qml root windows");
        return 1;
    }

    controller.attachWindows(overlayWindow, settingsWindow);
    appendProgressLine(smokeProgressPath, "main: controller attached windows");
    if (forceShowSettings) {
        appendProgressLine(smokeProgressPath, "main: force-show-settings enabled");
        controller.openSettings();
        if (controller.shouldShowWindowOnLaunch()) {
            controller.completeFirstRun();
        }
    } else if (controller.shouldShowWindowOnLaunch()) {
        controller.openSettings();
        controller.completeFirstRun();
    }

    return app.exec();
}
