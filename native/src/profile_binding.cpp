#include "profile_binding.h"

#include <QFileInfo>

void appendUniqueNormalized(QStringList &list, const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    if (!normalized.isEmpty() && !list.contains(normalized)) {
        list.append(normalized);
    }
}

QString profileNameForWindow(const WindowInfo &window)
{
    const QString title = window.title.simplified();
    if (!title.isEmpty()) {
        return title.left(48);
    }

    const QString exeBase = QFileInfo(window.exeName).completeBaseName().simplified();
    if (!exeBase.isEmpty()) {
        return exeBase.left(48);
    }
    return QStringLiteral("Game Profile");
}

Profile bindingProfileForWindow(const Profile &selectedProfile, const WindowInfo &)
{
    Profile profile = selectedProfile;
    if (!profile.isDefault) {
        return profile;
    }

    if (profile.name.isEmpty()) {
        profile.name = QStringLiteral("Default");
    }
    profile.lastBoundExe.clear();
    profile.lastBoundTitle.clear();
    return profile;
}
