param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$DeployRoot,

    [string]$ExePath,

    [string]$SmokeRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$defaultDeployRoot = Join-Path $root "dist\native"
$deployRoot = if ([string]::IsNullOrWhiteSpace($DeployRoot)) { $defaultDeployRoot } else { $DeployRoot }
$resolvedExePath = if ([string]::IsNullOrWhiteSpace($ExePath)) {
    Join-Path $deployRoot "ComfortCues.exe"
} else {
    $ExePath
}
$smokeRoot = if ([string]::IsNullOrWhiteSpace($SmokeRoot)) {
    Join-Path $root "build\native-smoke\$($Configuration.ToLower())"
} else {
    $SmokeRoot
}

function Remove-PathSafe {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Copy-FileIfExists {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    $parent = Split-Path -Parent $Destination
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Restore-EnvVar {
    param(
        [string]$Name,
        [string]$PreviousValue
    )

    if ($null -eq $PreviousValue) {
        Remove-Item "Env:$Name" -ErrorAction SilentlyContinue
    }
    else {
        Set-Item "Env:$Name" -Value $PreviousValue
    }
}

function Invoke-SmokeRun {
    param(
        [string]$Name,
        [string]$ExecutablePath,
        [string]$DataRoot,
        [string]$AppStatePath,
        [string]$ReportPath,
        [string]$ProgressPath
    )

    $trackedEnv = @(
        "CC_DATA_ROOT",
        "CC_APP_STATE_PATH",
        "CC_SMOKE_TEST_OUTPUT",
        "CC_SMOKE_PROGRESS_PATH",
        "PATH",
        "QML2_IMPORT_PATH",
        "QT_PLUGIN_PATH",
        "QT_QPA_PLATFORM",
        "QT_QUICK_BACKEND"
    )
    $previous = @{}
    foreach ($envName in $trackedEnv) {
        $item = Get-Item "Env:$envName" -ErrorAction SilentlyContinue
        $previous[$envName] = if ($null -ne $item) { $item.Value } else { $null }
    }

    try {
        $runtimePathEntries = @(
            [System.IO.Path]::GetDirectoryName($ExecutablePath)
            "C:\Windows\System32"
            "C:\Windows"
        ) | Select-Object -Unique

        Set-Item "Env:CC_DATA_ROOT" -Value $DataRoot
        Set-Item "Env:CC_APP_STATE_PATH" -Value $AppStatePath
        Set-Item "Env:CC_SMOKE_TEST_OUTPUT" -Value $ReportPath
        Set-Item "Env:CC_SMOKE_PROGRESS_PATH" -Value $ProgressPath
        Set-Item "Env:PATH" -Value ($runtimePathEntries -join ';')
        Remove-Item "Env:QML2_IMPORT_PATH" -ErrorAction SilentlyContinue
        Remove-Item "Env:QT_PLUGIN_PATH" -ErrorAction SilentlyContinue
        Remove-Item "Env:QT_QPA_PLATFORM" -ErrorAction SilentlyContinue
        Remove-Item "Env:QT_QUICK_BACKEND" -ErrorAction SilentlyContinue

        $process = Start-Process -FilePath $ExecutablePath -WorkingDirectory ([System.IO.Path]::GetDirectoryName($ExecutablePath)) -Wait -PassThru
        $exitCode = $process.ExitCode
    }
    finally {
        foreach ($envName in $trackedEnv) {
            Restore-EnvVar -Name $envName -PreviousValue $previous[$envName]
        }
    }

    if ($exitCode -ne 0) {
        throw "Smoke run '$Name' failed with exit code $exitCode."
    }
    if (-not (Test-Path -LiteralPath $ReportPath)) {
        throw "Smoke run '$Name' did not produce a report: $ReportPath"
    }

    return Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json
}

function Assert-Report {
    param(
        [pscustomobject]$Report,
        [string]$RunName,
        [bool]$ExpectShouldShow,
        [ref]$Errors
    )

    if ([string]$Report.smoke_scope -ne "state_only") {
        $Errors.Value += "${RunName}: expected smoke_scope=state_only but got '$($Report.smoke_scope)'."
    }
    if ([bool]$Report.profiles_dir_exists -ne $true) {
        $Errors.Value += "${RunName}: profiles directory was not created."
    }
    if ([bool]$Report.default_profile_exists -ne $true) {
        $Errors.Value += "${RunName}: default profile template missing."
    }
    if ([bool]$Report.should_show_window_on_launch -ne $ExpectShouldShow) {
        $Errors.Value += "${RunName}: should_show_window_on_launch expected $ExpectShouldShow but got $($Report.should_show_window_on_launch)."
    }
    if ([bool]$Report.launch_to_tray_persisted -ne $true) {
        $Errors.Value += "${RunName}: launch_to_tray was not persisted."
    }
    if ([bool]$Report.profile_save_succeeded -ne $true) {
        $Errors.Value += "${RunName}: profile save did not produce a file."
    }
    if ([bool]$Report.disable_roundtrip_ok -ne $true) {
        $Errors.Value += "${RunName}: disable roundtrip failed."
    }
    if ([bool]$Report.enable_roundtrip_ok -ne $true) {
        $Errors.Value += "${RunName}: enable roundtrip failed."
    }
    if ([string]::IsNullOrWhiteSpace([string]$Report.selected_profile_name)) {
        $Errors.Value += "${RunName}: selected profile name was empty."
    }
}

if (-not (Test-Path -LiteralPath $resolvedExePath)) {
    throw "Missing deployed executable: $resolvedExePath"
}

Remove-PathSafe -Path $smokeRoot
New-Item -ItemType Directory -Force $smokeRoot | Out-Null

$dataRoot = Join-Path $smokeRoot "data"
$profilesRoot = Join-Path $dataRoot "profiles"
$statePath = Join-Path $dataRoot "app-state.json"
$firstRunReportPath = Join-Path $smokeRoot "first-run.json"
$secondRunReportPath = Join-Path $smokeRoot "second-run.json"
$firstRunProgressPath = Join-Path $smokeRoot "first-run-progress.log"
$secondRunProgressPath = Join-Path $smokeRoot "second-run-progress.log"
$summaryPath = Join-Path $smokeRoot "summary.json"

New-Item -ItemType Directory -Force $profilesRoot | Out-Null
Copy-FileIfExists -Source (Join-Path $root "profiles\default.toml") -Destination (Join-Path $profilesRoot "default.toml")

$firstRun = Invoke-SmokeRun -Name "first-run" -ExecutablePath $resolvedExePath -DataRoot $dataRoot -AppStatePath $statePath -ReportPath $firstRunReportPath -ProgressPath $firstRunProgressPath
$secondRun = Invoke-SmokeRun -Name "second-run" -ExecutablePath $resolvedExePath -DataRoot $dataRoot -AppStatePath $statePath -ReportPath $secondRunReportPath -ProgressPath $secondRunProgressPath

$errors = @()
Assert-Report -Report $firstRun -RunName "first-run" -ExpectShouldShow $true -Errors ([ref]$errors)
Assert-Report -Report $secondRun -RunName "second-run" -ExpectShouldShow $false -Errors ([ref]$errors)

$summary = [ordered]@{
    status = if ($errors.Count -eq 0) { "PASS" } else { "FAIL" }
    exe_path = $resolvedExePath
    deploy_root = $deployRoot
    smoke_root = $smokeRoot
    first_run_report = $firstRunReportPath
    second_run_report = $secondRunReportPath
    first_run_progress = $firstRunProgressPath
    second_run_progress = $secondRunProgressPath
    app_state_path = $statePath
    first_should_show_window_on_launch = [bool]$firstRun.should_show_window_on_launch
    second_should_show_window_on_launch = [bool]$secondRun.should_show_window_on_launch
    launch_to_tray_after_second_run = [bool]$secondRun.launch_to_tray_persisted
    profile_save_succeeded = ([bool]$firstRun.profile_save_succeeded) -and ([bool]$secondRun.profile_save_succeeded)
    errors = $errors
}

$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryPath -Encoding ASCII

if ($errors.Count -gt 0) {
    throw ("Native runtime smoke failed:`n- " + ($errors -join "`n- "))
}

Write-Output "SMOKE_STATUS=PASS"
Write-Output "SMOKE_SUMMARY=$summaryPath"
Write-Output "FIRST_RUN_REPORT=$firstRunReportPath"
Write-Output "SECOND_RUN_REPORT=$secondRunReportPath"
