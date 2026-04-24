import os
from pathlib import Path
import shutil

from PySide6 import QtCore, QtQml, QtWidgets

from comfort_cues.app import AppController, create_engine
from comfort_cues.ui.settings import load_app_icon, resolve_app_icon_path


os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")


class FakeController(QtCore.QObject):
    def __init__(self, **values):
        super().__init__()
        defaults = {
            "overlay_visible": True,
            "overlay_x": 0,
            "overlay_y": 0,
            "overlay_width": 1280,
            "overlay_height": 720,
            "cue_pattern": "dynamic",
            "cue_visibility": "standard",
            "debug_overlay_enabled": False,
            "cue_energy": 0.0,
            "ui_language": "en",
            "left_alpha": 0.0,
            "right_alpha": 0.0,
            "top_alpha": 0.0,
            "bottom_alpha": 0.0,
            "left_density": 0.0,
            "right_density": 0.0,
            "top_density": 0.0,
            "bottom_density": 0.0,
            "cue_motion_x": 0.0,
            "cue_motion_y": 0.0,
            "flow_phase": 0.0,
            "max_opacity": 0.2,
            "active_profile_name": "Test",
        }
        defaults.update(values)
        for key, value in defaults.items():
            setattr(self, f"_{key}", value)

    @QtCore.Property(bool, constant=True)
    def overlayVisible(self) -> bool:
        return self._overlay_visible

    @QtCore.Property(int, constant=True)
    def overlayX(self) -> int:
        return self._overlay_x

    @QtCore.Property(int, constant=True)
    def overlayY(self) -> int:
        return self._overlay_y

    @QtCore.Property(int, constant=True)
    def overlayWidth(self) -> int:
        return self._overlay_width

    @QtCore.Property(int, constant=True)
    def overlayHeight(self) -> int:
        return self._overlay_height

    @QtCore.Property(str, constant=True)
    def cuePattern(self) -> str:
        return self._cue_pattern

    @QtCore.Property(str, constant=True)
    def uiLanguage(self) -> str:
        return self._ui_language

    @QtCore.Property(str, constant=True)
    def cueVisibility(self) -> str:
        return self._cue_visibility

    @QtCore.Property(bool, constant=True)
    def debugOverlayEnabled(self) -> bool:
        return self._debug_overlay_enabled

    @QtCore.Property(float, constant=True)
    def cueEnergy(self) -> float:
        return self._cue_energy

    @QtCore.Property(float, constant=True)
    def leftAlpha(self) -> float:
        return self._left_alpha

    @QtCore.Property(float, constant=True)
    def rightAlpha(self) -> float:
        return self._right_alpha

    @QtCore.Property(float, constant=True)
    def topAlpha(self) -> float:
        return self._top_alpha

    @QtCore.Property(float, constant=True)
    def bottomAlpha(self) -> float:
        return self._bottom_alpha

    @QtCore.Property(float, constant=True)
    def leftDensity(self) -> float:
        return self._left_density

    @QtCore.Property(float, constant=True)
    def rightDensity(self) -> float:
        return self._right_density

    @QtCore.Property(float, constant=True)
    def topDensity(self) -> float:
        return self._top_density

    @QtCore.Property(float, constant=True)
    def bottomDensity(self) -> float:
        return self._bottom_density

    @QtCore.Property(float, constant=True)
    def cueMotionX(self) -> float:
        return self._cue_motion_x

    @QtCore.Property(float, constant=True)
    def cueMotionY(self) -> float:
        return self._cue_motion_y

    @QtCore.Property(float, constant=True)
    def flowPhase(self) -> float:
        return self._flow_phase

    @QtCore.Property(float, constant=True)
    def maxOpacity(self) -> float:
        return self._max_opacity

    @QtCore.Property(str, constant=True)
    def activeProfileName(self) -> str:
        return self._active_profile_name


