from __future__ import annotations

import math
from pathlib import Path
from time import perf_counter

from PySide6 import QtCore, QtQml, QtWidgets

from comfort_cues.app_state import default_app_state_path, load_app_state, save_app_state
from comfort_cues.config import load_profiles
from comfort_cues.controller.display import DisabledDisplayState, apply_debug_visibility, display_cue_energy, flow_speed
from comfort_cues.controller.profile_binding import binding_profile_for_window, title_tokens
from comfort_cues.controller.profile_templates import ensure_profile_templates
from comfort_cues.controller.status import extract_exe_name
from comfort_cues.engine.cues import CueEngine
from comfort_cues.engine.signal import SignalProcessor
from comfort_cues.platform.win32_input import Win32InputSource
from comfort_cues.platform.window_tracker import ForegroundWindowTracker
from comfort_cues.runtime import RuntimeService
from comfort_cues.ui.overlay import apply_overlay_geometry, configure_overlay_window, resolve_overlay_rect
from comfort_cues.ui.settings import create_tray_icon, refresh_tray_icon


class AppController(QtCore.QObject):
    stateChanged = QtCore.Signal()
    cueChanged = QtCore.Signal()
    profileChanged = QtCore.Signal()
    profilesChanged = QtCore.Signal()

    def __init__(
        self,
        root_path: Path,
        app: QtWidgets.QApplication,
        state_path: Path | None = None,
        data_root: Path | None = None,
    ) -> None:
        super().__init__()
        self._root_path = root_path
        self._data_root = data_root or root_path
        self._profiles_dir = self._data_root / "profiles"
        self._app = app
        self._app_state_path = state_path or default_app_state_path()
        legacy_state_path = root_path / "profiles" / "app-state.json"
        if self._app_state_path.exists():
            self._app_state = load_app_state(self._app_state_path)
        elif legacy_state_path.exists():
            self._app_state = load_app_state(legacy_state_path)
            save_app_state(self._app_state_path, self._app_state)
        else:
            self._app_state = load_app_state(self._app_state_path)
        ensure_profile_templates(root_path / "profiles", self._profiles_dir)
        self._profile_store = load_profiles(self._profiles_dir)
        self._selected_profile = self._profile_store.clone_profile("CS2" if "CS2" in self._profile_store.profile_names() else self._profile_store.default_profile.name)
        self._tracker = ForegroundWindowTracker()
        self._input_source = Win32InputSource(self)
        self._input_source.start()
        self._runtime = RuntimeService(
            tracker=self._tracker,
            input_source=self._input_source,
            profile_store=self._profile_store,
            signal_processor=SignalProcessor(),
            cue_engine=CueEngine(),
        )
        self._overlay_window = None
        self._settings_window = None
        self._status_text = "Ready."
        self._active_window_title = ""
        self._active_profile_name = ""
        self._active_window_mode = "idle"
        self._active_exe_name = ""
        self._overlay_visible = False
        self._overlay_x = 0
        self._overlay_y = 0
        self._overlay_width = 1280
        self._overlay_height = 720
        self._left_alpha = 0.0
        self._right_alpha = 0.0
        self._top_alpha = 0.0
        self._bottom_alpha = 0.0
        self._center_bias = 0.0
        self._left_density = 0.0
        self._right_density = 0.0
        self._top_density = 0.0
        self._bottom_density = 0.0
        self._center_safe_ratio = 0.74
        self._cue_motion_x = 0.0
        self._cue_motion_y = 0.0
        self._cue_energy = 0.0
        self._flow_phase = 0.0
        self._last_flow_timestamp_ms: float | None = None
        self._debug_overlay_enabled = False
        self._app_enabled = self._app_state.app_enabled
        self._ui_language = self._app_state.ui_language
        self._quick_start_visible = True
        self._advanced_visible = False
        if self._app_enabled:
            self._status_text = "Comfort Cues running in background."
        else:
            self._set_disabled_view()
        self._tray = create_tray_icon(app, self)

        self._timer = QtCore.QTimer(self)
        self._timer.setInterval(16)
        self._timer.timeout.connect(self._tick)

    def attach_windows(self, overlay_window, settings_window) -> None:
        self._overlay_window = overlay_window
        self._settings_window = settings_window
        configure_overlay_window(overlay_window)
        self._timer.start()

    @QtCore.Slot()
    def open_settings(self) -> None:
        if self._settings_window is not None:
            self._settings_window.show()
            self._settings_window.raise_()
            self._settings_window.requestActivate()

    def should_show_window_on_launch(self) -> bool:
        return not self._app_state.launch_to_tray

    def complete_first_run(self) -> None:
        if self._app_state.launch_to_tray:
            return
        self._app_state.launch_to_tray = True
        self._persist_app_state()

    @QtCore.Slot()
    def reload_profiles(self) -> None:
        self._profile_store = load_profiles(self._profiles_dir)
        target_name = self._selected_profile.name if self._selected_profile.name in self._profile_store.profile_names() else self._profile_store.default_profile.name
        self._selected_profile = self._profile_store.clone_profile(target_name)
        self.profilesChanged.emit()
        self.profileChanged.emit()

    @QtCore.Slot()
    def enableApp(self) -> None:
        self._app_enabled = True
        self._status_text = "Comfort Cues running in background."
        self._persist_app_state()
        self.stateChanged.emit()
        refresh_tray_icon(self._tray, self)

    @QtCore.Slot()
    def disableApp(self) -> None:
        self._app_enabled = False
        self._runtime.reset()
        self._set_disabled_view()
        self._persist_app_state()
        self.stateChanged.emit()
        self.cueChanged.emit()
        refresh_tray_icon(self._tray, self)

    @QtCore.Slot()
    def saveSelectedProfile(self) -> None:
        saved = self._profile_store.save_profile(self._selected_profile)
        self._status_text = f"Saved profile to {saved.name}"
        self.stateChanged.emit()
        self.profilesChanged.emit()

    @QtCore.Slot()
    def bindCurrentWindow(self) -> None:
        window = self._runtime.foreground_window()
        if window is None:
            self._status_text = "Bind failed: no foreground game window detected."
            self.stateChanged.emit()
            return
        self._active_window_title = window.title
        self._active_window_mode = window.mode
        self._active_exe_name = window.exe_name
        if not window.supported:
            self._status_text = f"Bind failed: {window.exe_name} - {window.reason}"
            self.stateChanged.emit()
            return

        profile = binding_profile_for_window(self._selected_profile, window)
        profile.match_exe = tuple(dict.fromkeys([window.exe_name, *profile.match_exe]))
        profile.match_title = tuple(dict.fromkeys([*title_tokens(window.title), *profile.match_title]))
        profile.last_bound_exe = window.exe_name
        profile.last_bound_title = window.title.lower()
        saved_profile_name = profile.name
        self._profile_store.save_profile(profile)
        self._profile_store = load_profiles(self._profiles_dir)
        if saved_profile_name in self._profile_store.profile_names():
            self._selected_profile = self._profile_store.clone_profile(saved_profile_name)
        else:
            self._selected_profile = self._profile_store.clone_profile(self._profile_store.default_profile.name)
        self._status_text = f"Bound current window to {saved_profile_name} profile: {window.exe_name}"
        self._active_profile_name = saved_profile_name
        self.profilesChanged.emit()
        self.profileChanged.emit()
        self.stateChanged.emit()

    @QtCore.Slot()
    def quit_application(self) -> None:
        self._tray.hide()
        self._app.quit()

    @QtCore.Slot()
    def resetSimulator(self) -> None:
        self._runtime.simulation.yaw = 0.0
        self._runtime.simulation.pitch = 0.0
        self._runtime.simulation.lateral = 0.0
        self.stateChanged.emit()

    def _tick(self) -> None:
        if not self._app_enabled:
            self._set_disabled_view()
            self.stateChanged.emit()
            self.cueChanged.emit()
            return

        timestamp_ms = perf_counter() * 1000.0
        view = self._runtime.tick(timestamp_ms, self._selected_profile)
        overlay_rect = view.overlay_rect
        if self._overlay_window is not None:
            overlay_rect = resolve_overlay_rect(self._overlay_window, overlay_rect)
        base_cue_energy = view.cue_state.energy
        self._advance_flow_phase(timestamp_ms, base_cue_energy)
        self._status_text = view.status_text
        self._active_profile_name = view.active_profile_name
        self._active_window_title = view.active_window_title
        self._active_window_mode = view.support_mode
        self._active_exe_name = extract_exe_name(view.status_text)
        self._overlay_visible = view.overlay_visible
        self._overlay_x = overlay_rect.x
        self._overlay_y = overlay_rect.y
        self._overlay_width = overlay_rect.width
        self._overlay_height = overlay_rect.height
        self._left_alpha = view.cue_state.left_alpha
        self._right_alpha = view.cue_state.right_alpha
        self._top_alpha = view.cue_state.top_alpha
        self._bottom_alpha = view.cue_state.bottom_alpha
        self._center_bias = view.cue_state.center_bias
        self._left_density = view.cue_state.left_density
        self._right_density = view.cue_state.right_density
        self._top_density = view.cue_state.top_density
        self._bottom_density = view.cue_state.bottom_density
        self._center_safe_ratio = view.cue_state.center_safe_ratio
        self._cue_motion_x = view.cue_state.motion_x
        self._cue_motion_y = view.cue_state.motion_y
        self._cue_energy = display_cue_energy(
            base_cue_energy,
            self._debug_overlay_enabled,
            self._selected_profile.debug_opacity_multiplier,
        )
        debug_state = apply_debug_visibility(
            DisabledDisplayState(
                overlay_visible=self._overlay_visible,
                left_alpha=self._left_alpha,
                right_alpha=self._right_alpha,
                top_alpha=self._top_alpha,
                bottom_alpha=self._bottom_alpha,
                left_density=self._left_density,
                right_density=self._right_density,
                top_density=self._top_density,
                bottom_density=self._bottom_density,
            ),
            self._debug_overlay_enabled,
            self._selected_profile.debug_opacity_multiplier,
        )
        self._left_alpha = debug_state.left_alpha
        self._right_alpha = debug_state.right_alpha
        self._top_alpha = debug_state.top_alpha
        self._bottom_alpha = debug_state.bottom_alpha
        self._left_density = debug_state.left_density
        self._right_density = debug_state.right_density
        self._top_density = debug_state.top_density
        self._bottom_density = debug_state.bottom_density
        if self._overlay_window is not None:
            apply_overlay_geometry(self._overlay_window, overlay_rect)
        self.stateChanged.emit()
        self.cueChanged.emit()

    def _set_disabled_view(self) -> None:
        state = DisabledDisplayState()
        self._status_text = state.status_text
        self._active_window_title = state.active_window_title
        self._active_profile_name = state.active_profile_name
        self._active_window_mode = state.active_window_mode
        self._active_exe_name = state.active_exe_name
        self._overlay_visible = state.overlay_visible
        self._left_alpha = state.left_alpha
        self._right_alpha = state.right_alpha
        self._top_alpha = state.top_alpha
        self._bottom_alpha = state.bottom_alpha
        self._center_bias = state.center_bias
        self._left_density = state.left_density
        self._right_density = state.right_density
        self._top_density = state.top_density
        self._bottom_density = state.bottom_density
        self._cue_motion_x = state.cue_motion_x
        self._cue_motion_y = state.cue_motion_y
        self._cue_energy = state.cue_energy
        self._flow_phase = 0.0
        self._last_flow_timestamp_ms = None

    def _persist_app_state(self) -> None:
        self._app_state.app_enabled = self._app_enabled
        self._app_state.ui_language = self._ui_language
        save_app_state(self._app_state_path, self._app_state)

    def _advance_flow_phase(self, timestamp_ms: float, cue_energy: float) -> None:
        previous = self._last_flow_timestamp_ms
        self._last_flow_timestamp_ms = timestamp_ms
        dt_ms = 16.0 if previous is None else max(1.0, timestamp_ms - previous)
        speed = flow_speed(self._selected_profile.cue_pattern, cue_energy)
        self._flow_phase = (self._flow_phase + dt_ms / 1000.0 * speed) % math.tau

    @QtCore.Property("QVariantList", notify=profilesChanged)
    def profileOptions(self) -> list[str]:
        return self._profile_store.profile_names()

    @QtCore.Property(str, notify=profileChanged)
    def selectedProfileName(self) -> str:
        return self._selected_profile.name

    @selectedProfileName.setter
    def selectedProfileName(self, value: str) -> None:
        self._selected_profile = self._profile_store.clone_profile(value)
        self.profileChanged.emit()

    @QtCore.Property(bool, notify=stateChanged)
    def overlayVisible(self) -> bool:
        return self._overlay_visible

    @QtCore.Property(int, notify=stateChanged)
    def overlayX(self) -> int:
        return self._overlay_x

    @QtCore.Property(int, notify=stateChanged)
    def overlayY(self) -> int:
        return self._overlay_y

    @QtCore.Property(int, notify=stateChanged)
    def overlayWidth(self) -> int:
        return self._overlay_width

    @QtCore.Property(int, notify=stateChanged)
    def overlayHeight(self) -> int:
        return self._overlay_height

    @QtCore.Property(float, notify=cueChanged)
    def leftAlpha(self) -> float:
        return self._left_alpha

    @QtCore.Property(float, notify=cueChanged)
    def rightAlpha(self) -> float:
        return self._right_alpha

    @QtCore.Property(float, notify=cueChanged)
    def topAlpha(self) -> float:
        return self._top_alpha

    @QtCore.Property(float, notify=cueChanged)
    def bottomAlpha(self) -> float:
        return self._bottom_alpha

    @QtCore.Property(float, notify=cueChanged)
    def centerBias(self) -> float:
        return self._center_bias

    @QtCore.Property(float, notify=cueChanged)
    def leftDensity(self) -> float:
        return self._left_density

    @QtCore.Property(float, notify=cueChanged)
    def rightDensity(self) -> float:
        return self._right_density

    @QtCore.Property(float, notify=cueChanged)
    def topDensity(self) -> float:
        return self._top_density

    @QtCore.Property(float, notify=cueChanged)
    def bottomDensity(self) -> float:
        return self._bottom_density

    @QtCore.Property(float, notify=cueChanged)
    def centerSafeRatio(self) -> float:
        return self._center_safe_ratio

    @QtCore.Property(float, notify=cueChanged)
    def cueMotionX(self) -> float:
        return self._cue_motion_x

    @QtCore.Property(float, notify=cueChanged)
    def cueMotionY(self) -> float:
        return self._cue_motion_y

    @QtCore.Property(float, notify=cueChanged)
    def cueEnergy(self) -> float:
        return self._cue_energy

    @QtCore.Property(float, notify=cueChanged)
    def flowPhase(self) -> float:
        return self._flow_phase

    @QtCore.Property(str, notify=stateChanged)
    def statusText(self) -> str:
        return self._status_text

    @QtCore.Property(str, notify=stateChanged)
    def activeWindowTitle(self) -> str:
        return self._active_window_title

    @QtCore.Property(str, notify=stateChanged)
    def activeProfileName(self) -> str:
        return self._active_profile_name

    @QtCore.Property(str, notify=stateChanged)
    def activeWindowMode(self) -> str:
        return self._active_window_mode

    @QtCore.Property(str, notify=stateChanged)
    def activeExeName(self) -> str:
        return self._active_exe_name

    @QtCore.Property(bool, notify=stateChanged)
    def appEnabled(self) -> bool:
        return self._app_enabled

    @QtCore.Property(str, notify=stateChanged)
    def uiLanguage(self) -> str:
        return self._ui_language

    @uiLanguage.setter
    def uiLanguage(self, value: str) -> None:
        normalized = "zh" if str(value).strip().lower() == "zh" else "en"
        if self._ui_language == normalized:
            return
        self._ui_language = normalized
        self._app_state.ui_language = normalized
        self._persist_app_state()
        refresh_tray_icon(self._tray, self)
        self.stateChanged.emit()

    @QtCore.Property(float, notify=profileChanged)
    def yawGain(self) -> float:
        return self._selected_profile.yaw_gain

    @yawGain.setter
    def yawGain(self, value: float) -> None:
        self._selected_profile.yaw_gain = float(value)
        self.profileChanged.emit()

    @QtCore.Property(float, notify=profileChanged)
    def pitchGain(self) -> float:
        return self._selected_profile.pitch_gain

    @pitchGain.setter
    def pitchGain(self, value: float) -> None:
        self._selected_profile.pitch_gain = float(value)
        self.profileChanged.emit()

    @QtCore.Property(float, notify=profileChanged)
    def deadzone(self) -> float:
        return self._selected_profile.deadzone

    @deadzone.setter
    def deadzone(self, value: float) -> None:
        self._selected_profile.deadzone = float(value)
        self.profileChanged.emit()

    @QtCore.Property(float, notify=profileChanged)
    def maxOpacity(self) -> float:
        return self._selected_profile.max_opacity

    @maxOpacity.setter
    def maxOpacity(self, value: float) -> None:
        self._selected_profile.max_opacity = float(value)
        self.profileChanged.emit()

    @QtCore.Property(float, notify=profileChanged)
    def fadeInMs(self) -> float:
        return self._selected_profile.fade_in_ms

    @fadeInMs.setter
    def fadeInMs(self, value: float) -> None:
        self._selected_profile.fade_in_ms = float(value)
        self.profileChanged.emit()

    @QtCore.Property(float, notify=profileChanged)
    def fadeOutMs(self) -> float:
        return self._selected_profile.fade_out_ms

    @fadeOutMs.setter
    def fadeOutMs(self, value: float) -> None:
        self._selected_profile.fade_out_ms = float(value)
        self.profileChanged.emit()

    @QtCore.Property(bool, notify=profileChanged)
    def enableMouse(self) -> bool:
        return self._selected_profile.enable_mouse

    @enableMouse.setter
    def enableMouse(self, value: bool) -> None:
        self._selected_profile.enable_mouse = bool(value)
        self.profileChanged.emit()

    @QtCore.Property(bool, notify=profileChanged)
    def enableGamepad(self) -> bool:
        return self._selected_profile.enable_gamepad

    @enableGamepad.setter
    def enableGamepad(self, value: bool) -> None:
        self._selected_profile.enable_gamepad = bool(value)
        self.profileChanged.emit()

    @QtCore.Property(bool, notify=profileChanged)
    def safeMode(self) -> bool:
        return self._selected_profile.safe_mode

    @safeMode.setter
    def safeMode(self, value: bool) -> None:
        self._selected_profile.safe_mode = bool(value)
        self.profileChanged.emit()

    @QtCore.Property(str, notify=profileChanged)
    def cuePattern(self) -> str:
        return self._selected_profile.cue_pattern

    @cuePattern.setter
    def cuePattern(self, value: str) -> None:
        self._selected_profile.cue_pattern = str(value).strip().lower()
        self.profileChanged.emit()

    @QtCore.Property(str, notify=profileChanged)
    def cueVisibility(self) -> str:
        return self._selected_profile.cue_visibility

    @cueVisibility.setter
    def cueVisibility(self, value: str) -> None:
        self._selected_profile.cue_visibility = str(value).strip().lower()
        self.profileChanged.emit()

    @QtCore.Property(bool, notify=stateChanged)
    def debugOverlayEnabled(self) -> bool:
        return self._debug_overlay_enabled

    @debugOverlayEnabled.setter
    def debugOverlayEnabled(self, value: bool) -> None:
        self._debug_overlay_enabled = bool(value)
        self.stateChanged.emit()

    @QtCore.Property(bool, notify=stateChanged)
    def quickStartVisible(self) -> bool:
        return self._quick_start_visible

    @quickStartVisible.setter
    def quickStartVisible(self, value: bool) -> None:
        self._quick_start_visible = bool(value)
        self.stateChanged.emit()

    @QtCore.Property(bool, notify=stateChanged)
    def advancedVisible(self) -> bool:
        return self._advanced_visible

    @advancedVisible.setter
    def advancedVisible(self, value: bool) -> None:
        self._advanced_visible = bool(value)
        self.stateChanged.emit()

    @QtCore.Property(bool, notify=stateChanged)
    def simulatorEnabled(self) -> bool:
        return self._runtime.simulation.enabled

    @simulatorEnabled.setter
    def simulatorEnabled(self, value: bool) -> None:
        self._runtime.simulation.enabled = bool(value)
        self.stateChanged.emit()

    @QtCore.Property(float, notify=stateChanged)
    def simYaw(self) -> float:
        return self._runtime.simulation.yaw

    @simYaw.setter
    def simYaw(self, value: float) -> None:
        self._runtime.simulation.yaw = float(value)
        self.stateChanged.emit()

    @QtCore.Property(float, notify=stateChanged)
    def simPitch(self) -> float:
        return self._runtime.simulation.pitch

    @simPitch.setter
    def simPitch(self, value: float) -> None:
        self._runtime.simulation.pitch = float(value)
        self.stateChanged.emit()

    @QtCore.Property(float, notify=stateChanged)
    def simLateral(self) -> float:
        return self._runtime.simulation.lateral

    @simLateral.setter
    def simLateral(self, value: float) -> None:
        self._runtime.simulation.lateral = float(value)
        self.stateChanged.emit()

    @QtCore.Property("QVariantList", constant=True)
    def cuePatternOptions(self) -> list[str]:
        return ["dynamic", "regular"]

    @QtCore.Property("QVariantList", constant=True)
    def cueVisibilityOptions(self) -> list[str]:
        return ["standard", "larger_dots", "more_dots"]


def create_engine(controller: AppController) -> tuple[QtQml.QQmlApplicationEngine, object, object]:
    qml_dir = controller._root_path / "src" / "comfort_cues" / "ui" / "qml"
    engine = QtQml.QQmlApplicationEngine()
    engine.rootContext().setContextProperty("controller", controller)
    engine.load(QtCore.QUrl.fromLocalFile(str(qml_dir / "OverlayWindow.qml")))
    engine.load(QtCore.QUrl.fromLocalFile(str(qml_dir / "SettingsWindow.qml")))

    overlay_window = None
    settings_window = None
    for root in engine.rootObjects():
        if root.objectName() == "overlayWindow":
            overlay_window = root
        if root.objectName() == "settingsWindow":
            settings_window = root
    if overlay_window is None or settings_window is None:
        raise RuntimeError("Failed to load QML windows.")
    return engine, overlay_window, settings_window
