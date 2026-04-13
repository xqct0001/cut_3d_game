from comfort_cues.app_state import AppState, load_app_state, save_app_state


def test_load_app_state_defaults_to_enabled_and_first_run(tmp_path):
    state = load_app_state(tmp_path / "app-state.json")

    assert state.app_enabled is True
    assert state.launch_to_tray is False
    assert state.ui_language == "en"


def test_save_and_reload_app_state_round_trip(tmp_path):
    path = tmp_path / "app-state.json"
    save_app_state(path, AppState(app_enabled=False, launch_to_tray=True, ui_language="zh"))

    state = load_app_state(path)

    assert state.app_enabled is False
    assert state.launch_to_tray is True
    assert state.ui_language == "zh"
