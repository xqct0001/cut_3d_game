from __future__ import annotations

from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any
import tomllib


@dataclass(slots=True)
class Profile:
    name: str
    description: str = ""
    match_exe: tuple[str, ...] = ()
    match_title: tuple[str, ...] = ()
    enable_mouse: bool = True
    enable_gamepad: bool = True
    yaw_gain: float = 1.0
    pitch_gain: float = 0.85
    deadzone: float = 0.08
    max_opacity: float = 0.18
    fade_in_ms: float = 120.0
    fade_out_ms: float = 220.0
    safe_mode: bool = True
    cue_pattern: str = "dynamic"
    cue_visibility: str = "standard"
    debug_opacity_multiplier: float = 1.8
    last_bound_exe: str = ""
    last_bound_title: str = ""
    file_path: Path | None = None
    is_default: bool = False

    def matches(self, exe_name: str, title: str) -> bool:
        if self.is_default:
            return False
        exe_name = exe_name.lower()
        title = title.lower()
        exe_match = any(token in exe_name for token in self.match_exe)
        title_match = any(token in title for token in self.match_title)
        return exe_match or title_match


@dataclass(slots=True)
class ProfileStore:
    directory: Path
    default_profile: Profile
    profiles: list[Profile]

    def profile_names(self) -> list[str]:
        return [self.default_profile.name, *[profile.name for profile in self.profiles]]

    def get(self, name: str) -> Profile:
        if name == self.default_profile.name:
            return self.default_profile
        for profile in self.profiles:
            if profile.name == name:
                return profile
        raise KeyError(name)

    def match_for_window(self, exe_name: str, title: str) -> Profile | None:
        for profile in self.profiles:
            if profile.matches(exe_name, title):
                return profile
        return None

    def clone_profile(self, name: str) -> Profile:
        return replace(self.get(name))

    def save_profile(self, profile: Profile) -> Path:
        target = profile.file_path or self.directory / f"{profile.name.lower().replace(' ', '-')}.toml"
        target.write_text(serialize_profile(profile), encoding="utf-8")

        if profile.is_default:
            self.default_profile = replace(profile, file_path=target)
        else:
            for index, existing in enumerate(self.profiles):
                if existing.name == profile.name:
                    self.profiles[index] = replace(profile, file_path=target)
                    break
            else:
                self.profiles.append(replace(profile, file_path=target))
        return target


def load_profiles(directory: Path) -> ProfileStore:
    directory.mkdir(parents=True, exist_ok=True)
    default_path = directory / "default.toml"
    default_profile = (
        _load_profile(default_path, is_default=True)
        if default_path.exists()
        else Profile(name="Default", file_path=default_path, is_default=True)
    )
    profiles: list[Profile] = []
    for path in sorted(directory.glob("*.toml")):
        if path.name == "default.toml":
            continue
        profiles.append(_load_profile(path, base=default_profile))
    return ProfileStore(directory=directory, default_profile=default_profile, profiles=profiles)


def serialize_profile(profile: Profile) -> str:
    lines = [
        f'name = "{profile.name}"',
        f'description = "{_escape(profile.description)}"',
        f"match_exe = [{', '.join(_quote(item) for item in profile.match_exe)}]",
        f"match_title = [{', '.join(_quote(item) for item in profile.match_title)}]",
        f"enable_mouse = {_bool(profile.enable_mouse)}",
        f"enable_gamepad = {_bool(profile.enable_gamepad)}",
        f"yaw_gain = {profile.yaw_gain:.3f}",
        f"pitch_gain = {profile.pitch_gain:.3f}",
        f"deadzone = {profile.deadzone:.3f}",
        f"max_opacity = {profile.max_opacity:.3f}",
        f"fade_in_ms = {profile.fade_in_ms:.0f}",
        f"fade_out_ms = {profile.fade_out_ms:.0f}",
        f"safe_mode = {_bool(profile.safe_mode)}",
        f'cue_pattern = "{_escape(profile.cue_pattern)}"',
        f'cue_visibility = "{_escape(profile.cue_visibility)}"',
        f"debug_opacity_multiplier = {profile.debug_opacity_multiplier:.3f}",
        f'last_bound_exe = "{_escape(profile.last_bound_exe)}"',
        f'last_bound_title = "{_escape(profile.last_bound_title)}"',
    ]
    return "\n".join(lines) + "\n"


def _load_profile(path: Path, base: Profile | None = None, is_default: bool = False) -> Profile:
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    values = {
        "name": str(data.get("name", base.name if base else path.stem.replace("-", " ").title())),
        "description": str(data.get("description", base.description if base else "")),
        "match_exe": tuple(_norm_list(data.get("match_exe", base.match_exe if base else ()))),
        "match_title": tuple(_norm_list(data.get("match_title", base.match_title if base else ()))),
        "enable_mouse": bool(data.get("enable_mouse", base.enable_mouse if base else True)),
        "enable_gamepad": bool(data.get("enable_gamepad", base.enable_gamepad if base else True)),
        "yaw_gain": float(data.get("yaw_gain", base.yaw_gain if base else 1.0)),
        "pitch_gain": float(data.get("pitch_gain", base.pitch_gain if base else 0.85)),
        "deadzone": float(data.get("deadzone", base.deadzone if base else 0.08)),
        "max_opacity": float(data.get("max_opacity", base.max_opacity if base else 0.18)),
        "fade_in_ms": float(data.get("fade_in_ms", base.fade_in_ms if base else 120.0)),
        "fade_out_ms": float(data.get("fade_out_ms", base.fade_out_ms if base else 220.0)),
        "safe_mode": bool(data.get("safe_mode", base.safe_mode if base else True)),
        "cue_pattern": _normalize_pattern(data.get("cue_pattern", base.cue_pattern if base else "dynamic")),
        "cue_visibility": _normalize_visibility(data.get("cue_visibility", base.cue_visibility if base else "standard")),
        "debug_opacity_multiplier": float(data.get("debug_opacity_multiplier", base.debug_opacity_multiplier if base else 1.8)),
        "last_bound_exe": str(data.get("last_bound_exe", base.last_bound_exe if base else "")).lower(),
        "last_bound_title": str(data.get("last_bound_title", base.last_bound_title if base else "")).lower(),
        "file_path": path,
        "is_default": is_default,
    }
    return Profile(**values)


def _norm_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [value.lower()]
    return [str(item).lower() for item in value]


def _quote(value: str) -> str:
    return f'"{_escape(value)}"'


def _escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _bool(value: bool) -> str:
    return "true" if value else "false"


def _normalize_pattern(value: Any) -> str:
    normalized = str(value).strip().lower()
    if normalized in {"dynamic", "regular"}:
        return normalized
    return "dynamic"


def _normalize_visibility(value: Any) -> str:
    normalized = str(value).strip().lower()
    if normalized in {"standard", "larger_dots", "more_dots"}:
        return normalized
    return "standard"
