#include "app_state.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

QString defaultDataRoot()
{
    return QFileInfo(defaultAppStatePath()).absolutePath();
}

QString defaultAppStatePath()
{
    QString base = qEnvironmentVariable("APPDATA");
    if (base.isEmpty()) {
        base = QDir::homePath() + "/AppData/Roaming";
    }
    return QDir::toNativeSeparators(base + "/Comfort Cues/app-state.json");
}

AppState loadAppState(const QString &path)
{
    QFile file(path);
    AppState state;
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return state;
    }

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    const QJsonObject object = document.object();
    state.appEnabled = object.value("app_enabled").toBool(true);
    state.launchToTray = object.value("launch_to_tray").toBool(false);
    state.uiLanguage = object.value("ui_language").toString("en").trimmed().toLower();
    if (state.uiLanguage != "zh") {
        state.uiLanguage = "en";
    }
    return state;
}

bool saveAppState(const QString &path, const AppState &state)
{
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        return false;
    }

    QJsonObject object;
    object.insert("app_enabled", state.appEnabled);
    object.insert("launch_to_tray", state.launchToTray);
    object.insert("ui_language", state.uiLanguage);

    QByteArray payload = QJsonDocument(object).toJson(QJsonDocument::Indented);
    if (!payload.endsWith('\n')) {
        payload.append('\n');
    }
    file.write(payload);
    return true;
}
