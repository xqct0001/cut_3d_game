# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-14

First public Windows x64 release of ComfortCues as a portable native runtime package.

### Added

- Native Qt/QML application track as the primary runtime and packaging target.
- Release packaging flow through `scripts/make_release.ps1`.
- Project structure documentation in `docs/project-structure.md`.
- Developer continuity notes under `docs/dev/`.

### Changed

- Promoted the native implementation to the primary development path while keeping the Python implementation as a reference track.
- Cleaned the repository layout so packaging files, handoff notes, and canonical native project entry are in stable locations.
- Updated build and deployment scripts to use `native/ComfortCues.pro` as the single canonical native project file.
- Updated release packaging to publish a portable `dist/native` runtime zip instead of relying on an old `dist/ComfortCues.exe` layout.

### Validation

- `uv run pytest`
- `scripts\build_native.ps1 -Configuration Release`
- `scripts\deploy_native.ps1 -Configuration Release`
- `scripts\smoke_native_runtime.ps1 -Configuration Release`

### Notes

- This release is not a true single-executable build.
- A static Qt SDK is still required for single-exe packaging.
- Runtime state is stored under `%APPDATA%\Comfort Cues\`.
