# Project Structure

This document describes the maintained layout of the `ComfortCues` workspace after the repository cleanup.

## Top-Level Layout

- `native/`
  Primary application track. This is the canonical Qt/QML project and the main place for current product work.
- `src/comfort_cues/`
  Python reference implementation. It stays in the workspace for behavior comparison, packaging experiments, and test support.
- `tests/`
  Python-side regression tests for shared logic and reference-track behavior.
- `scripts/`
  PowerShell automation for build, deploy, smoke, manual runtime checks, and release steps.
- `profiles/`
  Default and sample profile data used by runtime flows and packaging.
- `docs/`
  User-facing and developer-facing documentation.
- `packaging/python/`
  Python packaging assets, including the PyInstaller spec file.
- `.vscode/`
  Workspace tasks that call the PowerShell build scripts.

## Native Track

The native track is the primary implementation path.

- Canonical project file: `native/ComfortCues.pro`
- C/C++ headers: `native/include/`
- C/C++ sources: `native/src/`
- Native tests or low-level checks: `native/tests/`
- Qt resource file: `native/resources.qrc`

Build and deployment automation are intentionally kept outside `native/` in `scripts/` so the project file stays focused on the application itself.

## Python Reference Track

The Python track is not the primary product direction, but it is still part of the maintained workspace.

- Python package root: `src/comfort_cues/`
- Entry point: `comfort_cues.main:main` from `pyproject.toml`
- Controller helper modules: `src/comfort_cues/controller/`
- QML shell and components: `src/comfort_cues/ui/qml/`
- Packaging spec: `packaging/python/ComfortCues.spec`
- Test suite: `tests/`

This track should not be treated as dead code unless the build, packaging, and test expectations are explicitly removed.

## UI Layout

The active QML UI is intentionally componentized:

- `src/comfort_cues/ui/qml/SettingsWindow.qml`
  Settings window shell and panel composition.
- `src/comfort_cues/ui/qml/OverlayWindow.qml`
  Transparent overlay shell and cue-band composition.
- `src/comfort_cues/ui/qml/components/`
  Focused QML panels, shared slider rows, metric rows, and edge cue bands.
- `src/comfort_cues/ui/qml/i18n/Strings.js`
  English/Chinese labels plus status and mode formatting.

Keep QML files focused. Do not fold translations, repeated slider markup, and panel layout back into the window shells.

## Controller Helper Layout

Python reference controller helpers live under `src/comfort_cues/controller/`:

- `status.py`: status-string parsing.
- `profile_binding.py`: bind-current-window profile creation helpers.
- `display.py`: flow speed, debug scaling, and disabled display defaults.
- `profile_templates.py`: profile template copying.

Native helper equivalents live under `native/include/` and `native/src/`:

- `status_text.*`
- `profile_binding.*`
- `display_state.*`

Keep Qt-facing controller properties and slots in `AppController`, but keep pure helper logic in these smaller files.

## Documentation Layout

- `README.md`
  Project overview, main commands, and current direction.
- `docs/native_manual_smoke.md`
  Manual GUI/runtime validation procedure.
- `docs/dev/README.md`
  Index for developer-facing continuity notes.
- `docs/dev/continuation-guide.md`
  Current working baseline, runtime notes, and next recommended work.
- `docs/dev/progress.md`
  Compact implementation progress log.

## Build And Runtime Outputs

The following paths are generated artifacts and should not be treated as long-lived source files:

- `build/`
- `dist/`
- `release/`
- `.pytest_cache/`
- `__pycache__/`

These are intentionally ignored by `.gitignore` and can be recreated from the documented scripts.

## Main Script Entry Points

- `scripts/check_native_toolchain.ps1`
  Validate whether the machine can build and deploy the native app.
- `scripts/build_native.ps1`
  Build the canonical native project into `build/native/<config>/`.
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

- Treat `native/ComfortCues.pro` as the only canonical native project entry.
- Keep root-level files minimal: overview docs, environment config, and package metadata only.
- Put developer handoff notes under `docs/dev/`, not in the repository root.
- Put packaging-specific files under `packaging/`, not in the repository root.
- Do not commit generated runtime directories or caches.
