#ifndef PROFILE_STORE_H
#define PROFILE_STORE_H

#include "cc_core.h"

#include <QString>
#include <QStringList>
#include <QVector>

struct Profile {
    QString name;
    QString description;
    QStringList matchExe;
    QStringList matchTitle;
    bool enableMouse = true;
    bool enableGamepad = true;
    double yawGain = 1.0;
    double pitchGain = 0.85;
    double deadzone = 0.08;
    double maxOpacity = 0.18;
    double fadeInMs = 120.0;
    double fadeOutMs = 220.0;
    bool safeMode = true;
    QString cuePattern = "dynamic";
    QString cueVisibility = "standard";
    double debugOpacityMultiplier = 1.8;
    QString lastBoundExe;
    QString lastBoundTitle;
    QString filePath;
    bool isDefault = false;

    bool matches(const QString &exeName, const QString &title) const;
    CCProfileParams toCoreParams() const;
};

class ProfileStore {
public:
    explicit ProfileStore(QString directory = QString());

    static ProfileStore load(const QString &directory);

    QStringList profileNames() const;
    bool hasProfile(const QString &name) const;
    Profile get(const QString &name) const;
    Profile cloneProfile(const QString &name) const;
    Profile matchForWindow(const QString &exeName, const QString &title) const;
    QString saveProfile(const Profile &profile);

    QString directory() const;
    Profile defaultProfile() const;
    QVector<Profile> profiles() const;

private:
    QString m_directory;
    Profile m_defaultProfile;
    QVector<Profile> m_profiles;
};

void ensureProfileTemplates(const QString &targetDirectory);
Profile defaultCs2Profile(const QString &profileDirectory);
QStringList titleTokens(const QString &title);

#endif
