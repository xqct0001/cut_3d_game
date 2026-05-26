# Comfort Cues UI And Logic Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Comfort Cues Qt/QML UI and split the controller/runtime-facing logic into small modules, then remove replaced old code safely.

**Architecture:** Preserve the current controller property/slot contract while replacing monolithic QML with focused components. Split Python and native controller helpers along the same status, profile-binding, and display-state boundaries so source files stay small and old inline helper code can be deleted only after replacements are active.

**Tech Stack:** Python 3.12, PySide6/QML, Qt native C++17/QML, pytest, qmake build scripts.

---

## File Structure

- Create `src/comfort_cues/controller/status.py`: pure Python status/mode formatting and exe-name extraction.
- Create `src/comfort_cues/controller/profile_binding.py`: pure Python profile-name and binding-profile helpers.
- Create `src/comfort_cues/controller/display.py`: pure Python flow-speed, disabled-view defaults, and debug cue scaling.
- Create `src/comfort_cues/controller/profile_templates.py`: pure Python profile template copy helper.
- Modify `src/comfort_cues/app.py`: keep `AppController`, delegate helpers to new modules, remove obsolete inline helpers after tests pass.
- Create `src/comfort_cues/ui/qml/i18n/Strings.js`: QML translation/status/mode functions with valid English and Chinese strings.
- Create QML components under `src/comfort_cues/ui/qml/components/`.
- Modify `src/comfort_cues/ui/qml/SettingsWindow.qml`: shell only, imports components and `Strings.js`.
- Modify `src/comfort_cues/ui/qml/OverlayWindow.qml`: shell plus `EdgeCueBand` components.
- Modify `native/resources.qrc`: include new QML component and JS files.
- Create `native/include/status_text.h` and `native/src/status_text.cpp`.
- Create `native/include/profile_binding.h` and `native/src/profile_binding.cpp`.
- Create `native/include/display_state.h` and `native/src/display_state.cpp`.
- Modify `native/include/app_controller.h`, `native/src/app_controller.cpp`, `native/ComfortCues.pro`.
- Modify `tests/test_app_controller.py` and `tests/test_qml_runtime.py`; add shared fixtures where useful.
- Update docs after code and verification.

## Task 1: Python Controller Helper Split

**Files:**
- Create: `src/comfort_cues/controller/__init__.py`
- Create: `src/comfort_cues/controller/status.py`
- Create: `src/comfort_cues/controller/profile_binding.py`
- Create: `src/comfort_cues/controller/display.py`
- Create: `src/comfort_cues/controller/profile_templates.py`
- Modify: `src/comfort_cues/app.py`
- Test: `tests/test_app_controller.py`

- [ ] **Step 1: Add failing tests for extracted helpers**

Add tests that import `extract_exe_name`, `profile_name_for_window`, `binding_profile_for_window`, `flow_speed`, `DisabledDisplayState`, and `apply_debug_visibility`.

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest tests\test_app_controller.py -q
```

Expected: import failures because the new modules do not exist.

- [ ] **Step 2: Add minimal helper modules**

Move only the existing pure helper behavior out of `app.py`. Keep function names close to existing private helpers, but expose public module functions:

```python
def extract_exe_name(status_text: str) -> str: ...
def profile_name_for_window(window) -> str: ...
def binding_profile_for_window(selected_profile, window): ...
def flow_speed(pattern: str, cue_energy: float) -> float: ...
```

- [ ] **Step 3: Rewire `AppController`**

Import the new helpers in `app.py`, delete the replaced private helper functions only after tests pass against the helper modules, and keep the Qt property/slot API unchanged.

- [ ] **Step 4: Verify**

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest tests\test_app_controller.py tests\test_runtime.py -q
```

Expected: all selected tests pass.

## Task 2: QML Settings UI Rebuild

**Files:**
- Create: `src/comfort_cues/ui/qml/i18n/Strings.js`
- Create: `src/comfort_cues/ui/qml/components/StatusHeader.qml`
- Create: `src/comfort_cues/ui/qml/components/SessionPanel.qml`
- Create: `src/comfort_cues/ui/qml/components/ComfortControls.qml`
- Create: `src/comfort_cues/ui/qml/components/ProfilePanel.qml`
- Create: `src/comfort_cues/ui/qml/components/AdvancedPanel.qml`
- Create: `src/comfort_cues/ui/qml/components/SimulatorPanel.qml`
- Create: `src/comfort_cues/ui/qml/components/MetricRow.qml`
- Create: `src/comfort_cues/ui/qml/components/LabeledSlider.qml`
- Modify: `src/comfort_cues/ui/qml/SettingsWindow.qml`
- Modify: `native/resources.qrc`
- Test: `tests/test_qml_runtime.py`

- [ ] **Step 1: Add failing QML structure tests**

Update `tests/test_qml_runtime.py` to require the new component object names:

