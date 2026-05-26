#ifndef STATUS_TEXT_H
#define STATUS_TEXT_H

#include <QString>

struct TrayText {
    QString enabledText;
    QString disabledText;
    QString modeText;
    QString clickHint;
    QString enableAction;
    QString disableAction;
    QString quitAction;
};

QString extractExeNameFromStatus(const QString &statusText);
QString normalizeLanguageCode(const QString &value);
TrayText trayTextForLanguage(const QString &language);

#endif
