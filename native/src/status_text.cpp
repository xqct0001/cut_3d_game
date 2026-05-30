#include "status_text.h"

QString extractExeNameFromStatus(const QString &statusText)
{
    auto takePayload = [&statusText](const QString &prefix) {
        if (!statusText.startsWith(prefix)) {
            return QString();
        }
        const QString payload = statusText.mid(prefix.size());
        return payload.section(" - ", 0, 0).toLower();
    };

    for (const QString &prefix : {
             QStringLiteral("Active: "),
             QStringLiteral("Unsupported ratio: "),
             QStringLiteral("Unsupported window: "),
             QStringLiteral("Window detected but no matched profile: "),
             QStringLiteral("Bind failed: "),
         }) {
        const QString value = takePayload(prefix);
        if (!value.isEmpty()) {
            return value;
        }
    }
    return QString();
}

QString normalizeLanguageCode(const QString &value)
{
    return value.trimmed().toLower() == "zh" ? "zh" : "en";
}

TrayText trayTextForLanguage(const QString &language)
{
    const bool isChinese = normalizeLanguageCode(language) == "zh";
    if (!isChinese) {
        return {
            QStringLiteral("Enabled"),
            QStringLiteral("Disabled"),
            QStringLiteral("Visible game window detection"),
            QStringLiteral("Click the tray icon to open"),
            QStringLiteral("Enable"),
            QStringLiteral("Disable"),
            QStringLiteral("Quit"),
        };
    }

    return {
        QStringLiteral("\u5DF2\u5F00\u542F"),
        QStringLiteral("\u5DF2\u5173\u95ED"),
        QStringLiteral("\u68C0\u6D4B\u53EF\u89C1\u6E38\u620F\u7A97\u53E3"),
        QStringLiteral("\u5355\u51FB\u6258\u76D8\u56FE\u6807\u53EF\u6253\u5F00\u8BBE\u7F6E"),
        QStringLiteral("\u5F00\u542F"),
        QStringLiteral("\u5173\u95ED"),
        QStringLiteral("\u9000\u51FA"),
    };
}
