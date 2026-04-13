#ifndef APP_STATE_H
#define APP_STATE_H

#include <QString>

struct AppState {
    bool appEnabled = true;
    bool launchToTray = false;
    QString uiLanguage = "en";
};

QString defaultDataRoot();
QString defaultAppStatePath();
AppState loadAppState(const QString &path);
bool saveAppState(const QString &path, const AppState &state);

#endif
