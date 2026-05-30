# Native Manual Smoke

Use `scripts\manual_native_runtime.ps1` when you need to verify real tray and window lifecycle behavior without touching the user's roaming app data.

## Entry Point

```powershell
scripts\build_native.ps1 -Configuration Release
scripts\deploy_native.ps1 -Configuration Release
scripts\manual_native_runtime.ps1 -Configuration Release
scripts\summarize_manual_runtime.ps1 -Configuration Release
```

The script creates a disposable session under `build/native-manual/<config>/`, preloads the default profile templates, points the app at that isolated data root, and writes runtime progress to `manual-runtime.log`.
It now does this through a generated `launch-manual.cmd -> launch-manual.ps1 -> ComfortCues.exe` chain so the real GUI process receives the isolated environment variables and runtime `PATH` reliably.
If the app previously looked like it was not starting, the usual cause was that it either launched straight to tray from persisted state or the manual launcher guessed the wrong process by name.
An additional native crash in isolated profile template setup has also been fixed, so the launcher once again reaches a live visible GUI session instead of exiting during startup.
The manual smoke launcher now forces the settings window visible for the session, so you start from a visible UI instead of a hidden tray-only launch.
The settings window also includes a persisted `Language / 语言` switch, so manual smoke can now verify both English and Chinese copy in the same isolated session.
After you finish the manual pass and close the app, run `scripts\summarize_manual_runtime.ps1 -Configuration Release` to produce `manual-summary.json`.

## Checklist

1. Confirm the first launch opens the settings window.
2. Keep a game window visible, click `Choose Window`, select the game, then click `Bind selected`.
3. Toggle `Debug` and verify the overlay becomes visually obvious.
4. Click `Save` and confirm a profile file exists under `build/native-manual/<config>/data/profiles/`.
5. Close the settings window and reopen it from the tray icon.
6. Click `Disable`, then `Enable`, and confirm the UI state and tray tooltip update.

## Output Files

- `build/native-manual/<config>/manual-runtime.log`
- `build/native-manual/<config>/manual-runtime.pid`
- `build/native-manual/<config>/manual-summary.json`
- `build/native-manual/<config>/launch-manual.cmd`
- `build/native-manual/<config>/launch-manual.ps1`
- `build/native-manual/<config>/data/app-state.json`
- `build/native-manual/<config>/data/profiles/*.toml`
- `build/native-manual/<config>/README.txt`
