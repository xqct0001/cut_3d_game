from __future__ import annotations

from dataclasses import dataclass
from math import copysign

from comfort_cues.config import Profile
from comfort_cues.models import ComfortSignal, InputSnapshot


@dataclass(slots=True)
class SignalProcessor:
    smoothing: float = 0.32
    mouse_scale: float = 0.045
    _last_timestamp_ms: float | None = None
    _yaw_state: float = 0.0
    _pitch_state: float = 0.0
    _lateral_state: float = 0.0

    def process(self, snapshot: InputSnapshot, profile: Profile, timestamp_ms: float) -> ComfortSignal:
        dt_ms = max(8.0, self._delta_ms(timestamp_ms))
        yaw_raw = 0.0
        pitch_raw = 0.0

        if profile.enable_mouse and snapshot.raw_input_active:
            yaw_raw += snapshot.mouse_dx / dt_ms * self.mouse_scale * profile.yaw_gain
            pitch_raw += snapshot.mouse_dy / dt_ms * self.mouse_scale * profile.pitch_gain
        if profile.enable_gamepad and snapshot.gamepad_connected:
            yaw_raw += snapshot.gamepad_yaw * 0.7 * profile.yaw_gain
            pitch_raw += snapshot.gamepad_pitch * 0.7 * profile.pitch_gain

        lateral_raw = snapshot.lateral_input * 0.75

        yaw = self._smooth(self._yaw_state, self._apply_deadzone(yaw_raw, profile.deadzone))
        pitch = self._smooth(self._pitch_state, self._apply_deadzone(pitch_raw, profile.deadzone))
        lateral = self._smooth(self._lateral_state, self._apply_deadzone(lateral_raw, profile.deadzone * 0.8))

        self._yaw_state = yaw
        self._pitch_state = pitch
        self._lateral_state = lateral
        return ComfortSignal(yaw_rate=yaw, pitch_rate=pitch, lateral_rate=lateral, timestamp_ms=timestamp_ms)

    def reset(self) -> None:
        self._last_timestamp_ms = None
        self._yaw_state = 0.0
        self._pitch_state = 0.0
        self._lateral_state = 0.0

    def _delta_ms(self, timestamp_ms: float) -> float:
        previous = self._last_timestamp_ms
        self._last_timestamp_ms = timestamp_ms
        if previous is None:
            return 16.0
        return max(1.0, timestamp_ms - previous)

    def _smooth(self, previous: float, current: float) -> float:
        return previous + (current - previous) * self.smoothing

    @staticmethod
    def _apply_deadzone(value: float, deadzone: float) -> float:
        magnitude = abs(value)
        if magnitude <= deadzone:
            return 0.0
        scaled = (magnitude - deadzone) / max(1e-6, 1.0 - deadzone)
        return max(-1.0, min(1.0, copysign(scaled, value)))
