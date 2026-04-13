#include "profile_store.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QRegularExpression>
#include <QTextStream>

namespace {

QString escapeString(const QString &value)
{
    QString escaped = value;
    escaped.replace("\\", "\\\\");
    escaped.replace("\"", "\\\"");
    return escaped;
}

QString quoteString(const QString &value)
{
    return "\"" + escapeString(value) + "\"";
}

QString boolString(bool value)
{
    return value ? "true" : "false";
}

QString slugifyName(const QString &value)
{
    QString slug = value.trimmed().toLower();
    slug.replace(QRegularExpression("\\s+"), "-");
    slug.replace(QRegularExpression("[^a-z0-9\\-]"), "");
    if (slug.isEmpty()) {
        slug = "profile";
    }
    return slug;
}

QString unescapeQuoted(const QString &value)
{
    QString input = value.trimmed();
    QString output;
    bool escaping = false;
    if (input.startsWith('"') && input.endsWith('"') && input.size() >= 2) {
        input = input.mid(1, input.size() - 2);
    }
    for (const QChar &ch : input) {
        if (escaping) {
            output.append(ch);
            escaping = false;
        } else if (ch == '\\') {
            escaping = true;
        } else {
            output.append(ch);
        }
    }
    return output;
}

QStringList parseStringArray(const QString &value)
{
    const QString trimmed = value.trimmed();
    QStringList results;
    QRegularExpression re("\"((?:\\\\.|[^\"])*)\"");
    QRegularExpressionMatchIterator it;

    if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
        return results;
    }

    it = re.globalMatch(trimmed);
    while (it.hasNext()) {
        const QRegularExpressionMatch match = it.next();
        results.append(unescapeQuoted("\"" + match.captured(1) + "\"").toLower());
    }
    return results;
}

QString normalizePattern(const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    if (normalized == "dynamic" || normalized == "regular") {
        return normalized;
    }
    return "dynamic";
}

QString normalizeVisibility(const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    if (normalized == "standard" || normalized == "larger_dots" || normalized == "more_dots") {
        return normalized;
    }
    return "standard";
}

QStringList normalizeList(QStringList values)
{
    for (QString &value : values) {
        value = value.trimmed().toLower();
    }
    values.removeAll(QString());
    return values;
}

Profile loadProfileFile(const QString &path, const Profile *baseProfile = nullptr, bool isDefault = false)
{
    QFile file(path);
    Profile profile;
    QHash<QString, QString> values;

    if (baseProfile != nullptr) {
        profile = *baseProfile;
    }
    if (profile.name.isEmpty()) {
        profile.name = QFileInfo(path).completeBaseName().replace('-', ' ');
    }
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        profile.filePath = path;
        profile.isDefault = isDefault;
        return profile;
    }

    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        const int split = line.indexOf('=');
        if (line.isEmpty() || line.startsWith('#') || split <= 0) {
            continue;
        }
        values.insert(line.left(split).trimmed(), line.mid(split + 1).trimmed());
    }

    if (values.contains("name")) {
        profile.name = unescapeQuoted(values.value("name"));
    }
    if (values.contains("description")) {
        profile.description = unescapeQuoted(values.value("description"));
    }
    if (values.contains("match_exe")) {
        profile.matchExe = normalizeList(parseStringArray(values.value("match_exe")));
    }
    if (values.contains("match_title")) {
        profile.matchTitle = normalizeList(parseStringArray(values.value("match_title")));
    }
    if (values.contains("enable_mouse")) {
        profile.enableMouse = values.value("enable_mouse").trimmed().toLower() == "true";
    }
    if (values.contains("enable_gamepad")) {
        profile.enableGamepad = values.value("enable_gamepad").trimmed().toLower() == "true";
    }
    if (values.contains("yaw_gain")) {
        profile.yawGain = values.value("yaw_gain").toDouble();
    }
    if (values.contains("pitch_gain")) {
        profile.pitchGain = values.value("pitch_gain").toDouble();
    }
    if (values.contains("deadzone")) {
        profile.deadzone = values.value("deadzone").toDouble();
    }
    if (values.contains("max_opacity")) {
        profile.maxOpacity = values.value("max_opacity").toDouble();
    }
    if (values.contains("fade_in_ms")) {
        profile.fadeInMs = values.value("fade_in_ms").toDouble();
    }
    if (values.contains("fade_out_ms")) {
        profile.fadeOutMs = values.value("fade_out_ms").toDouble();
    }
    if (values.contains("safe_mode")) {
        profile.safeMode = values.value("safe_mode").trimmed().toLower() == "true";
    }
    if (values.contains("cue_pattern")) {
        profile.cuePattern = normalizePattern(unescapeQuoted(values.value("cue_pattern")));
    }
    if (values.contains("cue_visibility")) {
        profile.cueVisibility = normalizeVisibility(unescapeQuoted(values.value("cue_visibility")));
    }
    if (values.contains("debug_opacity_multiplier")) {
        profile.debugOpacityMultiplier = values.value("debug_opacity_multiplier").toDouble();
    }
    if (values.contains("last_bound_exe")) {
        profile.lastBoundExe = unescapeQuoted(values.value("last_bound_exe")).toLower();
    }
    if (values.contains("last_bound_title")) {
        profile.lastBoundTitle = unescapeQuoted(values.value("last_bound_title")).toLower();
    }

    profile.filePath = path;
    profile.isDefault = isDefault;
    return profile;
}

