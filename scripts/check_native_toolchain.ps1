param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Try-ResolveTool {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) {
            return $command.Source
        }
    }

    return $null
}

function Invoke-Probe {
    param(
        [string]$Label,
        [string]$ToolPath,
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($ToolPath)) {
        return [pscustomobject]@{
            Label = $Label
            Status = "MISSING"
            Path = ""
            ExitCode = ""
        }
    }

    & $ToolPath @Arguments | Out-Null
    return [pscustomobject]@{
        Label = $Label
        Status = if ($LASTEXITCODE -eq 0) { "OK" } else { "BROKEN" }
        Path = $ToolPath
        ExitCode = $LASTEXITCODE
    }
}

function Invoke-PathProbe {
    param(
        [string]$Label,
        [string]$ToolPath,
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($ToolPath)) {
        return [pscustomobject]@{
            Label = $Label
            Status = "MISSING"
            Path = ""
            ExitCode = ""
        }
    }

    & $env:ComSpec /d /c ('set PATH={0};%PATH% && "{1}" {2}' -f (Split-Path -Parent $ToolPath), $ToolPath, ($Arguments -join ' ')) | Out-Null
    return [pscustomobject]@{
        Label = $Label
        Status = if ($LASTEXITCODE -eq 0) { "OK" } else { "BROKEN" }
        Path = $ToolPath
        ExitCode = $LASTEXITCODE
    }
}

function Resolve-CondaQtPackage {
    $roots = @(
        "E:\Users\qiyue\miniconda3\pkgs",
        "C:\Users\qiyue\miniconda3\pkgs",
        (Join-Path $env:USERPROFILE "miniconda3\pkgs")
    ) | Select-Object -Unique

    foreach ($rootPath in $roots) {
        if (-not (Test-Path -LiteralPath $rootPath)) {
            continue
        }

        $match = Get-ChildItem -LiteralPath $rootPath -Directory -Filter "qt-main-*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($null -ne $match) {
            $bin = Join-Path $match.FullName "Library\bin"
            if (Test-Path -LiteralPath (Join-Path $bin "qmake.exe")) {
                return [pscustomobject]@{
                    Root = $match.FullName
                    BinRoot = $bin
                    Qmake = Join-Path $bin "qmake.exe"
                    Windeployqt = Join-Path $bin "windeployqt.exe"
                }
            }
        }
    }

    return $null
}

function Resolve-CondaQtToolBin {
    $candidates = @(
        "E:\Users\qiyue\miniconda3\envs\ui_in\Lib\site-packages\qt5_applications\Qt\bin",
        "C:\Users\qiyue\miniconda3\envs\ui_in\Lib\site-packages\qt5_applications\Qt\bin",
        (Join-Path $env:USERPROFILE "miniconda3\envs\ui_in\Lib\site-packages\qt5_applications\Qt\bin")
    ) | Select-Object -Unique

    foreach ($candidate in $candidates) {
        if ((Test-Path -LiteralPath (Join-Path $candidate "rcc.exe")) -and
            (Test-Path -LiteralPath (Join-Path $candidate "moc.exe")) -and
            (Test-Path -LiteralPath (Join-Path $candidate "uic.exe")) -and
            (Test-Path -LiteralPath (Join-Path $candidate "windeployqt.exe"))) {
            return $candidate
        }
    }

    return $null
}

function Resolve-VcVars {
    $candidate = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    return $null
}

function Resolve-NMake {
    $candidate = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\nmake.exe"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    $match = Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" -Recurse -Filter nmake.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $match) {
        return $match.FullName
    }

    return $null
}

function Resolve-StaticQtRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:CC_STATIC_QT_ROOT)) {
        return $env:CC_STATIC_QT_ROOT
    }

    return $null
}

function Resolve-StaticQmake {
    param([string]$StaticQtRoot)

    if ([string]::IsNullOrWhiteSpace($StaticQtRoot)) {
        return $null
    }

    if ((Test-Path -LiteralPath $StaticQtRoot) -and -not (Get-Item -LiteralPath $StaticQtRoot).PSIsContainer) {
        return $StaticQtRoot
    }

    $candidate = Join-Path $StaticQtRoot "bin\qmake.exe"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    return $null
}

