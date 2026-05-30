param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$BuildRoot,

    [string]$DeployRoot,

    [string]$ExeName = "ComfortCues.exe",

    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$defaultBuildRoot = Join-Path $root "build\native"
$defaultDeployRoot = Join-Path $root "dist\native"
$buildRoot = if ([string]::IsNullOrWhiteSpace($BuildRoot)) { $defaultBuildRoot } else { $BuildRoot }
$deployRoot = if ([string]::IsNullOrWhiteSpace($DeployRoot)) { $defaultDeployRoot } else { $DeployRoot }
$projectRoot = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $root } else { $ProjectRoot }

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

function Test-NativeTool {
    param(
        [string]$ToolPath,
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($ToolPath) -or -not (Test-Path -LiteralPath $ToolPath)) {
        return $false
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $ToolPath @Arguments > $null 2> $null
        return $LASTEXITCODE -eq 0
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Remove-PathSafe {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Get-FreeDriveLetter {
    $used = (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name)
    foreach ($letter in @("X", "W", "V", "U", "T", "S", "R", "Q", "P")) {
        if ($used -notcontains $letter) {
            return $letter
        }
    }

    throw "Unable to allocate a temporary ASCII drive letter."
}

function New-WorkspaceMapping {
    param([string]$WorkspaceRoot)

    if ($WorkspaceRoot -notmatch "[^\u0000-\u007F]") {
        return [pscustomobject]@{
            Active = $false
            Drive = $null
            Root = $WorkspaceRoot
        }
    }

    $letter = Get-FreeDriveLetter
    & subst "${letter}:" $WorkspaceRoot | Out-Null
    return [pscustomobject]@{
        Active = $true
        Drive = "${letter}:"
        Root = "${letter}:\"
    }
}

function Remove-WorkspaceMapping {
    param($Mapping)

    if ($null -ne $Mapping -and $Mapping.Active) {
        & subst $Mapping.Drive /d | Out-Null
    }
}

function Convert-ToMappedPath {
    param(
        [string]$ActualPath,
        [string]$WorkspaceRoot,
        [string]$MappedRoot
    )

    if ($ActualPath.StartsWith($WorkspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $ActualPath.Substring($WorkspaceRoot.Length).TrimStart("\")
        if ([string]::IsNullOrWhiteSpace($relative)) {
            return $MappedRoot.TrimEnd("\")
        }
        return Join-Path $MappedRoot $relative
    }

    return $ActualPath
}

function Copy-PathIfExists {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Source) {
        New-Item -ItemType Directory -Force $Destination | Out-Null
        Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
    }
}

function Copy-FileIfExists {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Resolve-CondaQtPackage {
    $roots = @(
        "E:\Users\qiyue\miniconda3\pkgs",
        "C:\Users\qiyue\miniconda3\pkgs",
        (Join-Path $env:USERPROFILE "miniconda3\pkgs")
    ) | Select-Object -Unique

    $matches = @()
    foreach ($rootPath in $roots) {
        if (-not (Test-Path -LiteralPath $rootPath)) {
            continue
        }

        $matches += Get-ChildItem -LiteralPath $rootPath -Directory -Filter "qt-main-*" -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "Library\bin\windeployqt.exe") } |
            Sort-Object Name -Descending
    }

    $package = $matches | Select-Object -First 1
    if ($null -eq $package) {
        throw "Unable to locate a fallback Conda Qt deployment SDK."
    }

    $binRoot = Join-Path $package.FullName "Library\bin"
    return [pscustomobject]@{
        Root = $package.FullName
        BinRoot = $binRoot
        Windeployqt = Join-Path $binRoot "windeployqt.exe"
        QmlRoot = Join-Path $package.FullName "Library\qml"
    }
}

function Get-CondaPackageRoots {
    return @(
        "E:\Users\qiyue\miniconda3\pkgs",
        "C:\Users\qiyue\miniconda3\pkgs",
        (Join-Path $env:USERPROFILE "miniconda3\pkgs")
    ) | Select-Object -Unique
}

function Resolve-CondaRuntimeDll {
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
            return $candidate.FullName
        }
    }

    throw "Unable to locate runtime DLL: $DllName"
}

function Resolve-CondaQtToolBin {
    $candidates = @(
        "E:\Users\qiyue\miniconda3\envs\ui_in\Lib\site-packages\qt5_applications\Qt\bin",
        "C:\Users\qiyue\miniconda3\envs\ui_in\Lib\site-packages\qt5_applications\Qt\bin",
        (Join-Path $env:USERPROFILE "miniconda3\envs\ui_in\Lib\site-packages\qt5_applications\Qt\bin")
    ) | Select-Object -Unique

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "windeployqt.exe")) {
            return $candidate
        }
    }

    throw "Unable to locate a runnable Qt tool bin directory."
}

