from pathlib import Path

from comfort_cues.config import Profile, ProfileStore
from comfort_cues.engine.cues import CueEngine
from comfort_cues.engine.signal import SignalProcessor
from comfort_cues.models import InputSnapshot, Rect, WindowInfo
from comfort_cues.runtime import RuntimeService


class FakeTracker:
    def __init__(self, windows):
        self._windows = iter(windows)
        self._fallback = Rect(0, 0, 1920, 1080)

    def snapshot(self):
        return next(self._windows)

    def primary_monitor_rect(self):
        return self._fallback


class FakeInputSource:
    def __init__(self, snapshots):
        self._snapshots = iter(snapshots)

    def snapshot(self, timestamp_ms):
        return next(self._snapshots)


def _window(title: str, exe_name: str, supported: bool = True, mode: str = "windowed", reason: str = "ok"):
    return WindowInfo(
        hwnd=1,
        pid=42,
        title=title,
        exe_name=exe_name,
        exe_path=f"C:/Games/{exe_name}",
        rect=Rect(10, 20, 1280, 720),
        monitor_rect=Rect(0, 0, 1920, 1080),
        mode=mode,
        supported=supported,
        reason=reason,
    )


def _store():
    default = Profile(name="Default", safe_mode=True, file_path=Path("default.toml"), is_default=True)
    sample = Profile(name="Sample", match_exe=("demo.exe",), max_opacity=0.3, file_path=Path("sample.toml"))
    return ProfileStore(directory=Path("."), default_profile=default, profiles=[sample])


def test_runtime_hides_overlay_when_profile_does_not_match():
    runtime = RuntimeService(
        tracker=FakeTracker([_window("Unknown", "other.exe")]),
        input_source=FakeInputSource([InputSnapshot(raw_input_active=True)]),
        profile_store=_store(),
        signal_processor=SignalProcessor(),
        cue_engine=CueEngine(),
    )
    view = runtime.tick(16.0, _store().default_profile)
    assert view.overlay_visible is False
    assert "no matched profile" in view.status_text


def test_runtime_hides_overlay_for_unsupported_ratio():
    runtime = RuntimeService(
        tracker=FakeTracker([_window("Demo", "demo.exe", supported=False, mode="unsupported-ratio", reason="expected ~16:9")]),
        input_source=FakeInputSource([InputSnapshot(raw_input_active=True)]),
        profile_store=_store(),
        signal_processor=SignalProcessor(),
        cue_engine=CueEngine(),
    )
    view = runtime.tick(16.0, _store().default_profile)
    assert view.overlay_visible is False
    assert "unsupported ratio" in view.status_text.lower()


def test_runtime_shows_overlay_for_matched_window():
    runtime = RuntimeService(
        tracker=FakeTracker([_window("Demo", "demo.exe")]),
        input_source=FakeInputSource([InputSnapshot(mouse_dx=120, raw_input_active=True)]),
        profile_store=_store(),
        signal_processor=SignalProcessor(smoothing=1.0),
        cue_engine=CueEngine(),
    )
    view = runtime.tick(16.0, _store().default_profile)
    assert view.overlay_visible is True
    assert view.active_profile_name == "Sample"
    assert view.cue_state.right_alpha > view.cue_state.left_alpha > 0.0
    assert view.cue_state.right_density > view.cue_state.left_density > 0.0
    assert "Active:" in view.status_text


def test_foreground_window_falls_back_to_last_detected_game_window():
    game = _window("Demo", "demo.exe")
    runtime = RuntimeService(
        tracker=FakeTracker([game, None]),
        input_source=FakeInputSource([InputSnapshot(mouse_dx=120, raw_input_active=True)]),
        profile_store=_store(),
        signal_processor=SignalProcessor(smoothing=1.0),
        cue_engine=CueEngine(),
    )

    runtime.tick(16.0, _store().default_profile)

    assert runtime.foreground_window() == game


def test_runtime_uses_simulator_without_window():
    runtime = RuntimeService(
        tracker=FakeTracker([None]),
        input_source=FakeInputSource([]),
        profile_store=_store(),
        signal_processor=SignalProcessor(),
        cue_engine=CueEngine(),
    )
    runtime.simulation.enabled = True
    runtime.simulation.yaw = -0.7
    view = runtime.tick(16.0, _store().default_profile)
    assert view.overlay_visible is True
    assert view.simulator_enabled is True
    assert view.cue_state.left_alpha > view.cue_state.right_alpha > 0.0
    assert "Simulator preview" in view.status_text