QString serializeProfile(const Profile &profile)
{
    QStringList lines;
    auto joinArray = [](const QStringList &items) {
        QStringList quoted;
        for (const QString &item : items) {
            quoted.append(quoteString(item));
        }
        return "[" + quoted.join(", ") + "]";
    };

    lines
        << "name = " + quoteString(profile.name)
        << "description = " + quoteString(profile.description)
        << "match_exe = " + joinArray(profile.matchExe)
        << "match_title = " + joinArray(profile.matchTitle)
        << "enable_mouse = " + boolString(profile.enableMouse)
        << "enable_gamepad = " + boolString(profile.enableGamepad)
        << QString("yaw_gain = %1").arg(profile.yawGain, 0, 'f', 3)
        << QString("pitch_gain = %1").arg(profile.pitchGain, 0, 'f', 3)
        << QString("deadzone = %1").arg(profile.deadzone, 0, 'f', 3)
        << QString("max_opacity = %1").arg(profile.maxOpacity, 0, 'f', 3)
        << QString("fade_in_ms = %1").arg(profile.fadeInMs, 0, 'f', 0)
        << QString("fade_out_ms = %1").arg(profile.fadeOutMs, 0, 'f', 0)
        << "safe_mode = " + boolString(profile.safeMode)
        << "cue_pattern = " + quoteString(profile.cuePattern)
        << "cue_visibility = " + quoteString(profile.cueVisibility)
        << QString("debug_opacity_multiplier = %1").arg(profile.debugOpacityMultiplier, 0, 'f', 3)
        << "last_bound_exe = " + quoteString(profile.lastBoundExe)
        << "last_bound_title = " + quoteString(profile.lastBoundTitle);
    return lines.join("\n") + "\n";
}

QString smokeProgressPath()
{
    const QString runtimePath = qEnvironmentVariable("CC_RUNTIME_PROGRESS_PATH");
    if (!runtimePath.isEmpty()) {
        return runtimePath;
    }
    return qEnvironmentVariable("CC_SMOKE_PROGRESS_PATH");
}

void appendSmokeProgress(const QString &message)
{
    const QString path = smokeProgressPath();
    if (path.isEmpty()) {
        return;
    }

    QFileInfo info(path);
    QDir().mkpath(info.absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        return;
    }

    file.write(message.toUtf8());
    file.write("\n");
    file.close();
}

} // namespace

bool Profile::matches(const QString &exeName, const QString &title) const
{
    const QString exe = exeName.trimmed().toLower();
    const QString titleValue = title.trimmed().toLower();
    if (isDefault) {
        return false;
    }
    for (const QString &token : matchExe) {
        if (exe.contains(token)) {
            return true;
        }
    }
    for (const QString &token : matchTitle) {
        if (titleValue.contains(token)) {
            return true;
        }
    }
    return false;
}

CCProfileParams Profile::toCoreParams() const
{
    return CCProfileParams{
        static_cast<float>(yawGain),
        static_cast<float>(pitchGain),
        static_cast<float>(deadzone),
        static_cast<float>(maxOpacity),
        static_cast<float>(fadeInMs),
        static_cast<float>(fadeOutMs),
    };
}

ProfileStore::ProfileStore(QString directory)
    : m_directory(std::move(directory))
{
}

ProfileStore ProfileStore::load(const QString &directory)
{
    appendSmokeProgress(QString("profile_store: load begin (%1)").arg(QDir::toNativeSeparators(directory)));
    ProfileStore store(directory);
    QDir dir(directory);
    const QString defaultPath = dir.filePath("default.toml");
    store.m_defaultProfile = QFileInfo::exists(defaultPath)
        ? loadProfileFile(defaultPath, nullptr, true)
        : Profile();
    appendSmokeProgress("profile_store: default profile loaded");
    if (store.m_defaultProfile.name.isEmpty()) {
        store.m_defaultProfile.name = "Default";
        store.m_defaultProfile.filePath = defaultPath;
        store.m_defaultProfile.isDefault = true;
    }

    const QStringList entries = dir.entryList(QStringList() << "*.toml", QDir::Files, QDir::Name);
    for (const QString &entry : entries) {
        if (entry == "default.toml") {
            continue;
        }
        store.m_profiles.append(loadProfileFile(dir.filePath(entry), &store.m_defaultProfile, false));
    }
    appendSmokeProgress(QString("profile_store: load complete (%1 profiles)").arg(store.m_profiles.size()));
    return store;
}

QStringList ProfileStore::profileNames() const
{
    QStringList names;
    names.append(m_defaultProfile.name);
    for (const Profile &profile : m_profiles) {
        names.append(profile.name);
    }
    return names;
}