function Resolve-IcuBin {
    $roots = @(
        "E:\Users\qiyue\miniconda3\pkgs",
        "C:\Users\qiyue\miniconda3\pkgs",
        (Join-Path $env:USERPROFILE "miniconda3\pkgs")
    ) | Select-Object -Unique

    foreach ($rootPath in $roots) {
        if (-not (Test-Path -LiteralPath $rootPath)) {
            continue
        }

        $match = Get-ChildItem -LiteralPath $rootPath -Directory -Filter "icu-*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($null -ne $match) {
            $bin = Join-Path $match.FullName "Library\bin"
            if (Test-Path -LiteralPath (Join-Path $bin "icuin73.dll")) {
                return $bin
            }
        }
    }

    throw "Unable to locate ICU runtime directory."
}

function Resolve-VcVars {
    $candidate = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    throw "Unable to locate vcvars64.bat for Visual Studio Build Tools."
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

$buildDir = Join-Path $buildRoot ($Configuration.ToLower())
$exePath = Join-Path $buildDir $ExeName
if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Missing build output: $exePath"
}

Remove-PathSafe -Path $deployRoot
New-Item -ItemType Directory -Force $deployRoot | Out-Null
Copy-Item -LiteralPath $exePath -Destination (Join-Path $deployRoot $ExeName) -Force

$qmlSource = Join-Path $projectRoot "src\comfort_cues\ui\qml"
$assetSource = Join-Path $projectRoot "src\comfort_cues\ui\assets"
$profilesSource = Join-Path $projectRoot "profiles"
$readmeSource = Join-Path $projectRoot "README.md"

$pathWindeployqt = Try-ResolveTool -Names @("windeployqt6", "windeployqt", "windeployqt-qt6")
$pathQmake = Try-ResolveTool -Names @("qmake6", "qmake-qt6", "qmake")
$usePathQt = Test-NativeTool -ToolPath $pathWindeployqt -Arguments @("--help")
$fallbackQt = $null
$toolBin = $null
$icuBin = $null
$vcvars = $null
$vcRedistCrt = $null
if (-not $usePathQt) {
    $fallbackQt = Resolve-CondaQtPackage
    $toolBin = Resolve-CondaQtToolBin
    $icuBin = Resolve-IcuBin
    $vcvars = Resolve-VcVars
    $vcRedistCrt = Resolve-VcRedistCrt
}
$mapping = New-WorkspaceMapping -WorkspaceRoot $root

try {
    $mappedDeployRoot = Convert-ToMappedPath -ActualPath $deployRoot -WorkspaceRoot $root -MappedRoot $mapping.Root
    $mappedDeployExe = Convert-ToMappedPath -ActualPath (Join-Path $deployRoot $ExeName) -WorkspaceRoot $root -MappedRoot $mapping.Root
    $mappedQmlSource = Convert-ToMappedPath -ActualPath $qmlSource -WorkspaceRoot $root -MappedRoot $mapping.Root

    if ($usePathQt) {
        $qtBin = Split-Path -Parent $pathWindeployqt
        $cmd = 'set PATH={0};%PATH% && "{1}" --{2} --no-quick-import --dir "{3}" "{4}"' -f
            $qtBin,
            $pathWindeployqt,
            $Configuration.ToLower(),
            $mappedDeployRoot,
            $mappedDeployExe
    }
    else {
        $cmd = 'call "{0}" >nul && set PATH={1};{2};{3};%PATH% && "{4}" --{5} --no-quick-import --dir "{6}" --compiler-runtime "{7}"' -f
            $vcvars,
            $icuBin,
            $fallbackQt.BinRoot,
            $toolBin,
            $fallbackQt.Windeployqt,
            $Configuration.ToLower(),
            $mappedDeployRoot,
            $mappedDeployExe
    }

    & $env:ComSpec /d /c $cmd
    $deployExit = $LASTEXITCODE

    $qtCore = if ($usePathQt) { Join-Path $deployRoot "Qt6Core.dll" } else { Join-Path $deployRoot "Qt5Core_conda.dll" }
    if ($deployExit -notin @(0, 1)) {
        throw "windeployqt failed with exit code $deployExit"
    }
    if (-not (Test-Path -LiteralPath $qtCore)) {
        throw "windeployqt did not produce the expected Qt runtime files."
    }
}
finally {
    Remove-WorkspaceMapping -Mapping $mapping
}

Copy-PathIfExists -Source $qmlSource -Destination (Join-Path $deployRoot "qml\app")
Copy-PathIfExists -Source $assetSource -Destination (Join-Path $deployRoot "assets")
Copy-PathIfExists -Source $profilesSource -Destination (Join-Path $deployRoot "profiles")

if (Test-Path -LiteralPath $readmeSource) {
    Copy-Item -LiteralPath $readmeSource -Destination (Join-Path $deployRoot "README.md") -Force
}

$qtConfPath = Join-Path $deployRoot "qt.conf"
@(
    "[Paths]"
    "Prefix=."
    "Plugins=."
    "Qml2Imports=qml"
    "Imports=qml"
) | Set-Content -LiteralPath $qtConfPath -Encoding ASCII

foreach ($module in @("Qt", "QtQml", "QtQuick", "QtQuick.2")) {
    if ($null -ne $fallbackQt) {
        Copy-PathIfExists -Source (Join-Path $fallbackQt.QmlRoot $module) -Destination (Join-Path $deployRoot "qml\$module")
    }
}

