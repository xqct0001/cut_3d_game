from __future__ import annotations

from dataclasses import dataclass

from comfort_cues.config import Profile, ProfileStore
from comfort_cues.engine.cues import CueEngine
from comfort_cues.engine.signal import SignalProcessor
from comfort_cues.models import ComfortSignal, CueState, RuntimeViewState, WindowInfo


@dataclass(slots=True)
class SimulationState:
    enabled: bool = False
    yaw: float = 0.0
    pitch: float = 0.0
    lateral: float = 0.0


class RuntimeService:
    def __init__(self, tracker, input_source, profile_store: ProfileStore, signal_processor: SignalProcessor, cue_engine: CueEngine) -> None:
        self._tracker = tracker
        self._input_source = input_source
        self._profile_store = profile_store
        self._signal_processor = signal_processor
        self._cue_engine = cue_engine
        self._simulation = SimulationState()
        self._last_detected_window: WindowInfo | None = None

    @property
    def simulation(self) -> SimulationState:
        return self._simulation

    def reset(self) -> None:
        self._reset_engines()

    def tick(self, timestamp_ms: float, preview_profile: Profile) -> RuntimeViewState:
        if self._simulation.enabled:
            return self._tick_simulation(timestamp_ms, preview_profile)

        window = self._tracker.snapshot()
        if window is None:
            self._reset_engines()
            return self._empty_view(
                overlay_rect=self._tracker.primary_monitor_rect(),
                status_text="Idle: no foreground game window detected.",
                active_profile_name="",
                active_window_title="",
                support_mode="idle",
            )
        self._last_detected_window = window

        if not window.supported:
            self._reset_engines()
            if window.mode == "unsupported-ratio":
                status_text = f"Unsupported ratio: {window.exe_name} - expected ~16:9"
            else:
                status_text = f"Unsupported window: {window.exe_name} - {window.mode} - {window.reason}"
            return self._empty_view(
                overlay_rect=window.rect,
                status_text=status_text,
                active_profile_name="",
                active_window_title=window.title,
                support_mode=window.mode,
            )

        profile = self._profile_store.match_for_window(window.exe_name, window.title)
        if profile is None and preview_profile.safe_mode:
            self._reset_engines()
            return self._empty_view(
                overlay_rect=window.rect,
                status_text=f"Window detected but no matched profile: {window.exe_name} - {window.mode}",
                active_profile_name="",
                active_window_title=window.title,
                support_mode=window.mode,
            )

        active_profile = profile or preview_profile
        snapshot = self._input_source.snapshot(timestamp_ms)
        signal = self._signal_processor.process(snapshot, active_profile, timestamp_ms)
        cue = self._cue_engine.update(signal, active_profile, timestamp_ms)
        return RuntimeViewState(
            overlay_visible=True,
            overlay_rect=window.rect,
            cue_state=cue,
            status_text=f"Active: {window.exe_name} - {window.mode} - profile {active_profile.name}",
            active_profile_name=active_profile.name,
            active_window_title=window.title,
            support_mode=window.mode,
            simulator_enabled=False,
        )

    def _tick_simulation(self, timestamp_ms: float, preview_profile: Profile) -> RuntimeViewState:
        signal = ComfortSignal(
            yaw_rate=self._simulation.yaw,
            pitch_rate=self._simulation.pitch,
            lateral_rate=self._simulation.lateral,
            timestamp_ms=timestamp_ms,
        )
        cue = self._cue_engine.update(signal, preview_profile, timestamp_ms)
        return RuntimeViewState(
            overlay_visible=True,
            overlay_rect=self._tracker.primary_monitor_rect(),
            cue_state=cue,
            status_text=f"Simulator preview - {preview_profile.name}",
            active_profile_name=preview_profile.name,
            active_window_title="Simulator",
            support_mode="simulator",
            simulator_enabled=True,
        )

    def foreground_window(self) -> WindowInfo | None:
        window = self._tracker.snapshot()
        if window is not None:
            self._last_detected_window = window
            return window
        return self._last_detected_window

    def _reset_engines(self) -> None:
        self._signal_processor.reset()
        self._cue_engine.reset()

    @staticmethod
    def _empty_view(overlay_rect, status_text: str, active_profile_name: str, active_window_title: str, support_mode: str) -> RuntimeViewState:
        return RuntimeViewState(
            overlay_visible=False,
            overlay_rect=overlay_rect,
            cue_state=CueState.zero(),
            status_text=status_text,
            active_profile_name=active_profile_name,
            active_window_title=active_window_title,
            support_mode=support_mode,
            simulator_enabled=False,
        )
