from __future__ import annotations

from pathlib import Path
import sys

from PySide6 import QtWidgets

from comfort_cues.app import AppController, create_engine
from comfort_cues.app_state import default_data_root
from comfort_cues.ui.settings import apply_app_icon


def _resource_root() -> Path:
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS)
    return Path(__file__).resolve().parents[2]


def main() -> int:
    app = QtWidgets.QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    resource_root = _resource_root()
    controller = AppController(root_path=resource_root, app=app, data_root=default_data_root())
    engine, overlay_window, settings_window = create_engine(controller)
    app._comfort_cues_icon = apply_app_icon(app, resource_root, settings_window)
    controller.attach_windows(overlay_window, settings_window)
    if controller.should_show_window_on_launch():
        controller.open_settings()
        controller.complete_first_run()
    app._comfort_cues_engine = engine
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
