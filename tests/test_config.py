from pathlib import Path

from comfort_cues.config import Profile, load_profiles


def test_profile_store_matches_by_exe_and_title(tmp_path: Path):
    (tmp_path / "default.toml").write_text(
        'name = "Default"\n'
        'description = "base"\n'
        "match_exe = []\n"
        "match_title = []\n"
        "enable_mouse = true\n"
        "enable_gamepad = true\n"
        "yaw_gain = 1.0\n"
        "pitch_gain = 0.8\n"
        "deadzone = 0.08\n"
        "max_opacity = 0.2\n"
        "fade_in_ms = 100\n"
        "fade_out_ms = 200\n"
        "safe_mode = true\n",
        encoding="utf-8",
    )
    (tmp_path / "sample.toml").write_text(
        'name = "Sample"\n'
        'description = "sample"\n'
        'match_exe = ["demo.exe"]\n'
        'match_title = ["demo scene"]\n',
        encoding="utf-8",
    )
    store = load_profiles(tmp_path)
    assert store.match_for_window("demo.exe", "Ignored").name == "Sample"
    assert store.match_for_window("other.exe", "Demo Scene Preview").name == "Sample"
    assert store.match_for_window("other.exe", "Elsewhere") is None
    assert store.default_profile.cue_pattern == "dynamic"
    assert store.default_profile.cue_visibility == "standard"
    assert store.default_profile.debug_opacity_multiplier == 1.8


def test_profile_store_save_round_trip(tmp_path: Path):
    (tmp_path / "default.toml").write_text(
        'name = "Default"\n'
        'description = ""\n'
        "match_exe = []\n"
        "match_title = []\n"
        "enable_mouse = true\n"
        "enable_gamepad = true\n"
        "yaw_gain = 1.0\n"
        "pitch_gain = 0.8\n"
        "deadzone = 0.08\n"
        "max_opacity = 0.2\n"
        "fade_in_ms = 100\n"
        "fade_out_ms = 200\n"
        "safe_mode = true\n",
        encoding="utf-8",
    )
    store = load_profiles(tmp_path)
    updated = Profile(
        name="Default",
        yaw_gain=1.4,
        pitch_gain=0.9,
        cue_pattern="regular",
        cue_visibility="more_dots",
        file_path=tmp_path / "default.toml",
        is_default=True,
    )
    path = store.save_profile(updated)
    assert path.exists()
    reloaded = load_profiles(tmp_path)
    assert reloaded.default_profile.yaw_gain == 1.4
    assert reloaded.default_profile.cue_pattern == "regular"
    assert reloaded.default_profile.cue_visibility == "more_dots"
    assert reloaded.default_profile.debug_opacity_multiplier == 1.8
