from pathlib import Path

from PySide6 import QtWidgets

from comfort_cues.app import AppController, _flow_speed
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


def test_bind_current_window_updates_cs2_profile(tmp_path: Path):
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
    cs2_profile = (profiles / "cs2.toml").read_text(encoding="utf-8").lower()
    assert 'cs2.exe' in cs2_profile
    assert 'counter-strike' in cs2_profile
    assert "bound current window to cs2 profile" in controller.statusText.lower()


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


def test_debug_visibility_keeps_directional_ordering(tmp_path: Path):
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
    controller._left_alpha = 0.10
    controller._right_alpha = 0.22
    controller._top_alpha = 0.04
    controller._bottom_alpha = 0.08
    controller._left_density = 0.35
    controller._right_density = 0.65
    controller._top_density = 0.18
    controller._bottom_density = 0.26
    controller._center_bias = 0.24
    controller.debugOverlayEnabled = True

    controller._apply_debug_visibility()

    assert controller.rightAlpha > controller.leftAlpha > 0.0
    assert controller.rightDensity > controller.leftDensity > 0.0
    assert controller.bottomAlpha > controller.topAlpha >= 0.0


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
    assert _flow_speed("dynamic", 0.0) == 0.0
    assert _flow_speed("regular", 0.0) == 0.0
    assert _flow_speed("dynamic", 0.8) > _flow_speed("regular", 0.8) > 0.0


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