if ($usePathQt -and -not [string]::IsNullOrWhiteSpace($pathQmake)) {
    $qtQmlRoot = & $pathQmake -query QT_INSTALL_QML
    $qtBin = Split-Path -Parent $pathWindeployqt
    foreach ($module in @("Qt", "QtQml", "QtQuick", "QtQuick.2")) {
        Copy-PathIfExists -Source (Join-Path $qtQmlRoot $module) -Destination (Join-Path $deployRoot "qml\$module")
    }

    foreach ($dllName in @("Qt6QuickControls2.dll", "Qt6QuickControls2Impl.dll", "Qt6QuickLayouts.dll", "Qt6QuickTemplates2.dll")) {
        Copy-FileIfExists -Source (Join-Path $qtBin $dllName) -Destination (Join-Path $deployRoot $dllName)
    }

    foreach ($dllName in @(
        "libb2-1.dll",
        "libbrotlicommon.dll",
        "libbrotlidec.dll",
        "libbz2-1.dll",
        "libdouble-conversion.dll",
        "libffi-8.dll",
        "libfreetype-6.dll",
        "libgcc_s_seh-1.dll",
        "libglib-2.0-0.dll",
        "libgio-2.0-0.dll",
        "libgmodule-2.0-0.dll",
        "libgobject-2.0-0.dll",
        "libgraphite2.dll",
        "libharfbuzz-0.dll",
        "libiconv-2.dll",
        "libicudt78.dll",
        "libicuin78.dll",
        "libicuuc78.dll",
        "libintl-8.dll",
        "libjpeg-8.dll",
        "libmd4c.dll",
        "libpcre2-16-0.dll",
        "libpcre2-8-0.dll",
        "libpng16-16.dll",
        "libstdc++-6.dll",
        "libwinpthread-1.dll",
        "libzstd.dll",
        "Qt6LabsAnimation.dll",
        "Qt6LabsFolderListModel.dll",
        "Qt6LabsPlatform.dll",
        "Qt6LabsQmlModels.dll",
        "Qt6LabsSettings.dll",
        "Qt6LabsSharedImage.dll",
        "Qt6LabsStyleKit.dll",
        "Qt6LabsStyleKitImpl.dll",
        "Qt6LabsSynchronizer.dll",
        "Qt6LabsWavefrontMesh.dll",
        "Qt6QmlLocalStorage.dll",
        "Qt6QmlXmlListModel.dll",
        "Qt6QuickControls2Basic.dll",
        "Qt6QuickControls2BasicStyleImpl.dll",
        "Qt6QuickControls2FluentWinUI3StyleImpl.dll",
        "Qt6QuickControls2Fusion.dll",
        "Qt6QuickControls2FusionStyleImpl.dll",
        "Qt6QuickControls2Imagine.dll",
        "Qt6QuickControls2ImagineStyleImpl.dll",
        "Qt6QuickControls2Material.dll",
        "Qt6QuickControls2MaterialStyleImpl.dll",
        "Qt6QuickControls2Universal.dll",
        "Qt6QuickControls2UniversalStyleImpl.dll",
        "Qt6QuickControls2WindowsStyleImpl.dll",
        "Qt6QuickDialogs2.dll",
        "Qt6QuickDialogs2QuickImpl.dll",
        "Qt6QuickDialogs2Utils.dll",
        "Qt6QuickEffects.dll",
        "Qt6QuickParticles.dll",
        "Qt6QuickShapes.dll",
        "Qt6QuickShapesDesignHelpers.dll",
        "Qt6QuickTest.dll",
        "Qt6QuickVectorImage.dll",
        "Qt6QuickVectorImageGenerator.dll",
        "Qt6QuickVectorImageHelpers.dll",
        "Qt6Sql.dll",
        "Qt6Svg.dll",
        "Qt6Test.dll",
        "zlib1.dll"
    )) {
        Copy-FileIfExists -Source (Join-Path $qtBin $dllName) -Destination (Join-Path $deployRoot $dllName)
    }
}

if ($null -ne $fallbackQt) {
    foreach ($dllName in @("Qt5QuickControls2_conda.dll", "Qt5QuickTemplates2_conda.dll", "Qt5QmlWorkerScript_conda.dll")) {
        Copy-FileIfExists -Source (Join-Path $fallbackQt.BinRoot $dllName) -Destination (Join-Path $deployRoot $dllName)
    }

    foreach ($dllName in @("msvcp140.dll", "msvcp140_1.dll", "vcruntime140.dll", "vcruntime140_1.dll")) {
        Copy-FileIfExists -Source (Join-Path $vcRedistCrt $dllName) -Destination (Join-Path $deployRoot $dllName)
    }

    foreach ($dllName in @("libpng16.dll", "zlib.dll", "zstd.dll", "libcrypto-3-x64.dll", "libssl-3-x64.dll")) {
        Copy-FileIfExists -Source (Resolve-CondaRuntimeDll -DllName $dllName) -Destination (Join-Path $deployRoot $dllName)
    }
}

Write-Output "DEPLOY_DIR=$deployRoot"
Write-Output "DEPLOY_EXE=$(Join-Path $deployRoot $ExeName)"