function Get-StaticQtMode {
    param([string]$QmakePath)

    if ([string]::IsNullOrWhiteSpace($QmakePath)) {
        return "MISSING"
    }

    $qtBin = Split-Path -Parent $QmakePath
    $qtRoot = Split-Path -Parent $qtBin
    foreach ($name in @("Qt6Core.prl", "Qt5Core.prl", "Qt6Core_conda.prl", "Qt5Core_conda.prl")) {
        $candidate = Join-Path $qtRoot "lib\$name"
        if (-not (Test-Path -LiteralPath $candidate)) {
            continue
        }

        $text = Get-Content -Raw -LiteralPath $candidate
        if ($text -match '(^|[\s=])shared($|[\s])') {
            return "DYNAMIC"
        }
        return "STATIC"
    }

    return "UNKNOWN"
}

$pathQmake = Try-ResolveTool -Names @("qmake6", "qmake-qt6", "qmake")
$pathMake = Try-ResolveTool -Names @("mingw32-make", "make")
$pathGcc = Try-ResolveTool -Names @("gcc")
$pathGxx = Try-ResolveTool -Names @("g++")
$pathWindeployqt = Try-ResolveTool -Names @("windeployqt", "windeployqt6", "windeployqt-qt6")

$primary = @(
    Invoke-Probe -Label "path_qmake" -ToolPath $pathQmake -Arguments @("-query")
    Invoke-Probe -Label "path_make" -ToolPath $pathMake -Arguments @("--version")
    Invoke-Probe -Label "path_gcc" -ToolPath $pathGcc -Arguments @("--version")
    Invoke-Probe -Label "path_g++" -ToolPath $pathGxx -Arguments @("--version")
    Invoke-Probe -Label "path_windeployqt" -ToolPath $pathWindeployqt -Arguments @("--help")
)

$condaQt = Resolve-CondaQtPackage
$condaToolBin = Resolve-CondaQtToolBin
$vcvars = Resolve-VcVars
$nmake = Resolve-NMake
$staticQtRoot = Resolve-StaticQtRoot
$staticQmake = Resolve-StaticQmake -StaticQtRoot $staticQtRoot
$staticMode = Get-StaticQtMode -QmakePath $staticQmake
$fallbackQmake = if ($null -ne $condaQt) { $condaQt.Qmake } else { $null }
$fallbackWindeployqt = if ($null -ne $condaQt) { $condaQt.Windeployqt } else { $null }
$fallbackRcc = if ($null -ne $condaToolBin) { Join-Path $condaToolBin "rcc.exe" } else { $null }
$fallbackMoc = if ($null -ne $condaToolBin) { Join-Path $condaToolBin "moc.exe" } else { $null }
$fallbackUic = if ($null -ne $condaToolBin) { Join-Path $condaToolBin "uic.exe" } else { $null }

$fallback = @(
    Invoke-Probe -Label "fallback_qmake" -ToolPath $fallbackQmake -Arguments @("-query")
    Invoke-Probe -Label "fallback_rcc" -ToolPath $fallbackRcc -Arguments @("--version")
    Invoke-Probe -Label "fallback_moc" -ToolPath $fallbackMoc -Arguments @("-v")
    Invoke-Probe -Label "fallback_uic" -ToolPath $fallbackUic -Arguments @("-v")
    Invoke-PathProbe -Label "fallback_windeployqt" -ToolPath $fallbackWindeployqt -Arguments @("--help")
    Invoke-Probe -Label "fallback_nmake" -ToolPath $nmake -Arguments @("/?")
    [pscustomobject]@{
        Label = "fallback_vcvars"
        Status = if ([string]::IsNullOrWhiteSpace($vcvars)) { "MISSING" } else { "OK" }
        Path = if ([string]::IsNullOrWhiteSpace($vcvars)) { "" } else { $vcvars }
        ExitCode = ""
    }
    [pscustomobject]@{
        Label = "single_exe_qmake"
        Status = if ([string]::IsNullOrWhiteSpace($staticQmake)) { "MISSING" } else { "OK" }
        Path = if ([string]::IsNullOrWhiteSpace($staticQmake)) { "" } else { $staticQmake }
        ExitCode = ""
    }
    [pscustomobject]@{
        Label = "single_exe_sdk"
        Status = $staticMode
        Path = if ([string]::IsNullOrWhiteSpace($staticQtRoot)) { "" } else { $staticQtRoot }
        ExitCode = ""
    }
)

$results = @($primary + $fallback)
$results | Format-Table -AutoSize

$primaryReady = ($primary | Where-Object { $_.Status -eq "OK" }).Count -ge 4
$fallbackReady = ($fallback | Where-Object { $_.Status -eq "OK" }).Count -ge 6

if (-not ($primaryReady -or $fallbackReady)) {
    throw "No working native toolchain was found."
}