bool ProfileStore::hasProfile(const QString &name) const
{
    const QString needle = name.trimmed();
    if (m_defaultProfile.name == needle) {
        return true;
    }
    for (const Profile &profile : m_profiles) {
        if (profile.name == needle) {
            return true;
        }
    }
    return false;
}

Profile ProfileStore::get(const QString &name) const
{
    const QString needle = name.trimmed();
    if (m_defaultProfile.name == needle) {
        return m_defaultProfile;
    }
    for (const Profile &profile : m_profiles) {
        if (profile.name == needle) {
            return profile;
        }
    }
    return m_defaultProfile;
}

Profile ProfileStore::cloneProfile(const QString &name) const
{
    return get(name);
}

Profile ProfileStore::matchForWindow(const QString &exeName, const QString &title) const
{
    for (const Profile &profile : m_profiles) {
        if (profile.matches(exeName, title)) {
            return profile;
        }
    }
    return Profile();
}

QString ProfileStore::saveProfile(const Profile &profile)
{
    Profile copy = profile;
    QString target = copy.filePath;
    if (target.isEmpty()) {
        target = QDir(m_directory).filePath(slugifyName(copy.name) + ".toml");
    }

    QDir().mkpath(m_directory);
    QFile file(target);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        file.write(serializeProfile(copy).toUtf8());
    }

    copy.filePath = target;
    if (copy.isDefault) {
        m_defaultProfile = copy;
    } else {
        bool updated = false;
        for (Profile &existing : m_profiles) {
            if (existing.name == copy.name) {
                existing = copy;
                updated = true;
                break;
            }
        }
        if (!updated) {
            m_profiles.append(copy);
        }
    }
    return target;
}

QString ProfileStore::directory() const
{
    return m_directory;
}

Profile ProfileStore::defaultProfile() const
{
    return m_defaultProfile;
}

QVector<Profile> ProfileStore::profiles() const
{
    return m_profiles;
}

void ensureProfileTemplates(const QString &targetDirectory)
{
    appendSmokeProgress(QString("profile_store: ensure templates begin (%1)").arg(QDir::toNativeSeparators(targetDirectory)));
    const QString normalizedTarget = QDir::fromNativeSeparators(targetDirectory);
    appendSmokeProgress("profile_store: ensure templates qdir ready");
    const bool created = QDir().mkpath(normalizedTarget);
    appendSmokeProgress(QString("profile_store: ensure templates mkpath complete (%1)").arg(created ? "true" : "false"));

    const QStringList templateNames = {
        QStringLiteral("default.toml"),
        QStringLiteral("sample-third-person.toml"),
    };
    for (const QString &name : templateNames) {
        const QString targetPath = QDir(normalizedTarget).filePath(name);
        appendSmokeProgress(QString("profile_store: ensure template check %1").arg(name));
        if (QFileInfo::exists(targetPath)) {
            appendSmokeProgress(QString("profile_store: ensure template already present %1").arg(name));
            continue;
        }
        QFile resource(":/profiles/" + name);
        if (!resource.open(QIODevice::ReadOnly)) {
            appendSmokeProgress(QString("profile_store: resource open failed %1").arg(name));
            continue;
        }
        QFile output(targetPath);
        if (output.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
            appendSmokeProgress(QString("profile_store: writing template %1").arg(name));
            output.write(resource.readAll());
            appendSmokeProgress(QString("profile_store: wrote template %1").arg(name));
        }
    }
    appendSmokeProgress("profile_store: ensure templates complete");
}

Profile defaultCs2Profile(const QString &profileDirectory)
{
    Profile profile;
    profile.name = "CS2";
    profile.description = "Counter-Strike 2 windowed or borderless profile.";
    profile.matchExe = QStringList() << "cs2.exe";
    profile.matchTitle = QStringList() << "counter-strike" << "counter strike 2" << "cs2";
    profile.enableMouse = true;
    profile.enableGamepad = false;
    profile.yawGain = 1.05;
    profile.pitchGain = 0.7;
    profile.deadzone = 0.05;
    profile.maxOpacity = 0.38;
    profile.fadeInMs = 70.0;
    profile.fadeOutMs = 300.0;
    profile.safeMode = true;
    profile.cuePattern = "dynamic";
    profile.cueVisibility = "more_dots";
    profile.debugOpacityMultiplier = 2.3;
    profile.lastBoundExe = "cs2.exe";
    profile.lastBoundTitle = "counter-strike";
    profile.filePath = QDir(profileDirectory).filePath("cs2.toml");
    return profile;
}

QStringList titleTokens(const QString &title)
{
    const QString lowered = title.trimmed().toLower();
    QStringList tokens;
    for (const QString &token : QStringList() << "counter-strike" << "counter strike 2" << "cs2") {
        if (lowered.contains(token)) {
            tokens.append(token);
        }
    }
    if (!lowered.isEmpty()) {
        const QString truncated = lowered.left(80);
        if (!tokens.contains(truncated)) {
            tokens.append(truncated);
        }
    }
    return tokens;
}
