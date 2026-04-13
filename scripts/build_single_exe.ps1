param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$StaticQtRoot = $env:CC_STATIC_QT_ROOT,

    [string]$ProjectFile,

    [string]$BuildRoot,

    [string]$OutputRoot,

    [string]$TargetName = "ComfortCues"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$defaultBuildRoot = Join-Path $root "build\single-exe"
$defaultOutputRoot = Join-Path $root "release\single-exe"
$buildRoot = if ([string]::IsNullOrWhiteSpace($BuildRoot)) { $defaultBuildRoot } else { $BuildRoot }
$outputRoot = if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $defaultOutputRoot } else { $OutputRoot }

function Resolve-ProjectFile {
    param([string]$ExplicitProjectFile)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitProjectFile)) {
        if (-not (Test-Path -LiteralPath $ExplicitProjectFile)) {
            throw "Project file not found: $ExplicitProjectFile"
        }
        return (Resolve-Path -LiteralPath $ExplicitProjectFile).Path
    }

    foreach ($candidate in @(
        (Join-Path $root "native\ComfortCues.pro")
    )) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Unable to locate a Qt project file."
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

function Resolve-VcVars {
    $candidate = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    throw "Unable to locate vcvars64.bat for Visual Studio Build Tools."
}

function Resolve-NMake {
    $match = Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" -Recurse -Filter nmake.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($null -ne $match) {
        return $match.FullName
    }

    throw "Unable to locate nmake.exe."
}

function Resolve-StaticQmake {
    param([string]$SdkRootOrQmake)

    if ([string]::IsNullOrWhiteSpace($SdkRootOrQmake)) {
        throw "True single EXE build requires CC_STATIC_QT_ROOT or -StaticQtRoot pointing to a static Qt SDK."
    }

    if ((Test-Path -LiteralPath $SdkRootOrQmake) -and ((Get-Item -LiteralPath $SdkRootOrQmake).PSIsContainer -eq $false)) {
        return (Resolve-Path -LiteralPath $SdkRootOrQmake).Path
    }

    foreach ($candidate in @(
        (Join-Path $SdkRootOrQmake "bin\qmake.exe"),
        (Join-Path $SdkRootOrQmake "Library\bin\qmake.exe")
    )) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Unable to locate qmake.exe under static Qt root: $SdkRootOrQmake"
}

function Resolve-CorePrl {
    param([string]$QmakePath)

    $qtBin = Split-Path -Parent $QmakePath
    $qtRoot = Split-Path -Parent $qtBin
    foreach ($libRoot in @(
        (Join-Path $qtRoot "lib"),
        (Join-Path $qtRoot "Library\lib")
    )) {
        foreach ($name in @("Qt6Core.prl", "Qt5Core.prl", "Qt6Core_conda.prl", "Qt5Core_conda.prl")) {
            $candidate = Join-Path $libRoot $name
            if (Test-Path -LiteralPath $candidate) {
                return $candidate
            }
        }
    }

    throw "Unable to locate a QtCore .prl file under $qtRoot\lib"
}

function Assert-StaticQtSdk {
    param([string]$QmakePath)

    $prl = Resolve-CorePrl -QmakePath $QmakePath
    $prlText = Get-Content -Raw -LiteralPath $prl
    if ($prlText -match '(^|[\s=])shared($|[\s])') {
        throw "The Qt SDK at $QmakePath is a shared/dynamic build. A true single EXE requires a static Qt SDK."
    }
}

function Resolve-MakeTool {
    param([string]$QmakePath)

    $spec = (& $QmakePath -query QMAKE_SPEC 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($spec)) {
        throw "Unable to query QMAKE_SPEC from $QmakePath"
    }

    if ($spec -match 'msvc') {
        return [pscustomobject]@{
            Type = "msvc"
            Tool = Resolve-NMake
            VcVars = Resolve-VcVars
        }
    }

    $make = Get-Command "mingw32-make" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $make) {
        $make = Get-Command "make" -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($null -eq $make) {
        throw "Unable to locate a make tool for non-MSVC static Qt build."
    }

    return [pscustomobject]@{
        Type = "make"
        Tool = $make.Source
        VcVars = $null
    }
}

$projectPath = Resolve-ProjectFile -ExplicitProjectFile $ProjectFile
$qmakePath = Resolve-StaticQmake -SdkRootOrQmake $StaticQtRoot
Assert-StaticQtSdk -QmakePath $qmakePath
$makeTool = Resolve-MakeTool -QmakePath $qmakePath

$buildDir = Join-Path $buildRoot ($Configuration.ToLower())
$outputExe = Join-Path $outputRoot "$TargetName.exe"

Remove-PathSafe -Path $buildDir
New-Item -ItemType Directory -Force $buildDir | Out-Null
New-Item -ItemType Directory -Force $outputRoot | Out-Null
Remove-PathSafe -Path $outputExe

$mapping = New-WorkspaceMapping -WorkspaceRoot $root

try {
    $mappedBuildDir = Convert-ToMappedPath -ActualPath $buildDir -WorkspaceRoot $root -MappedRoot $mapping.Root
    $mappedProjectPath = Convert-ToMappedPath -ActualPath $projectPath -WorkspaceRoot $root -MappedRoot $mapping.Root

    if ($makeTool.Type -eq "msvc") {
        $cmdGenerate = 'call "{0}" >nul && cd /d "{1}" && "{2}" "{3}" CONFIG+={4} CONFIG+=single_exe CONFIG-=debug_and_release' -f
            $makeTool.VcVars, $mappedBuildDir, $qmakePath, $mappedProjectPath, $Configuration.ToLower()
        & $env:ComSpec /d /c $cmdGenerate
        if ($LASTEXITCODE -ne 0) {
            throw "Static qmake generation failed."
        }

        $cmdBuild = 'call "{0}" >nul && cd /d "{1}" && "{2}"' -f $makeTool.VcVars, $mappedBuildDir, $makeTool.Tool
        & $env:ComSpec /d /c $cmdBuild
        if ($LASTEXITCODE -ne 0) {
            throw "Static single EXE build failed."
        }
    }
    else {
        Push-Location $buildDir
        try {
            & $qmakePath $projectPath "CONFIG+=$($Configuration.ToLower())" "CONFIG+=single_exe" "CONFIG-=debug_and_release"
            if ($LASTEXITCODE -ne 0) {
                throw "Static qmake generation failed."
            }

            & $makeTool.Tool "-j$([Environment]::ProcessorCount)"
            if ($LASTEXITCODE -ne 0) {
                throw "Static single EXE build failed."
            }
        }
        finally {
            Pop-Location
        }
    }
}
finally {
    Remove-WorkspaceMapping -Mapping $mapping
}

$builtExe = Join-Path $buildDir "$TargetName.exe"
if (-not (Test-Path -LiteralPath $builtExe)) {
    $exeCandidate = Get-ChildItem -LiteralPath $buildDir -Filter *.exe -File | Select-Object -First 1
    if ($null -eq $exeCandidate) {
        throw "Static build completed but no executable was found in $buildDir"
    }
    $builtExe = $exeCandidate.FullName
}

Copy-Item -LiteralPath $builtExe -Destination $outputExe -Force

Write-Output "STATIC_QMAKE=$qmakePath"
Write-Output "BUILD_DIR=$buildDir"
Write-Output "SINGLE_EXE=$outputExe"
