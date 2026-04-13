# -*- mode: python ; coding: utf-8 -*-

import os
from pathlib import Path


project_root = Path(SPECPATH).resolve().parents[1]
src_root = project_root / "src"
mode = os.environ.get("CC_BUILD_MODE", "single").strip().lower()
app_name = os.environ.get("CC_APP_NAME", "ComfortCues-Portable").strip() or "ComfortCues-Portable"
onefile = mode == "single"
icon_path = project_root / "src" / "comfort_cues" / "ui" / "assets" / "comfort-cues.ico"
app_icon = str(icon_path) if icon_path.exists() else None

datas = [
    (str(src_root / "comfort_cues" / "ui" / "qml"), "src/comfort_cues/ui/qml"),
    (str(src_root / "comfort_cues" / "ui" / "assets"), "src/comfort_cues/ui/assets"),
    (str(project_root / "profiles" / "default.toml"), "profiles"),
    (str(project_root / "profiles" / "sample-third-person.toml"), "profiles"),
]

excluded_modules = [
    "PySide6.QtCharts",
    "PySide6.QtQuick3D",
    "PySide6.QtQuick3DAssetImport",
    "PySide6.QtQuick3DPhysics",
    "PySide6.QtQuick3DRender",
    "PySide6.QtQuick3DRuntimeRender",
    "PySide6.QtQuick3DUtils",
    "PySide6.QtSensors",
    "PySide6.QtTest",
    "PySide6.QtWebChannel",
    "PySide6.QtWebEngineCore",
    "PySide6.QtWebEngineQuick",
    "PySide6.QtWebEngineWidgets",
    "PySide6.QtWebSockets",
]

a = Analysis(
    [str(src_root / "comfort_cues" / "main.py")],
    pathex=[str(src_root)],
    binaries=[],
    datas=datas,
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=excluded_modules,
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

if onefile:
    exe = EXE(
        pyz,
        a.scripts,
        a.binaries,
        a.datas,
        [],
        name=app_name,
        debug=False,
        bootloader_ignore_signals=False,
        strip=False,
        upx=False,
        upx_exclude=[],
        runtime_tmpdir=None,
        console=False,
        icon=app_icon,
        disable_windowed_traceback=False,
        argv_emulation=False,
        target_arch=None,
        codesign_identity=None,
        entitlements_file=None,
    )
else:
    exe = EXE(
        pyz,
        a.scripts,
        [],
        exclude_binaries=True,
        name=app_name,
        debug=False,
        bootloader_ignore_signals=False,
        strip=False,
        upx=False,
        upx_exclude=[],
        runtime_tmpdir=None,
        console=False,
        icon=app_icon,
        disable_windowed_traceback=False,
        argv_emulation=False,
        target_arch=None,
        codesign_identity=None,
        entitlements_file=None,
    )
    coll = COLLECT(
        exe,
        a.binaries,
        a.datas,
        strip=False,
        upx=False,
        upx_exclude=[],
        name=app_name,
    )

