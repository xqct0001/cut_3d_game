# Comfort Cues Continuation Guide
Updated: 2026-04-14

## Workspace

Use this workspace for all ongoing work:
`C:\Users\qiyue\Desktop\ComfortCues`

## Current State

The repository currently has two working tracks:

- Python reference implementation under `src/comfort_cues/` and `tests/`
- Native Qt/QML implementation under `native/include/`, `native/src/`, and `native/ComfortCues.pro`

The native app is the primary development track and can be built and deployed as a runnable directory. It is still not a true single-file executable because the available Qt toolchain is a shared build.
The deployed runtime directory now depends less on external machine PATH state because `deploy_native.ps1` writes `qt.conf` and copies the extra Conda/MSVC DLLs required by direct `dist/native/ComfortCues.exe` launches.

## Primary Commands

```powershell
scripts\check_native_toolchain.ps1
scripts\build_native.ps1 -Configuration Release
scripts\deploy_native.ps1 -Configuration Release
scripts\smoke_native_runtime.ps1 -Configuration Release
scripts\manual_native_runtime.ps1 -Configuration Release
scripts\summarize_manual_runtime.ps1 -Configuration Release
uv run pytest
```

## Regression Baseline

These commands are the current baseline and should keep passing:

- `scripts\build_native.ps1 -Configuration Release`
- `scripts\deploy_native.ps1 -Configuration Release`
- `scripts\smoke_native_runtime.ps1 -Configuration Release`
- `uv run pytest`
- direct launch of `dist/native/ComfortCues.exe`

The automated smoke run remains `state-only`. It validates isolated `app-state.json` persistence, profile save behavior, and enable/disable roundtrips. QML and window loading checks stay under `uv run pytest`.

## Manual Runtime Chain

The manual runtime path is now:

`manual_native_runtime.ps1 -> launch-manual.cmd -> launch-manual.ps1 -> ComfortCues.exe`

Current behavior and boundaries:

- manual smoke uses an isolated session under `build/native-manual/<config>/`
- manual smoke forces the settings window visible through `CC_FORCE_SHOW_SETTINGS=1`
- normal deployed runs still respect the persisted `launch_to_tray` state
- UI language is now persisted as `ui_language` and can be switched between `en` and `zh`
- Settings UI strings now live in `src/comfort_cues/ui/qml/i18n/Strings.js` and should stay valid UTF-8.
- Settings and overlay QML are split into focused components under `src/comfort_cues/ui/qml/components/`.
- Python controller helper logic lives under `src/comfort_cues/controller/`; native helper equivalents live in `native/include/status_text.h`, `native/include/profile_binding.h`, and `native/include/display_state.h`.
- manual smoke must produce `manual-runtime.log`, `manual-runtime.pid`, and `data/app-state.json`
- manual smoke results are summarized through `scripts\summarize_manual_runtime.ps1`

## Root Cause Addressed

The earlier manual launcher had two reliability issues:

- it relied on implicit environment inheritance for the isolated `CC_*` variables
- it guessed the launched process by polling `Get-Process ComfortCues`, which could return the wrong instance
- isolated manual sessions also exposed an early native crash during profile template setup

The current launcher addresses that by:

- generating a disposable `launch-manual.cmd`
- delegating the actual GUI start to `launch-manual.ps1`
- starting `ComfortCues.exe` through an explicit process configuration with the required runtime `PATH`
- capturing the exact child pid
- refusing to report success until app-owned progress lines and the isolated `app-state.json` appear
- using a safer profile template initialization path that no longer crashes during isolated GUI startup

## Output Locations

- Build output: `build/native/release/ComfortCues.exe`
- Deployed runtime directory: `dist/native/`
- State-only smoke artifacts: `build/native-smoke/<config>/`
- Manual smoke artifacts: `build/native-manual/<config>/`

## Next Recommended Work

1. Run the manual runtime checklist with a real visible session.
2. Confirm `Bind Window`, `Debug`, `Save`, tray reopen, `Disable`, and `Enable`.
3. Run `scripts\summarize_manual_runtime.ps1 -Configuration Release` and inspect `manual-summary.json`.
4. After runtime behavior is stable, return to UI refinement or true single-exe prerequisites.

## Constraints

- Do not restore any old self-extracting `single exe` packaging path.
- Treat the shared Qt deployment as `exe + runtime directory`, not a true single-file release.
- Keep documentation updated whenever runtime behavior or scripts change.
