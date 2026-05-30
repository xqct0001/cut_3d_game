#include "runtime_service.h"

RuntimeService::RuntimeService(ForegroundWindowTracker *tracker, Win32InputSource *inputSource, const ProfileStore *profileStore)
    : m_tracker(tracker)
    , m_inputSource(inputSource)
    , m_profileStore(profileStore)
{
    cc_signal_reset(&m_signalState);
    cc_cue_reset(&m_cueState);
}

void RuntimeService::reset()
{
    cc_signal_reset(&m_signalState);
    cc_cue_reset(&m_cueState);
}

RuntimeViewState RuntimeService::tick(double timestampMs, const Profile &previewProfile)
{
    const std::optional<WindowInfo> window = m_tracker != nullptr ? m_tracker->snapshot() : std::optional<WindowInfo>();

    if (m_simulation.enabled) {
        return tickSimulation(timestampMs, previewProfile);
    }
    if (!window.has_value()) {
        reset();
        return emptyView(primaryMonitorRect(), "Idle: no foreground game window detected.", "", "", "idle");
    }
    m_lastDetectedWindow = window;
    if (!window->supported) {
        reset();
        return emptyView(window->rect,
                         QString("Unsupported window: %1 - %2 - %3").arg(window->exeName, window->mode, window->reason),
                         "", window->title, window->mode);
    }

    const Profile matchedProfile = m_profileStore != nullptr ? m_profileStore->matchForWindow(window->exeName, window->title) : Profile();
    const bool hasMatchedProfile = !matchedProfile.name.isEmpty();
    if (!hasMatchedProfile && previewProfile.safeMode) {
        reset();
        return emptyView(window->rect,
                         QString("Window detected but no matched profile: %1 - %2").arg(window->exeName, window->mode),
                         "", window->title, window->mode);
    }

    const Profile activeProfile = hasMatchedProfile ? matchedProfile : previewProfile;
    const CCProfileParams params = activeProfile.toCoreParams();
    CCInputSnapshot snapshot = m_inputSource != nullptr ? m_inputSource->snapshot(timestampMs) : CCInputSnapshot{};
    if (!activeProfile.enableMouse) {
        snapshot.mouse_dx = 0.0f;
        snapshot.mouse_dy = 0.0f;
        snapshot.raw_input_active = 0;
    }
    if (!activeProfile.enableGamepad) {
        snapshot.gamepad_yaw = 0.0f;
        snapshot.gamepad_pitch = 0.0f;
        snapshot.gamepad_lateral = 0.0f;
        snapshot.gamepad_connected = 0;
    }
    const CCComfortSignal signal = cc_signal_process(&m_signalState, &snapshot, &params, static_cast<float>(timestampMs));
    const CCCueState cue = cc_cue_update(&m_cueState, &signal, &params, static_cast<float>(timestampMs));

    RuntimeViewState state;
    state.overlayVisible = true;
    state.overlayRect = window->rect;
    state.cueState = cue;
    state.statusText = QString("Active: %1 - %2 - profile %3").arg(window->exeName, window->mode, activeProfile.name);
    state.activeProfileName = activeProfile.name;
    state.activeWindowTitle = window->title;
    state.supportMode = window->mode;
    state.simulatorEnabled = false;
    return state;
}

RuntimeViewState RuntimeService::tickSimulation(double timestampMs, const Profile &previewProfile)
{
    const CCProfileParams params = previewProfile.toCoreParams();
    const CCComfortSignal signal = {
        static_cast<float>(m_simulation.yaw),
        static_cast<float>(m_simulation.pitch),
        static_cast<float>(m_simulation.lateral),
        static_cast<float>(timestampMs),
    };

    RuntimeViewState state;
    state.overlayVisible = true;
    state.overlayRect = primaryMonitorRect();
    state.cueState = cc_cue_update(&m_cueState, &signal, &params, static_cast<float>(timestampMs));
    state.statusText = QString("Simulator preview - %1").arg(previewProfile.name);
    state.activeProfileName = previewProfile.name;
    state.activeWindowTitle = "Simulator";
    state.supportMode = "simulator";
    state.simulatorEnabled = true;
    return state;
}

std::optional<WindowInfo> RuntimeService::foregroundWindow() const
{
    if (m_tracker == nullptr) {
        return std::nullopt;
    }
    const std::optional<WindowInfo> window = m_tracker->snapshot();
    if (window.has_value()) {
        m_lastDetectedWindow = window;
        return window;
    }
    return m_lastDetectedWindow;
}

QVector<WindowInfo> RuntimeService::visibleWindows() const
{
    if (m_tracker == nullptr) {
        return {};
    }
    return m_tracker->visibleWindows();
}

std::optional<WindowInfo> RuntimeService::bestVisibleWindow() const
{
    if (m_tracker == nullptr) {
        return std::nullopt;
    }
    const std::optional<WindowInfo> window = m_tracker->bestVisibleWindow();
    if (window.has_value()) {
        m_lastDetectedWindow = window;
    }
    return window;
}

Rect RuntimeService::primaryMonitorRect() const
{
    if (m_tracker == nullptr) {
        return Rect{0, 0, 1280, 720};
    }
    return m_tracker->primaryMonitorRect();
}

SimulationState &RuntimeService::simulation()
{
    return m_simulation;
}

const SimulationState &RuntimeService::simulation() const
{
    return m_simulation;
}

RuntimeViewState RuntimeService::emptyView(const Rect &overlayRect, const QString &statusText, const QString &activeProfileName,
                                           const QString &activeWindowTitle, const QString &supportMode) const
{
    RuntimeViewState state;
    state.overlayVisible = false;
    state.overlayRect = overlayRect;
    state.cueState = cc_cue_zero();
    state.statusText = statusText;
    state.activeProfileName = activeProfileName;
    state.activeWindowTitle = activeWindowTitle;
    state.supportMode = supportMode;
    state.simulatorEnabled = false;
    return state;
}
