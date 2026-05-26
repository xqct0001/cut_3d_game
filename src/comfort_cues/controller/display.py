from __future__ import annotations

from dataclasses import dataclass, replace


@dataclass(frozen=True, slots=True)
class DisabledDisplayState:
    status_text: str = "Comfort Cues disabled."
    active_window_title: str = ""
    active_profile_name: str = ""
    active_window_mode: str = "disabled"
    active_exe_name: str = ""
    overlay_visible: bool = False
    left_alpha: float = 0.0
    right_alpha: float = 0.0
    top_alpha: float = 0.0
    bottom_alpha: float = 0.0
    center_bias: float = 0.0
    left_density: float = 0.0
    right_density: float = 0.0
    top_density: float = 0.0
    bottom_density: float = 0.0
    cue_motion_x: float = 0.0
    cue_motion_y: float = 0.0
    cue_energy: float = 0.0


def flow_speed(pattern: str, cue_energy: float) -> float:
    energy = max(0.0, min(1.0, cue_energy))
    if energy <= 0.001:
        return 0.0
    if pattern == "dynamic":
        return 0.22 + energy * 4.6
    return 0.12 + energy * 2.1


def display_cue_energy(cue_energy: float, debug_enabled: bool, debug_multiplier: float) -> float:
    if not debug_enabled:
        return cue_energy
    return min(1.0, cue_energy * debug_multiplier)


def apply_debug_visibility(
    state: DisabledDisplayState,
    debug_enabled: bool,
    debug_multiplier: float,
) -> DisabledDisplayState:
    if not debug_enabled or not state.overlay_visible:
        return state

    density_scale = 0.9 + debug_multiplier * 0.18
    return replace(
        state,
        left_alpha=min(1.0, state.left_alpha * debug_multiplier),
        right_alpha=min(1.0, state.right_alpha * debug_multiplier),
        top_alpha=min(1.0, state.top_alpha * debug_multiplier),
        bottom_alpha=min(1.0, state.bottom_alpha * debug_multiplier),
        left_density=min(1.0, state.left_density * density_scale),
        right_density=min(1.0, state.right_density * density_scale),
        top_density=min(1.0, state.top_density * density_scale),
        bottom_density=min(1.0, state.bottom_density * density_scale),
    )
