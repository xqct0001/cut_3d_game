from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class Rect:
    x: int = 0
    y: int = 0
    width: int = 0
    height: int = 0

    @property
    def right(self) -> int:
        return self.x + self.width

    @property
    def bottom(self) -> int:
        return self.y + self.height

    @property
    def is_empty(self) -> bool:
        return self.width <= 0 or self.height <= 0


@dataclass(slots=True)
class WindowInfo:
    hwnd: int
    pid: int
    title: str
    exe_name: str
    exe_path: str
    rect: Rect
    monitor_rect: Rect
    mode: str
    supported: bool
    reason: str


@dataclass(slots=True)
class InputSnapshot:
    mouse_dx: float = 0.0
    mouse_dy: float = 0.0
    gamepad_yaw: float = 0.0
    gamepad_pitch: float = 0.0
    gamepad_lateral: float = 0.0
    keyboard_lateral: float = 0.0
    timestamp_ms: float = 0.0
    raw_input_active: bool = False
    gamepad_connected: bool = False

    @property
    def lateral_input(self) -> float:
        lateral = self.gamepad_lateral + self.keyboard_lateral
        return max(-1.0, min(1.0, lateral))


@dataclass(slots=True)
class ComfortSignal:
    yaw_rate: float = 0.0
    pitch_rate: float = 0.0
    lateral_rate: float = 0.0
    timestamp_ms: float = 0.0

    @classmethod
    def zero(cls, timestamp_ms: float) -> "ComfortSignal":
        return cls(timestamp_ms=timestamp_ms)


@dataclass(slots=True)
class CueState:
    left_alpha: float = 0.0
    right_alpha: float = 0.0
    top_alpha: float = 0.0
    bottom_alpha: float = 0.0
    center_bias: float = 0.0
    left_density: float = 0.0
    right_density: float = 0.0
    top_density: float = 0.0
    bottom_density: float = 0.0
    center_safe_ratio: float = 0.74
    motion_x: float = 0.0
    motion_y: float = 0.0
    energy: float = 0.0

    @classmethod
    def zero(cls) -> "CueState":
        return cls()


@dataclass(slots=True)
class RuntimeViewState:
    overlay_visible: bool
    overlay_rect: Rect
    cue_state: CueState
    status_text: str
    active_profile_name: str
    active_window_title: str
    support_mode: str
    simulator_enabled: bool
