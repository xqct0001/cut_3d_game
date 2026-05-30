# Project Structure

This document describes the maintained native-only layout of the Comfort Cues workspace.

## Top-Level Layout

- `native/`
  Canonical Qt/QML application project.
- `src/comfort_cues/ui/qml/`
  QML settings window, overlay window, components, and UI strings loaded by `native/resources.qrc`.
- `src/comfort_cues/ui/assets/`
  Icons and image assets used by the native application.
- `profiles/`
  Default and sample profile data used by runtime flows and deployment.
- `scripts/`
  PowerShell automation for toolchain checks, build, deploy, smoke, manual runtime checks, and release packaging.
- `docs/`
  Runtime guides and developer notes.
- `.vscode/`
  Workspace tasks that call the PowerShell build scripts.

## Native Track

The native track is the only maintained implementation path.

- Project file: `native/ComfortCues.pro`
- C/C++ headers: `native/include/`
- C/C++ sources: `native/src/`
- Native low-level tests: `native/tests/`
- Qt resource file: `native/resources.qrc`

Build and deployment automation stays in `scripts/` so the project file remains focused on the application.

## UI Layout

- `src/comfort_cues/ui/qml/SettingsWindow.qml`
  Settings window shell and panel composition.
- `src/comfort_cues/ui/qml/OverlayWindow.qml`
  Transparent overlay shell and cue-band composition.
- `src/comfort_cues/ui/qml/components/`
  Focused QML panels, shared slider rows, metric rows, and edge cue bands.
- `src/comfort_cues/ui/qml/i18n/Strings.js`
  English/Chinese labels plus status and mode formatting.

Keep QML files focused. Do not fold translations, repeated slider markup, and panel layout back into the window shells.

## Native Helper Layout

Qt-facing controller properties and slots live in `AppController`. Pure helper logic lives in smaller native files:

- `status_text.*`
- `profile_binding.*`
- `display_state.*`
- `profile_store.*`
- `runtime_service.*`
- `window_tracker.*`
- `input_source.*`

## Build And Runtime Outputs

The following paths are generated artifacts and should not be treated as source files:

- `build/`
- `dist/`
- `release/`

They are ignored by `.gitignore` and can be recreated from the documented scripts.

## Main Script Entry Points

- `scripts/check_native_toolchain.ps1`
  Validate whether the machine can build and deploy the native app.
- `scripts/build_native.ps1`
  Build the native project into `build/native/<config>/`.
- `scripts/deploy_native.ps1`
  Produce a runnable native directory under `dist/native/`.
- `scripts/smoke_native_runtime.ps1`
  Run isolated state-focused smoke checks on the deployed native app.
- `scripts/manual_native_runtime.ps1`
  Launch an isolated visible GUI session for manual verification.
- `scripts/summarize_manual_runtime.ps1`
  Summarize the manual runtime session outputs.
- `scripts/make_release.ps1`
  Package the deployed native runtime into a publishable portable zip under `release/`.
- `scripts/build_single_exe.ps1`
  Build a true single executable only when a static Qt SDK is available.

## Maintenance Rules

- Treat `native/ComfortCues.pro` as the only canonical project entry.
- Keep root-level files minimal: overview docs, tool config, and release notes only.
- Do not commit generated runtime directories or caches.
- Keep `src/comfort_cues/ui/qml/` and `src/comfort_cues/ui/assets/`; the native app depends on them.
