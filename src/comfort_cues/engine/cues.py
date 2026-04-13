from __future__ import annotations

from dataclasses import dataclass, field

from comfort_cues.config import Profile
from comfort_cues.models import ComfortSignal, CueState


@dataclass(slots=True)
class CueEngine:
    _state: CueState = field(default_factory=CueState.zero)
    _last_timestamp_ms: float | None = None

    def update(self, signal: ComfortSignal, profile: Profile, timestamp_ms: float) -> CueState:
        dt_ms = self._delta_ms(timestamp_ms)
        target = self._target_state(signal, profile)
        current = CueState(
            left_alpha=self._ease(self._state.left_alpha, target.left_alpha, dt_ms, profile),
            right_alpha=self._ease(self._state.right_alpha, target.right_alpha, dt_ms, profile),
            top_alpha=self._ease(self._state.top_alpha, target.top_alpha, dt_ms, profile),
            bottom_alpha=self._ease(self._state.bottom_alpha, target.bottom_alpha, dt_ms, profile),
            center_bias=self._ease(self._state.center_bias, target.center_bias, dt_ms, profile, extra_scale=0.6),
            left_density=self._ease(self._state.left_density, target.left_density, dt_ms, profile, extra_scale=0.85),
            right_density=self._ease(self._state.right_density, target.right_density, dt_ms, profile, extra_scale=0.85),
            top_density=self._ease(self._state.top_density, target.top_density, dt_ms, profile, extra_scale=0.85),
            bottom_density=self._ease(self._state.bottom_density, target.bottom_density, dt_ms, profile, extra_scale=0.85),
            center_safe_ratio=self._ease(
                self._state.center_safe_ratio,
                target.center_safe_ratio,
                dt_ms,
                profile,
                extra_scale=0.5,
            ),
            motion_x=self._ease(self._state.motion_x, target.motion_x, dt_ms, profile, extra_scale=0.9),
            motion_y=self._ease(self._state.motion_y, target.motion_y, dt_ms, profile, extra_scale=0.9),
            energy=self._ease(self._state.energy, target.energy, dt_ms, profile, extra_scale=0.9),
        )
        self._state = current
        return current

    def reset(self) -> None:
        self._state = CueState.zero()
        self._last_timestamp_ms = None

    def _delta_ms(self, timestamp_ms: float) -> float:
        previous = self._last_timestamp_ms
        self._last_timestamp_ms = timestamp_ms
        if previous is None:
            return 16.0
        return max(1.0, timestamp_ms - previous)

    def _target_state(self, signal: ComfortSignal, profile: Profile) -> CueState:
        yaw_magnitude = _clamp01(abs(signal.yaw_rate))
        pitch_magnitude = _clamp01(abs(signal.pitch_rate))
        lateral_magnitude = _clamp01(abs(signal.lateral_rate))
        max_opacity = profile.max_opacity

        turn_strength = _clamp01(yaw_magnitude * 1.08 + lateral_magnitude * 0.28)
        side_breath = _clamp01(turn_strength * 0.18 + lateral_magnitude * 0.16)
        side_floor = yaw_magnitude * 0.10

        if signal.yaw_rate < -0.01:
            left_factor = min(1.0, turn_strength * 0.98 + side_breath * 0.38 + side_floor * 0.28)
            right_factor = min(0.86, turn_strength * 0.68 + side_breath * 0.24 + side_floor * 0.18)
        elif signal.yaw_rate > 0.01:
            left_factor = min(0.86, turn_strength * 0.68 + side_breath * 0.24 + side_floor * 0.18)
            right_factor = min(1.0, turn_strength * 0.98 + side_breath * 0.38 + side_floor * 0.28)
        else:
            left_factor = side_breath * 0.72
            right_factor = side_breath * 0.72

        vertical_factor = _clamp01(pitch_magnitude * 0.84)
        vertical_floor = pitch_magnitude * 0.12
        if signal.pitch_rate < -0.01:
            top_factor = vertical_factor + vertical_floor
            bottom_factor = vertical_factor * 0.40 + vertical_floor * 0.46
        elif signal.pitch_rate > 0.01:
            top_factor = vertical_factor * 0.40 + vertical_floor * 0.46
            bottom_factor = vertical_factor + vertical_floor
        else:
            top_factor = 0.0
            bottom_factor = 0.0

        left = max_opacity * min(1.0, left_factor)
        right = max_opacity * min(1.0, right_factor)
        vertical_cap = max_opacity * 0.70
        top = vertical_cap * top_factor
        bottom = vertical_cap * bottom_factor
        energy = _clamp01(
            max(
                turn_strength,
                vertical_factor * 0.92,
                lateral_magnitude * 0.46,
            )
        )
        center_safe_ratio = min(0.78, 0.74 + turn_strength * 0.022 + vertical_factor * 0.028)
        center = min(0.34, 0.12 + max(turn_strength, vertical_factor) * 0.14)
        motion_x = _clamp(signal.yaw_rate * 1.00 + signal.lateral_rate * 0.34)
        motion_y = _clamp(signal.pitch_rate * 1.08)
        return CueState(
            left_alpha=left,
            right_alpha=right,
            top_alpha=top,
            bottom_alpha=bottom,
            center_bias=center,
            left_density=_density(left_factor, ambient=side_breath),
            right_density=_density(right_factor, ambient=side_breath),
            top_density=_density(top_factor, floor=0.14),
            bottom_density=_density(bottom_factor, floor=0.14),
            center_safe_ratio=center_safe_ratio,
            motion_x=motion_x,
            motion_y=motion_y,
            energy=energy,
        )

    @staticmethod
    def _ease(current: float, target: float, dt_ms: float, profile: Profile, extra_scale: float = 1.0) -> float:
        duration = profile.fade_in_ms if target > current else profile.fade_out_ms
        if duration <= 0:
            return target
        ratio = min(1.0, dt_ms / duration) * extra_scale
        return current + (target - current) * ratio


def _clamp(value: float) -> float:
    return max(-1.0, min(1.0, value))


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def _density(edge_factor: float, floor: float = 0.26, ambient: float = 0.0) -> float:
    strength = _clamp01(edge_factor * 0.82 + ambient * 0.32)
    if strength <= 0.01:
        return 0.0
    return _clamp01(floor + strength * (1.0 - floor))
