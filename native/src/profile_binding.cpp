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

Profile bindingProfileForWindow(const Profile &selectedProfile, const WindowInfo &window)
{
    Profile profile = selectedProfile;
    if (!profile.isDefault) {
        return profile;
    }

    const QString name = profileNameForWindow(window);
    profile.name = name;
    profile.description = QString("%1 windowed or borderless profile.").arg(name);
    profile.matchExe.clear();
    profile.matchTitle.clear();
    profile.lastBoundExe.clear();
    profile.lastBoundTitle.clear();
    profile.filePath.clear();
    profile.isDefault = false;
    return profile;
}
