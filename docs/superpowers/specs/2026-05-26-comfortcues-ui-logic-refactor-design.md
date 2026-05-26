# Comfort Cues UI And Logic Refactor Design

## Goal

Rebuild the Comfort Cues settings UI and runtime-facing logic into small, testable units while preserving the current app until replacements are loaded, verified, and wired into both the Python reference track and the native Qt/QML track.

## Current Facts

- The native Qt/QML app is the primary product track.
- The Python implementation remains a maintained reference track and still owns the pytest/QML regression surface.
- `src/comfort_cues/ui/qml/SettingsWindow.qml` is a large mixed layout, translation, state-formatting, and control file.
- `src/comfort_cues/ui/qml/OverlayWindow.qml` is a single overlay renderer with repeated edge-band math.
- `src/comfort_cues/app.py` and `native/src/app_controller.cpp` each combine controller, profile editing, tray, runtime ticking, debug display, and QML view-model responsibilities.
- The baseline Python/QML suite passes with `.venv\Scripts\python.exe -m pytest`.
- `uv run pytest` currently fails before running tests with `Failed to canonicalize script path`; keep using the direct Python command until that toolchain issue is separately fixed.

## Research Constraints For Display Effects

The overlay should calm and orient, not pull attention into the periphery.

- A 2023 cybersickness study reported that restricting attention toward the central visual field can reduce symptoms, while peripheral attention worsened sickness in a passive exposure experiment: https://link.springer.com/article/10.1186/s41235-023-00466-1
- A 2024 preregistered virtual-nose study did not find a reliable general benefit, so fixed decorative anchors should not be treated as a guaranteed mitigation: https://link.springer.com/article/10.1186/s41235-024-00593-3
- Accepted IEEE VR 2025 peripheral rest-frame work suggests stable peripheral references can help when they match physical motion, but this desktop overlay cannot observe head motion and should stay conservative: https://arxiv.org/abs/2502.15227

Design implication: keep edge cues low contrast, stable, and sparse by default; use stronger visual output only in explicit calibration/debug mode.

## Product Direction

The new UI should feel like a quiet desktop utility for repeated use during gaming sessions:

- first screen answers status, selected window, profile, and primary actions;
- controls are grouped by job rather than by implementation details;
- advanced and simulator controls are available without dominating normal use;
- Chinese and English strings are valid UTF-8 and centralized;
- no visible in-app explanatory design text, no marketing hero, no card-heavy dashboard.

## Architecture

### QML

Replace the monolithic settings window with a small shell and focused components:

- `SettingsWindow.qml`: window shell, scroll layout, imports, shared sizing.
- `components/StatusHeader.qml`: app title, language switch, enabled state.
- `components/SessionPanel.qml`: current state, window summary, bind/debug/enable actions.
- `components/ComfortControls.qml`: cue strength, turn sensitivity, vertical sensitivity.
- `components/ProfilePanel.qml`: profile selection, reload, save, active profile summary.
- `components/AdvancedPanel.qml`: mouse/gamepad/safe mode, cue style, visibility, fades.
- `components/SimulatorPanel.qml`: simulator enable/reset and yaw/pitch/lateral controls.
- `components/MetricRow.qml`: compact two-column label/value row.
- `components/LabeledSlider.qml`: reusable slider row with value label.
- `i18n/Strings.js`: translation table and status/mode formatting helpers.

Replace the overlay renderer with reusable edge-band components:

- `OverlayWindow.qml`: window shell, shared overlay properties, three edge bands.
- `components/EdgeCueBand.qml`: repeated dot renderer for top/left/right bands.

The QML replacement keeps existing controller property names and slot names so Python and native controllers remain compatible during the swap.

### Python Reference Logic

Keep the reference track, but split controller responsibilities:

- `controller/status.py`: status text parsing and derived view labels.
- `controller/profile_binding.py`: bind-current-window profile creation helpers.
- `controller/display.py`: flow speed, debug alpha/density scaling, disabled display reset values.
- `controller/profile_templates.py`: profile template copy behavior.

`app.py` remains the QML-facing `AppController`, but delegates helper logic to the new modules.

### Native Logic

Mirror the same boundaries where the native controller currently has duplicated helpers:

- `native/include/status_text.h` and `native/src/status_text.cpp`
- `native/include/profile_binding.h` and `native/src/profile_binding.cpp`
- `native/include/display_state.h` and `native/src/display_state.cpp`

The native controller keeps Qt properties and slots stable, but string parsing, binding profile creation, tray text formatting, and display reset/debug scaling move out.

### Safe Deletion

No old source file is deleted until its replacement is imported by the runtime and covered by tests or build checks.

Delete only after replacement:

- inline translation/status helper blocks inside `SettingsWindow.qml`;
- duplicated QML slider/metric markup replaced by reusable components;
- Python controller helper functions moved into new modules;
- native anonymous-namespace helper functions moved into new C++ modules;
- mojibake Chinese tray/status strings once UTF-8 strings are centralized.

Do not delete the Python reference package, `packaging/python/ComfortCues.spec`, or Python tests in this refactor; they are still the regression harness and fallback track.

## Verification

Minimum gates:

- `.venv\Scripts\python.exe -m pytest`
- `scripts\check_native_toolchain.ps1`
- `scripts\build_native.ps1 -Configuration Release`
- `scripts\deploy_native.ps1 -Configuration Release`
- `scripts\smoke_native_runtime.ps1 -Configuration Release`
- git diff review for removed stale references

Manual smoke target:

- settings window opens;
- language toggles between English and Chinese without mojibake;
- enable/disable and tray actions work;
- bind current window status remains clear;
- simulator sliders move overlay cues;
- debug/calibration mode remains visibly stronger than default mode.

