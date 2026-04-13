param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$DeployRoot,

    [string]$ExePath,

    [string]$SessionRoot,

    [switch]$NoLaunch
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
$sessionRoot = if ([string]::IsNullOrWhiteSpace($SessionRoot)) {
    Join-Path $root "build\native-manual\$($Configuration.ToLower())"
} else {
    $SessionRoot
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

function Convert-ToPsSingleQuoted {
    param([string]$Value)

    return $Value.Replace("'", "''")
}

function Get-CondaPackageRoots {
    return @(
        "E:\Users\qiyue\miniconda3\pkgs",
        "C:\Users\qiyue\miniconda3\pkgs",
        (Join-Path $env:USERPROFILE "miniconda3\pkgs")
    ) | Select-Object -Unique
}

function Get-CondaRuntimeBinDirectories {
    return @(
        "E:\Users\qiyue\miniconda3\Library\bin",
        "E:\Users\qiyue\miniconda3\envs\ui_in\Library\bin",
        (Join-Path $env:USERPROFILE "miniconda3\Library\bin"),
        (Join-Path $env:USERPROFILE "miniconda3\envs\ui_in\Library\bin")
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique
}

function Resolve-CondaQtBin {
    foreach ($rootPath in Get-CondaPackageRoots) {
        if (-not (Test-Path -LiteralPath $rootPath)) {
            continue
        }

        $package = Get-ChildItem -LiteralPath $rootPath -Directory -Filter "qt-main-*" -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "Library\bin\qmake.exe") } |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($null -ne $package) {
            return (Join-Path $package.FullName "Library\bin")
        }
    }

    throw "Unable to locate the Conda Qt bin directory."
}

function Resolve-CondaQtPluginRoot {
    $qtBin = Resolve-CondaQtBin
    $pluginRoot = Join-Path (Split-Path -Parent $qtBin) "plugins"
    if (-not (Test-Path -LiteralPath $pluginRoot)) {
        throw "Unable to locate the Conda Qt plugin directory."
    }
    return $pluginRoot
}

function Resolve-CondaRuntimeDllDirectory {
    param([string]$DllName)

    foreach ($rootPath in Get-CondaPackageRoots) {
        if (-not (Test-Path -LiteralPath $rootPath)) {
            continue
        }

        $candidate = Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter $DllName -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like '*\Library\bin\*' -or $_.DirectoryName -eq $rootPath } |
            Sort-Object FullName |
            Select-Object -First 1
        if ($null -ne $candidate) {
            return $candidate.DirectoryName
        }
    }

    throw "Unable to locate runtime DLL directory for $DllName"
}

function Resolve-VcRedistCrt {
    $rootPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC"
    if (-not (Test-Path -LiteralPath $rootPath)) {
        throw "Unable to locate the MSVC redist root."
    }

    $candidate = Get-ChildItem -LiteralPath $rootPath -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "x64\Microsoft.VC143.CRT" } |
        Where-Object {
            (Test-Path -LiteralPath $_) -and
            (Test-Path -LiteralPath (Join-Path $_ "msvcp140.dll")) -and
            (Test-Path -LiteralPath (Join-Path $_ "vcruntime140.dll"))
        } |
        Select-Object -First 1

    if ($null -eq $candidate) {
        throw "Unable to locate the MSVC x64 CRT runtime directory."
    }

    return $candidate
}

if (-not (Test-Path -LiteralPath $resolvedExePath)) {
    throw "Missing deployed executable: $resolvedExePath"
}

Remove-PathSafe -Path $sessionRoot
New-Item -ItemType Directory -Force $sessionRoot | Out-Null

$dataRoot = Join-Path $sessionRoot "data"
$profilesRoot = Join-Path $dataRoot "profiles"
$statePath = Join-Path $dataRoot "app-state.json"
$progressPath = Join-Path $sessionRoot "manual-runtime.log"
$notesPath = Join-Path $sessionRoot "README.txt"
$launcherPath = Join-Path $sessionRoot "launch-manual.cmd"
$launcherPs1Path = Join-Path $sessionRoot "launch-manual.ps1"
$pidPath = Join-Path $sessionRoot "manual-runtime.pid"

New-Item -ItemType Directory -Force $profilesRoot | Out-Null
Copy-FileIfExists -Source (Join-Path $root "profiles\default.toml") -Destination (Join-Path $profilesRoot "default.toml")
Copy-FileIfExists -Source (Join-Path $root "profiles\sample-third-person.toml") -Destination (Join-Path $profilesRoot "sample-third-person.toml")

