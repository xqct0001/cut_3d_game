from __future__ import annotations

from pathlib import Path

from PySide6 import QtGui, QtWidgets


ICON_CANDIDATES = ("comfort-cues.ico", "tray-dog.jpg")


def resolve_app_icon_path(root_path: Path) -> Path | None:
    assets_dir = Path(root_path) / "src" / "comfort_cues" / "ui" / "assets"
    for name in ICON_CANDIDATES:
        candidate = assets_dir / name
        if candidate.exists():
            return candidate
    return None


def load_app_icon(app: QtWidgets.QApplication, root_path: Path) -> QtGui.QIcon:
    asset_path = resolve_app_icon_path(root_path)
    if asset_path is not None:
        icon = QtGui.QIcon(str(asset_path))
        if not icon.isNull():
            return icon
    return QtGui.QIcon(app.style().standardIcon(QtWidgets.QStyle.StandardPixmap.SP_ComputerIcon))


def apply_app_icon(app: QtWidgets.QApplication, root_path: Path, *windows) -> QtGui.QIcon:
    icon = load_app_icon(app, root_path)
    app.setWindowIcon(icon)
    for window in windows:
        if window is not None and hasattr(window, "setIcon"):
            window.setIcon(icon)
    return icon


def create_tray_icon(app: QtWidgets.QApplication, controller) -> QtWidgets.QSystemTrayIcon:
    tray = QtWidgets.QSystemTrayIcon(load_app_icon(app, Path(controller._root_path)), parent=app)

    menu = QtWidgets.QMenu()
    enable_action = menu.addAction("\u5f00\u542f")
    enable_action.triggered.connect(controller.enableApp)

    disable_action = menu.addAction("\u5173\u95ed")
    disable_action.triggered.connect(controller.disableApp)

    menu.addSeparator()

    quit_action = menu.addAction("\u9000\u51fa")
    quit_action.triggered.connect(controller.quit_application)

    tray.setContextMenu(menu)
    tray.enable_action = enable_action
    tray.disable_action = disable_action
    tray.activated.connect(
        lambda reason: controller.open_settings()
        if reason in (
            QtWidgets.QSystemTrayIcon.ActivationReason.Trigger,
            QtWidgets.QSystemTrayIcon.ActivationReason.DoubleClick,
        )
        else None
    )
    refresh_tray_icon(tray, controller)
    tray.show()
    return tray


def refresh_tray_icon(tray: QtWidgets.QSystemTrayIcon, controller) -> None:
    is_chinese = getattr(controller, "uiLanguage", "en") == "zh"
    status_text = "已开启" if controller.appEnabled else "已关闭"
    if not is_chinese:
        status_text = "Enabled" if controller.appEnabled else "Disabled"
    tray.setToolTip(
        f"Comfort Cues\n{status_text}\n"
        + ("仅支持 16:9 窗口化/无边框\n单击图标可打开设置" if is_chinese else "16:9 windowed/borderless only\nClick the tray icon to open")
    )
    tray.enable_action.setText("开启" if is_chinese else "Enable")
    tray.disable_action.setText("关闭" if is_chinese else "Disable")
    for action in reversed(tray.contextMenu().actions()):
        if not action.isSeparator():
            action.setText("退出" if is_chinese else "Quit")
            break
    tray.enable_action.setEnabled(not controller.appEnabled)
    tray.disable_action.setEnabled(controller.appEnabled)
