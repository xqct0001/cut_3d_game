from pathlib import Path

from PySide6 import QtWidgets

from comfort_cues.app import AppController
from comfort_cues.config import Profile
from comfort_cues.controller.display import DisabledDisplayState, apply_debug_visibility, display_cue_energy, flow_speed
from comfort_cues.controller.profile_binding import binding_profile_for_window, profile_name_for_window, title_tokens
from comfort_cues.controller.profile_templates import ensure_profile_templates
from comfort_cues.controller.status import extract_exe_name
from comfort_cues.models import Rect, WindowInfo


class FakeRuntime:
    def __init__(self, window):
        self._window = window

    def foreground_window(self):
        return self._window

    @property
    def simulation(self):
        class Sim:
            enabled = False
            yaw = 0.0
            pitch = 0.0
            lateral = 0.0
        return Sim()

    def tick(self, timestamp_ms, preview_profile):
        raise RuntimeError("not used in this test")


def _window(exe_name="cs2.exe", title="Counter-Strike 2", supported=True, mode="borderless", reason="borderless window supported"):
    return WindowInfo(
        hwnd=1,
        pid=10,
        title=title,
        exe_name=exe_name,
        exe_path=f"C:/Games/{exe_name}",
        rect=Rect(0, 0, 1280, 720),
        monitor_rect=Rect(0, 0, 1920, 1080),
        mode=mode,
        supported=supported,
        reason=reason,
    )


def _controller(tmp_path: Path, app: QtWidgets.QApplication) -> AppController:
    return AppController(tmp_path, app, state_path=tmp_path / "app-state.json")