$notes = @(
    "Comfort Cues manual runtime smoke session",
    "",
    "Session root: $sessionRoot",
    "Data root: $dataRoot",
    "App state: $statePath",
    "Progress log: $progressPath",
    "Launcher: $launcherPath",
    "Launcher PS1: $launcherPs1Path",
    "",
    "Checklist:",
    "1. Confirm the first launch opens the settings window instead of silently staying in tray.",
    "2. Click Bind Window while a supported 16:9 windowed or borderless game is focused.",
    "3. Toggle Debug and confirm the overlay becomes visually obvious.",
    "4. Click Save and confirm a profile file is written under data\\profiles.",
    "5. Close the settings window and reopen it from the tray icon.",
    "6. Disable, then Enable, and confirm the tray tooltip and UI state update.",
    "",
    "The generated launcher now starts an exact child process instead of polling by process name.",
    "Reference guide: docs\\native_manual_smoke.md"
)
$notes | Set-Content -LiteralPath $notesPath -Encoding ASCII

$deployDirectory = [System.IO.Path]::GetDirectoryName($resolvedExePath)
$runtimeArguments = @(
    '--cc-data-root "' + $dataRoot + '"',
    '--cc-app-state-path "' + $statePath + '"',
    '--cc-runtime-progress-path "' + $progressPath + '"',
    '--cc-force-show-settings'
) -join ' '
$runtimePathEntries = @(
    $deployDirectory
    (Get-CondaRuntimeBinDirectories)
    (Resolve-CondaQtBin)
    (Resolve-CondaRuntimeDllDirectory -DllName "libpng16.dll")
    (Resolve-CondaRuntimeDllDirectory -DllName "zlib.dll")
    (Resolve-VcRedistCrt)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
$runtimePathValue = (($runtimePathEntries -join ';') + ';' + $env:PATH)
$qtPluginPath = Resolve-CondaQtPluginRoot

$launcherPs1Template = @'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dataRoot = if ([string]::IsNullOrWhiteSpace($env:CC_DATA_ROOT)) { '__DATA_ROOT__' } else { $env:CC_DATA_ROOT }
$statePath = if ([string]::IsNullOrWhiteSpace($env:CC_APP_STATE_PATH)) { '__STATE_PATH__' } else { $env:CC_APP_STATE_PATH }
$progressPath = if ([string]::IsNullOrWhiteSpace($env:CC_RUNTIME_PROGRESS_PATH)) { '__PROGRESS_PATH__' } else { $env:CC_RUNTIME_PROGRESS_PATH }
$forceShowSettings = if ([string]::IsNullOrWhiteSpace($env:CC_FORCE_SHOW_SETTINGS)) { '1' } else { $env:CC_FORCE_SHOW_SETTINGS }

$parent = Split-Path -Parent $progressPath
if (-not [string]::IsNullOrWhiteSpace($parent)) {
    New-Item -ItemType Directory -Force $parent | Out-Null
}
Add-Content -LiteralPath $progressPath -Value 'manual_launcher: bootstrap'

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = '__EXE_PATH__'
$psi.WorkingDirectory = '__WORKING_DIR__'
$psi.UseShellExecute = $false
$psi.Arguments = '__ARGUMENTS__'
$psi.EnvironmentVariables['CC_DATA_ROOT'] = $dataRoot
$psi.EnvironmentVariables['CC_APP_STATE_PATH'] = $statePath
$psi.EnvironmentVariables['CC_RUNTIME_PROGRESS_PATH'] = $progressPath
$psi.EnvironmentVariables['CC_FORCE_SHOW_SETTINGS'] = $forceShowSettings
$psi.EnvironmentVariables['PATH'] = '__PATH_VALUE__'
if (-not [string]::IsNullOrWhiteSpace('__QT_PLUGIN_PATH__')) {
    $psi.EnvironmentVariables['QT_PLUGIN_PATH'] = '__QT_PLUGIN_PATH__'
}

$process = [System.Diagnostics.Process]::Start($psi)
if ($null -eq $process) {
    throw 'Manual runtime launcher failed to start the deployed executable.'
}

Set-Content -LiteralPath '__PID_PATH__' -Value $process.Id -Encoding ASCII
Add-Content -LiteralPath $progressPath -Value ('manual_launcher: launched pid=' + $process.Id)
'@
$launcherPs1Content = $launcherPs1Template.
    Replace('__DATA_ROOT__', (Convert-ToPsSingleQuoted -Value $dataRoot)).
    Replace('__STATE_PATH__', (Convert-ToPsSingleQuoted -Value $statePath)).
    Replace('__PROGRESS_PATH__', (Convert-ToPsSingleQuoted -Value $progressPath)).
    Replace('__EXE_PATH__', (Convert-ToPsSingleQuoted -Value $resolvedExePath)).
    Replace('__WORKING_DIR__', (Convert-ToPsSingleQuoted -Value $deployDirectory)).
    Replace('__ARGUMENTS__', (Convert-ToPsSingleQuoted -Value $runtimeArguments)).
    Replace('__PATH_VALUE__', (Convert-ToPsSingleQuoted -Value $runtimePathValue)).
    Replace('__QT_PLUGIN_PATH__', (Convert-ToPsSingleQuoted -Value $qtPluginPath)).
    Replace('__PID_PATH__', (Convert-ToPsSingleQuoted -Value $pidPath))
$launcherPs1Content | Set-Content -LiteralPath $launcherPs1Path -Encoding ASCII

$launcherLines = @(
    "@echo off",
    "setlocal",
    "set ""CC_DATA_ROOT=$dataRoot""",
    "set ""CC_APP_STATE_PATH=$statePath""",
    "set ""CC_RUNTIME_PROGRESS_PATH=$progressPath""",
    "set ""CC_FORCE_SHOW_SETTINGS=1""",
    "cd /d ""$deployDirectory""",
    "powershell -NoProfile -ExecutionPolicy Bypass -File ""$launcherPs1Path"""
)
$launcherLines | Set-Content -LiteralPath $launcherPath -Encoding ASCII

Write-Output "MANUAL_SESSION_ROOT=$sessionRoot"
Write-Output "MANUAL_DATA_ROOT=$dataRoot"
Write-Output "MANUAL_APP_STATE=$statePath"
Write-Output "MANUAL_PROGRESS_LOG=$progressPath"
Write-Output "MANUAL_NOTES=$notesPath"
Write-Output "MANUAL_LAUNCHER=$launcherPath"
Write-Output "MANUAL_LAUNCHER_PS1=$launcherPs1Path"

if ($NoLaunch) {
    Write-Output "MANUAL_STATUS=PREPARED"
    exit 0
}

Remove-Item -LiteralPath $progressPath -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $pidPath -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue

$launcherProcess = Start-Process -FilePath $env:ComSpec -ArgumentList "/d", "/c", "`"$launcherPath`"" -WorkingDirectory $sessionRoot -PassThru
if (-not $launcherProcess.WaitForExit(10000)) {
    Stop-Process -Id $launcherProcess.Id -Force -ErrorAction SilentlyContinue
    throw "Manual runtime launcher did not finish preparing the GUI process."
}
if ($launcherProcess.ExitCode -ne 0) {
    throw "Manual runtime launcher failed with exit code $($launcherProcess.ExitCode)."
}

if (-not (Test-Path -LiteralPath $pidPath)) {
    throw "Manual runtime launcher did not produce a pid file: $pidPath"
}

$appPid = [int](Get-Content -LiteralPath $pidPath | Select-Object -First 1)
$deadline = (Get-Date).AddSeconds(10)
$appProgressObserved = $false
$stateObserved = $false

do {
    $process = Get-Process -Id $appPid -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        throw "Manual runtime launcher started ComfortCues.exe, but the process exited before validation."
    }

    if (Test-Path -LiteralPath $progressPath) {
        $progressText = Get-Content -Raw -LiteralPath $progressPath -ErrorAction SilentlyContinue
        $appProgressObserved = $progressText -match 'main: application started|app_controller: constructor entered'
    }
    $stateObserved = Test-Path -LiteralPath $statePath

    if ($appProgressObserved -and $stateObserved) {
        Write-Output "MANUAL_STATUS=LAUNCHED"
        Write-Output "MANUAL_PID=$($process.Id)"
        exit 0
    }

    Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $deadline)

if (-not $appProgressObserved) {
    throw "Manual runtime launcher did not observe application progress in $progressPath"
}
if (-not $stateObserved) {
    throw "Manual runtime launcher did not observe isolated state creation at $statePath"
}
