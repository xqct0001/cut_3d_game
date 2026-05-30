# Comfort Cues

`Comfort Cues` is a Windows desktop comfort overlay for 3D games. It is designed as an accessibility-style companion app:

- no DLL injection
- no hooks into the game render pipeline
- no game memory reads or writes
- no synthetic input or gameplay automation

The first version targets visible first/third-person game windows. It uses system-level input only and draws a light edge cue overlay through the desktop compositor.

## Project Layout

- `native/`: primary Qt/QML application and canonical project file `native/ComfortCues.pro`
- `src/comfort_cues/ui/qml/`: QML settings and overlay UI loaded by the native app
- `src/comfort_cues/ui/assets/`: icons and image assets used by the native app
- `scripts/`: build, deploy, smoke, and release automation
- `docs/`: runtime guides plus developer handoff notes under `docs/dev/`

For current developer-facing handoff notes, use `docs/dev/README.md`.
For a fuller directory-by-directory breakdown, use `docs/project-structure.md`.
For productization and user-facing release work, use:

- `docs/commercialization-plan.md`
- `docs/profile-schema.md`
- `docs/troubleshooting.md`

## Native Build

```powershell
scripts\check_native_toolchain.ps1
scripts\build_native.ps1 -Configuration Release
scripts\deploy_native.ps1 -Configuration Release
scripts\smoke_native_runtime.ps1 -Configuration Release
scripts\manual_native_runtime.ps1 -Configuration Release
scripts\summarize_manual_runtime.ps1 -Configuration Release
scripts\make_release.ps1
```

`build_native.ps1` + `deploy_native.ps1` are the development/runtime path. They produce a runnable directory, not a true single-file release.
The deploy script now also writes `qt.conf` and copies extra Conda/MSVC runtime DLLs such as `zstd.dll`, `libcrypto-3-x64.dll`, `libssl-3-x64.dll`, and `Qt5QmlWorkerScript_conda.dll` so `dist/native/ComfortCues.exe` can run directly without relying on the shell's PATH.
`smoke_native_runtime.ps1` runs the deployed native executable twice in an isolated data directory and checks first-run state persistence, profile save, and enable/disable persistence without touching the user's real app data.
The smoke run is intentionally headless and state-only: it writes per-run progress logs under `build/native-smoke/<config>/` and validates first-run state persistence plus common controller actions.
`manual_native_runtime.ps1` now creates a disposable `launch-manual.cmd` and `launch-manual.ps1` under `build/native-manual/<config>/`.
The command file seeds the isolated `CC_*` variables, and the PowerShell launcher starts the deployed GUI with an explicit runtime `PATH`, captures the exact child pid, and waits until `manual-runtime.log` and `data/app-state.json` appear in the isolated session.
This fixes the earlier failure mode where the manual smoke launcher guessed the pid by process name and the GUI process could still behave like a tray-only launch from non-isolated state.
The manual smoke path now forces the settings window visible for the session while leaving the normal deployed app behavior unchanged.
The manual runtime path is now verified against a real GUI launch again after fixing an early native crash in profile template setup during isolated sessions.
The settings UI and tray copy now support a persisted Chinese/English toggle through `ui_language` in `app-state.json`.
`summarize_manual_runtime.ps1` turns that manual session into `manual-summary.json` so you can see which checklist items were actually observed.
`make_release.ps1` packages the deployed `dist/native/` runtime into `release/ComfortCues-<version>-windows-x64.zip` and writes SHA-256 checksums for publication.

## True Single EXE

```powershell
$env:CC_STATIC_QT_ROOT = 'C:\Qt\5.15.2-static-msvc2019_64'
scripts\build_single_exe.ps1 -Configuration Release
```

A real single-file `ComfortCues.exe` requires a static Qt SDK. The current fallback Conda/MSVC toolchain in this repository is a shared Qt build and cannot produce a true single-file executable without extra DLLs or an extraction wrapper.

Game detection scans visible top-level windows and no longer rejects fullscreen or non-16:9 windows during binding.

The native build expects a Qt 6 MinGW toolchain on `PATH`, including `qmake`, `mingw32-make`, and a deploy tool exposed as `windeployqt`, `windeployqt6`, or `windeployqt-qt6`.
Run `scripts\check_native_toolchain.ps1` first if the machine has multiple Qt or MinGW installs.

## UI And Controller Layout

The QML UI is split by responsibility under `src/comfort_cues/ui/qml/`:

- `SettingsWindow.qml` composes small settings panels.
- `OverlayWindow.qml` composes edge cue bands.
- `components/` contains reusable settings and overlay pieces.
- `i18n/Strings.js` contains English/Chinese UI strings and status formatting.

The native controller keeps pure helper behavior in `native/include/*` and `native/src/*` helper files for status text, profile binding, and display cue scaling.

## VSCode Tasks

Open the workspace in VSCode and run:

- `Check Native Toolchain`
- `Build Native Debug`
- `Build Native Release`
- `Deploy Native Release`
- `Build True Single EXE`

These tasks call the PowerShell scripts under `scripts/` and assume the native Qt project file is available in the repository.

The canonical native project entry is `native/ComfortCues.pro`.

## CS2 Quick Start

1. Build and deploy the native app.
2. Launch Counter-Strike 2 and keep its window visible.
3. Alt-Tab back to the app, click `Choose Window`, select the game from the list, then click `Bind selected`.
4. Enable `Debug / Calibration` so the edge cue becomes obvious.
5. Go back to CS2 and move the camera left and right to confirm the overlay is active.
6. Turn off `Debug / Calibration` once confirmed and use the lighter cue for actual play.

## Verification

```powershell
scripts\build_native.ps1 -Configuration Release
scripts\deploy_native.ps1 -Configuration Release
scripts\smoke_native_runtime.ps1 -Configuration Release
scripts\manual_native_runtime.ps1 -Configuration Release
```

For real tray and window lifecycle validation, use `docs/native_manual_smoke.md`.