def _write_default_profile(path: Path) -> None:
    path.write_text(
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


def _copy_qml_tree(root: Path) -> None:
    qml_src = Path(__file__).resolve().parents[1] / "src" / "comfort_cues" / "ui" / "qml"
    qml_dst = root / "src" / "comfort_cues" / "ui" / "qml"
    assets_src = Path(__file__).resolve().parents[1] / "src" / "comfort_cues" / "ui" / "assets"
    assets_dst = root / "src" / "comfort_cues" / "ui" / "assets"
    qml_dst.mkdir(parents=True)
    assets_dst.mkdir(parents=True)
    shutil.copy2(qml_src / "OverlayWindow.qml", qml_dst / "OverlayWindow.qml")
    shutil.copy2(qml_src / "SettingsWindow.qml", qml_dst / "SettingsWindow.qml")
    for asset_name in ("tray-dog.jpg", "comfort-cues.ico"):
        if (assets_src / asset_name).exists():
            shutil.copy2(assets_src / asset_name, assets_dst / asset_name)


def _load_overlay(controller: QtCore.QObject):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    engine = QtQml.QQmlApplicationEngine()
    engine.rootContext().setContextProperty("controller", controller)
    qml_path = Path(__file__).resolve().parents[1] / "src" / "comfort_cues" / "ui" / "qml" / "OverlayWindow.qml"
    engine.load(QtCore.QUrl.fromLocalFile(str(qml_path)))
    app.processEvents()
    return app, engine, engine.rootObjects()[0]


def test_create_engine_loads_overlay_and_settings_windows(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    profiles = tmp_path / "profiles"
    profiles.mkdir()
    _write_default_profile(profiles / "default.toml")
    _copy_qml_tree(tmp_path)

    controller = AppController(tmp_path, app, state_path=tmp_path / "app-state.json")
    engine, overlay, settings = create_engine(controller)
    app.processEvents()

    assert [obj.objectName() for obj in engine.rootObjects()] == ["overlayWindow", "settingsWindow"]
    assert overlay.objectName() == "overlayWindow"
    assert settings.objectName() == "settingsWindow"
    assert settings.property("visible") is False
    assert settings.property("width") == 720
    assert settings.property("height") == 760
    assert settings.property("minimumWidth") == 640
    assert settings.property("minimumHeight") == 620
    assert settings.findChild(QtCore.QObject, "windowSummaryLabel") is not None
    assert settings.findChild(QtCore.QObject, "quickStartCard") is not None
    assert settings.findChild(QtCore.QObject, "enableButton") is not None
    assert settings.findChild(QtCore.QObject, "disableButton") is not None
    assert settings.findChild(QtCore.QObject, "bindWindowButton") is not None
    assert settings.findChild(QtCore.QObject, "debugButton") is not None
    assert settings.findChild(QtCore.QObject, "reloadButton") is not None
    assert settings.findChild(QtCore.QObject, "saveButton") is not None
    advanced_toggle = settings.findChild(QtCore.QObject, "advancedToggle")
    assert advanced_toggle is not None
    assert advanced_toggle.property("text") == "Show controls"
    language_combo = settings.findChild(QtCore.QObject, "languageCombo")
    assert language_combo is not None
    advanced_details = settings.findChild(QtCore.QObject, "advancedDetails")
    assert advanced_details is not None
    assert advanced_details.property("visible") is False
    assert settings.findChild(QtCore.QObject, "exitButton") is None


def test_load_app_icon_prefers_ico_asset(tmp_path: Path):
    app = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    _copy_qml_tree(tmp_path)

    icon_path = resolve_app_icon_path(tmp_path)
    icon = load_app_icon(app, tmp_path)

    assert icon_path is not None
    assert icon_path.name == "comfort-cues.ico"
    assert not icon.isNull()


def test_overlay_keeps_ambient_points_visible_when_idle():
    _, engine, overlay = _load_overlay(FakeController())

    assert len(engine.rootObjects()) == 1
    assert overlay.property("leftAmbientAlpha") > 0.0
    assert overlay.property("rightAmbientAlpha") > 0.0
    assert overlay.property("topAmbientAlpha") > 0.0
    assert overlay.property("leftAccentAlpha") == 0.0
    assert overlay.property("rightAccentAlpha") == 0.0
    assert overlay.property("topAccentAlpha") == 0.0


def test_overlay_brightens_accent_layer_when_motion_is_present():
    _, _, overlay = _load_overlay(
        FakeController(
            cue_energy=0.75,
            left_alpha=0.16,
            left_density=0.62,
            cue_motion_x=-0.8,
            flow_phase=0.9,
        )
    )

    assert overlay.property("leftAccentAlpha") > overlay.property("leftAmbientAlpha")
    assert overlay.property("leftAccentAlpha") > 0.0
    assert overlay.property("rightAccentAlpha") == 0.0
