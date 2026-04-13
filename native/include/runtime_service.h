#ifndef RUNTIME_SERVICE_H
#define RUNTIME_SERVICE_H

#include "input_source.h"
#include "models.h"
#include "profile_store.h"
#include "window_tracker.h"

#include <optional>

struct SimulationState {
    bool enabled = false;
    double yaw = 0.0;
    double pitch = 0.0;
    double lateral = 0.0;
};

class RuntimeService {
public:
    RuntimeService(ForegroundWindowTracker *tracker, Win32InputSource *inputSource, const ProfileStore *profileStore);

    void reset();
    RuntimeViewState tick(double timestampMs, const Profile &previewProfile);
    std::optional<WindowInfo> foregroundWindow() const;
    Rect primaryMonitorRect() const;

    SimulationState &simulation();
    const SimulationState &simulation() const;

private:
    RuntimeViewState tickSimulation(double timestampMs, const Profile &previewProfile);
    RuntimeViewState emptyView(const Rect &overlayRect, const QString &statusText, const QString &activeProfileName,
                               const QString &activeWindowTitle, const QString &supportMode) const;

    ForegroundWindowTracker *m_tracker = nullptr;
    Win32InputSource *m_inputSource = nullptr;
    const ProfileStore *m_profileStore = nullptr;
    SimulationState m_simulation;
    CCSignalProcessorState m_signalState;
    CCCueEngineState m_cueState;
};

#endif
