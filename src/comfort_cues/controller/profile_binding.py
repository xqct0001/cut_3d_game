from __future__ import annotations

from dataclasses import replace
from pathlib import Path

from comfort_cues.config import Profile


def title_tokens(title: str) -> list[str]:
    lowered = title.lower().strip()
    return [lowered[:80]] if lowered else []


def profile_name_for_window(window) -> str:
    title = window.title.strip()
    if title:
        return title[:48]
    stem = Path(window.exe_name).stem.strip()
    if stem:
        return stem[:48]
    return "Game Profile"


def binding_profile_for_window(selected_profile: Profile, window) -> Profile:
    if not selected_profile.is_default:
        return selected_profile

    name = profile_name_for_window(window)
    return replace(
        selected_profile,
        name=name,
        description=f"{name} windowed or borderless profile.",
        match_exe=(),
        match_title=(),
        last_bound_exe="",
        last_bound_title="",
        file_path=None,
        is_default=False,
    )
