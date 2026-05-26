#ifndef PROFILE_BINDING_H
#define PROFILE_BINDING_H

#include "models.h"
#include "profile_store.h"

void appendUniqueNormalized(QStringList &list, const QString &value);
QString profileNameForWindow(const WindowInfo &window);
Profile bindingProfileForWindow(const Profile &selectedProfile, const WindowInfo &window);

#endif