```python
assert settings.findChild(QtCore.QObject, "statusHeader") is not None
assert settings.findChild(QtCore.QObject, "sessionPanel") is not None
assert settings.findChild(QtCore.QObject, "comfortControls") is not None
assert settings.findChild(QtCore.QObject, "profilePanel") is not None
assert settings.findChild(QtCore.QObject, "advancedPanel") is not None
assert settings.findChild(QtCore.QObject, "simulatorPanel") is not None
```

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest tests\test_qml_runtime.py::test_create_engine_loads_overlay_and_settings_windows -q
```

Expected: fails because new components do not exist.

- [ ] **Step 2: Add `Strings.js`**

Centralize `tr`, `translateStatus`, `modeSummary`, `sessionTitle`, `sessionColorKey`, `windowSummary`, and `formatNumber`. Use valid UTF-8 Chinese strings.

- [ ] **Step 3: Add small components**

Each component receives `property var controller` and `property var strings` where needed. Keep existing object names for tested controls: `languageCombo`, `quickStartCard`, `windowSummaryLabel`, `enableButton`, `disableButton`, `bindWindowButton`, `debugButton`, `reloadButton`, `saveButton`, `advancedToggle`, `advancedDetails`.

- [ ] **Step 4: Replace `SettingsWindow.qml` shell**

Replace inline translation/layout blocks with imports:

```qml
import "components"
import "i18n/Strings.js" as Strings
```

The shell owns palette, scroll view, and component composition only.

- [ ] **Step 5: Verify**

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest tests\test_qml_runtime.py tests\test_app_controller.py -q
```

Expected: all selected tests pass.

## Task 3: Overlay Renderer Rebuild

**Files:**
- Create: `src/comfort_cues/ui/qml/components/EdgeCueBand.qml`
- Modify: `src/comfort_cues/ui/qml/OverlayWindow.qml`
- Modify: `native/resources.qrc`
- Test: `tests/test_qml_runtime.py`

- [ ] **Step 1: Add failing overlay component test**

Assert the overlay has `topCueBand`, `leftCueBand`, and `rightCueBand` children, and that idle ambient alpha stays low but nonzero.

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest tests\test_qml_runtime.py::test_overlay_keeps_ambient_points_visible_when_idle -q
```

Expected: fails because bands do not yet expose the new object names.

- [ ] **Step 2: Add `EdgeCueBand.qml`**

Move repeated Repeater dot rendering into one reusable component with orientation, drive, density, accent alpha, ambient alpha, and motion properties.

- [ ] **Step 3: Rebuild `OverlayWindow.qml`**

Keep the public calculated properties used by tests: `leftAmbientAlpha`, `rightAmbientAlpha`, `topAmbientAlpha`, `leftAccentAlpha`, `rightAccentAlpha`, `topAccentAlpha`. Lower default ambient visual weight, keep debug mode stronger.

- [ ] **Step 4: Verify**

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest tests\test_qml_runtime.py -q
```

Expected: all QML tests pass.

## Task 4: Native Controller Helper Split

**Files:**
- Create: `native/include/status_text.h`
- Create: `native/src/status_text.cpp`
- Create: `native/include/profile_binding.h`
- Create: `native/src/profile_binding.cpp`
- Create: `native/include/display_state.h`
- Create: `native/src/display_state.cpp`
- Modify: `native/include/app_controller.h`
- Modify: `native/src/app_controller.cpp`
- Modify: `native/ComfortCues.pro`

- [ ] **Step 1: Move status helpers**

Move `extractExeName` and language/tray label helpers into `status_text.*`.

- [ ] **Step 2: Move profile binding helpers**

Move `appendUnique`, `profileNameForWindow`, and `bindingProfileForWindow` into `profile_binding.*`.

- [ ] **Step 3: Move display helpers**

Move disabled display defaults and debug cue scaling into `display_state.*` with functions that mutate a small plain struct or controller-owned fields through explicit parameters.

- [ ] **Step 4: Rewire build files**

Add headers and sources to `native/ComfortCues.pro`.

- [ ] **Step 5: Verify native build**

Run:

```powershell
scripts\check_native_toolchain.ps1
scripts\build_native.ps1 -Configuration Release
```

Expected: toolchain available and native release build succeeds. If toolchain is unavailable, record exact failure and keep Python/QML verification as the completed gate.

## Task 5: Remove Replaced Old Code And Update Docs

**Files:**
- Modify: `README.md`
- Modify: `docs/project-structure.md`
- Modify: `docs/dev/continuation-guide.md`
- Modify: `native/resources.qrc`
- Modify: any source files still carrying unused replaced helpers

- [ ] **Step 1: Search for stale old references**

Run:

```powershell
rg "exitButton|涓|闈|璇|TODO|old|legacy" src native tests docs README.md
```

Expected: only intentional mentions remain.

- [ ] **Step 2: Delete dead inline helper blocks**

Remove obsolete inline translation tables, duplicated slider rows, and private helper functions that are now imported from new modules.

- [ ] **Step 3: Update docs**

Document the new UI component layout and controller helper boundaries.

- [ ] **Step 4: Final verification**

Run:

```powershell
$env:QT_QPA_PLATFORM='offscreen'; .\.venv\Scripts\python.exe -m pytest
scripts\build_native.ps1 -Configuration Release
scripts\deploy_native.ps1 -Configuration Release
scripts\smoke_native_runtime.ps1 -Configuration Release
git status --short
```

Expected: tests pass, native gates pass or exact environment blocker is recorded, and git status contains only intentional changes.

## Task 6: Git Upload

**Files:**
- All modified source/docs/tests.

- [ ] **Step 1: Review diff**

Run:

```powershell
git diff --stat
git diff -- src native tests docs README.md native/ComfortCues.pro native/resources.qrc
```

Expected: no unrelated generated files, no premature deletion of maintained Python reference track.

- [ ] **Step 2: Commit**

Run:

```powershell
git add src native tests docs README.md
git commit -m "refactor comfort cues ui and controller logic"
```

- [ ] **Step 3: Push**

Run:

```powershell
git push -u origin codex/comfortcues-refactor-ui-logic
```

Expected: branch pushed to origin.