def test_bind_current_window_creates_profile_from_default_selection(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    controller = _controller(tmp_path, app)
    controller._runtime = FakeRuntime(_window())
    controller.bindCurrentWindow()
    bound_profile = (profiles / "counter-strike-2.toml").read_text(encoding="utf-8").lower()
    assert 'name = "counter-strike 2"' in bound_profile
    assert 'cs2.exe' in bound_profile
    assert 'counter-strike 2' in bound_profile
    assert "bound current window to counter-strike 2 profile" in controller.statusText.lower()
    assert controller.selectedProfileName == "Counter-Strike 2"


def test_bind_current_window_rejects_unsupported_window(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    controller = _controller(tmp_path, app)
    controller._runtime = FakeRuntime(_window(supported=False, mode="exclusive-or-unknown", reason="fullscreen mode not supported"))
    controller.bindCurrentWindow()
    assert "bind failed" in controller.statusText.lower()
    assert not (profiles / "cs2.toml").exists()


def test_extract_exe_name_matches_runtime_status_prefixes():
    assert extract_exe_name("Active: CS2.EXE - Counter-Strike 2") == "cs2.exe"
    assert extract_exe_name("Unsupported ratio: Valorant.exe - 32:9") == "valorant.exe"
    assert extract_exe_name("Unsupported window: Doom.exe - exclusive") == "doom.exe"
    assert extract_exe_name("Window detected but no matched profile: Game.exe - Title") == "game.exe"
    assert extract_exe_name("Bind failed: Editor.exe - fullscreen mode not supported") == "editor.exe"
    assert extract_exe_name("Comfort Cues running in background.") == ""


def test_profile_binding_helpers_match_current_window_behavior():
    window = _window(exe_name="game-client.exe", title="  Very Long Game Window Title  ")

    assert title_tokens(window.title) == ["very long game window title"]
    assert profile_name_for_window(window) == "Very Long Game Window Title"

    selected = Profile(name="Default", description="Default profile", is_default=True)
    bound = binding_profile_for_window(selected, window)
    assert bound.name == "Very Long Game Window Title"
    assert bound.description == "Very Long Game Window Title windowed or borderless profile."
    assert bound.match_exe == ()
    assert bound.match_title == ()
    assert bound.file_path is None
    assert bound.is_default is False

    custom = Profile(name="Custom")
    assert binding_profile_for_window(custom, window) is custom


def test_profile_name_for_window_falls_back_to_exe_stem_and_generic_name():
    assert profile_name_for_window(_window(exe_name="space-game.exe", title="")) == "space-game"
    assert profile_name_for_window(_window(exe_name="", title="")) == "Game Profile"


def test_display_helpers_scale_debug_visibility_and_defaults():
    assert flow_speed("dynamic", 0.0) == 0.0
    assert flow_speed("regular", 0.0) == 0.0
    assert flow_speed("dynamic", 0.8) > flow_speed("regular", 0.8) > 0.0
    assert display_cue_energy(0.75, debug_enabled=False, debug_multiplier=1.8) == 0.75
    assert display_cue_energy(0.75, debug_enabled=True, debug_multiplier=2.0) == 1.0

    state = apply_debug_visibility(
        DisabledDisplayState(
            overlay_visible=True,
            left_alpha=0.10,
            right_alpha=0.22,
            top_alpha=0.04,
            bottom_alpha=0.08,
            left_density=0.35,
            right_density=0.65,
            top_density=0.18,
            bottom_density=0.26,
        ),
        debug_enabled=True,
        debug_multiplier=1.8,
    )
    assert state.right_alpha > state.left_alpha > 0.0
    assert state.right_density > state.left_density > 0.0
    assert state.bottom_alpha > state.top_alpha >= 0.0

    disabled = DisabledDisplayState()
    assert disabled.overlay_visible is False
    assert disabled.active_window_mode == "disabled"
    assert disabled.cue_energy == 0.0


def test_ensure_profile_templates_copies_missing_defaults_only(tmp_path: Path):
    source = tmp_path / "source"
    target = tmp_path / "target"
    source.mkdir()
    (source / "default.toml").write_text("default", encoding="utf-8")
    (source / "sample-third-person.toml").write_text("sample", encoding="utf-8")
    target.mkdir()
    (target / "default.toml").write_text("existing", encoding="utf-8")

    ensure_profile_templates(source, target)

    assert (target / "default.toml").read_text(encoding="utf-8") == "existing"
    assert (target / "sample-third-person.toml").read_text(encoding="utf-8") == "sample"


def test_advanced_panel_defaults_to_hidden_and_can_toggle(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    controller = _controller(tmp_path, app)

    assert controller.advancedVisible is False
    controller.advancedVisible = True
    assert controller.advancedVisible is True


def test_app_defaults_to_enabled_and_can_toggle_runtime_state(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    controller = _controller(tmp_path, app)
    controller._overlay_visible = True
    controller._left_alpha = 0.4
    controller._cue_energy = 0.5

    assert controller.appEnabled is True

    controller.disableApp()
    assert controller.appEnabled is False
    assert controller.overlayVisible is False
    assert controller.leftAlpha == 0.0
    assert controller.cueEnergy == 0.0

    controller.enableApp()
    assert controller.appEnabled is True


def test_first_run_shows_window_then_switches_to_tray_mode(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )

    controller = _controller(tmp_path, app)
    assert controller.should_show_window_on_launch() is True

    controller.complete_first_run()

    second = _controller(tmp_path, app)
    assert second.should_show_window_on_launch() is False


def test_tray_menu_keeps_exit_action_as_only_quit_entry(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    controller = _controller(tmp_path, app)

    action_texts = [
        action.text()
        for action in controller._tray.contextMenu().actions()
        if not action.isSeparator()
    ]

    assert any(text in {"Quit", "退出"} for text in action_texts)
    assert len([text for text in action_texts if text in {"Quit", "退出"}]) == 1


def test_controller_persists_ui_language(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    state_path = tmp_path / "app-state.json"
    controller = AppController(tmp_path, app, state_path=state_path)

    controller.uiLanguage = "zh"

    reloaded = AppController(tmp_path, app, state_path=state_path)
    assert reloaded.uiLanguage == "zh"


def test_controller_migrates_legacy_app_state_to_new_path(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    legacy_state = profiles / "app-state.json"
    legacy_state.write_text('{"app_enabled": false, "launch_to_tray": true}\n', encoding="utf-8")
    new_state = tmp_path / "new-app-state.json"

    controller = AppController(tmp_path, app, state_path=new_state)

    assert controller.appEnabled is False
    assert controller.should_show_window_on_launch() is False
    assert new_state.exists()


def test_flow_speed_stops_when_idle_and_accelerates_with_energy():
    assert flow_speed("dynamic", 0.0) == 0.0
    assert flow_speed("regular", 0.0) == 0.0
    assert flow_speed("dynamic", 0.8) > flow_speed("regular", 0.8) > 0.0


def test_advance_flow_phase_only_moves_when_energy_present(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    (profiles / "default.toml").write_text(
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
        "safe_mode = true\n"
        'cue_pattern = "dynamic"\n'
        'cue_visibility = "standard"\n'
        "debug_opacity_multiplier = 1.8\n"
        'last_bound_exe = ""\n'
        'last_bound_title = ""\n',
        encoding="utf-8",
    )
    controller = _controller(tmp_path, app)

    controller._advance_flow_phase(16.0, 0.0)
    idle_phase = controller.flowPhase
    controller._advance_flow_phase(32.0, 0.0)
    assert controller.flowPhase == idle_phase

    controller._advance_flow_phase(48.0, 0.7)
    assert controller.flowPhase > idle_phase
