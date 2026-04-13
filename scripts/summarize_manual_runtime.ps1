param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$SessionRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$sessionRoot = if ([string]::IsNullOrWhiteSpace($SessionRoot)) {
    Join-Path $root "build\native-manual\$($Configuration.ToLower())"
} else {
    $SessionRoot
}

$dataRoot = Join-Path $sessionRoot "data"
$profilesRoot = Join-Path $dataRoot "profiles"
$statePath = Join-Path $dataRoot "app-state.json"
$progressPath = Join-Path $sessionRoot "manual-runtime.log"
$summaryPath = Join-Path $sessionRoot "manual-summary.json"

$logLines = @()
if (Test-Path -LiteralPath $progressPath) {
    $logLines = Get-Content -LiteralPath $progressPath
}

$appState = $null
if (Test-Path -LiteralPath $statePath) {
    $appState = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
}

$profileFiles = @()
if (Test-Path -LiteralPath $profilesRoot) {
    $profileFiles = Get-ChildItem -LiteralPath $profilesRoot -Filter *.toml -File | Select-Object -ExpandProperty Name
}

function Test-Log {
    param([string]$Pattern)

    return [bool]($logLines | Where-Object { $_ -like "*$Pattern*" } | Select-Object -First 1)
}

$summary = [ordered]@{
    session_root = $sessionRoot
    data_root = $dataRoot
    progress_log = $progressPath
    app_state_path = $statePath
    profile_files = $profileFiles
    checks = [ordered]@{
        first_launch_opened_settings = (Test-Log -Pattern "settings window opened") -or (Test-Log -Pattern "settings window visible=true")
        first_run_persisted = (Test-Log -Pattern "completed first-run persistence") -or (($null -ne $appState) -and [bool]$appState.launch_to_tray)
        tray_reopen_observed = Test-Log -Pattern "tray icon activated"
        bind_attempted = (Test-Log -Pattern "bind succeeded") -or (Test-Log -Pattern "bind failed")
        bind_succeeded = Test-Log -Pattern "bind succeeded"
        debug_toggle_observed = Test-Log -Pattern "debug overlay=true"
        profile_saved = Test-Log -Pattern "profile saved"
        disable_observed = Test-Log -Pattern "app disabled"
        enable_observed = Test-Log -Pattern "app enabled"
        quit_requested = Test-Log -Pattern "quit requested"
    }
    launch_to_tray = if ($null -ne $appState) { [bool]$appState.launch_to_tray } else { $null }
    app_enabled = if ($null -ne $appState) { [bool]$appState.app_enabled } else { $null }
}

$missing = @()
foreach ($pair in $summary.checks.GetEnumerator()) {
    if (-not [bool]$pair.Value) {
        $missing += $pair.Key
    }
}
$summary["missing_checks"] = $missing

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding ASCII

Write-Output "MANUAL_SUMMARY=$summaryPath"
Write-Output "MANUAL_MISSING_COUNT=$($missing.Count)"
