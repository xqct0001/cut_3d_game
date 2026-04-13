param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$ProjectFile,

    [string]$BuildRoot,

    [string]$TargetName = "ComfortCues"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$defaultBuildRoot = Join-Path $root "build\native"
$buildRoot = if ([string]::IsNullOrWhiteSpace($BuildRoot)) { $defaultBuildRoot } else { $BuildRoot }

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

function Resolve-ProjectFile {
    param([string]$ExplicitProjectFile)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitProjectFile)) {
        if (-not (Test-Path -LiteralPath $ExplicitProjectFile)) {
            throw "Project file not found: $ExplicitProjectFile"
        }
        return (Resolve-Path -LiteralPath $ExplicitProjectFile).Path
    }

    $candidates = @(
        (Join-Path $root "native\ComfortCues.pro")
    )

    foreach ($candidate in $candidates) {
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

function Test-NativeTool {
    param(
        [string]$ToolPath,
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($ToolPath)) {
        return $false
    }

    & $ToolPath @Arguments | Out-Null
    return $LASTEXITCODE -eq 0
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
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "Library\bin\qmake.exe") } |
            Sort-Object Name -Descending
    }

    $package = $matches | Select-Object -First 1
    if ($null -eq $package) {
        throw "Unable to locate a fallback Conda Qt SDK."
    }

    $binRoot = Join-Path $package.FullName "Library\bin"
    return [pscustomobject]@{
        Root = $package.FullName
        BinRoot = $binRoot
        Qmake = Join-Path $binRoot "qmake.exe"
    }
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
            (Test-Path -LiteralPath (Join-Path $candidate "uic.exe"))) {
            return $candidate
        }
    }

    throw "Unable to locate runnable Qt tool binaries (rcc/moc/uic)."
}

function Resolve-VcVars {
    $candidate = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    throw "Unable to locate vcvars64.bat for Visual Studio Build Tools."
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

    throw "Unable to locate nmake.exe."
}

$projectPath = Resolve-ProjectFile -ExplicitProjectFile $ProjectFile
$buildDir = Join-Path $buildRoot ($Configuration.ToLower())

Remove-PathSafe -Path $buildDir
New-Item -ItemType Directory -Force $buildDir | Out-Null

$pathQmake = Try-ResolveTool -Names @("qmake6", "qmake-qt6", "qmake")
$pathMake = Try-ResolveTool -Names @("mingw32-make", "make")

if ((Test-NativeTool -ToolPath $pathQmake -Arguments @("-query")) -and -not [string]::IsNullOrWhiteSpace($pathMake)) {
    Push-Location $buildDir
    try {
        & $pathQmake $projectPath "CONFIG+=$($Configuration.ToLower())" "CONFIG-=debug_and_release"
        if ($LASTEXITCODE -ne 0) {
            throw "qmake failed for $projectPath"
        }

        & $pathMake "-j$([Environment]::ProcessorCount)"
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed in $buildDir"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    $fallbackQt = Resolve-CondaQtPackage
    $toolBin = Resolve-CondaQtToolBin
    $vcvars = Resolve-VcVars
    $nmake = Resolve-NMake
    $mapping = New-WorkspaceMapping -WorkspaceRoot $root

    try {
        $mappedBuildDir = Convert-ToMappedPath -ActualPath $buildDir -WorkspaceRoot $root -MappedRoot $mapping.Root
        $mappedProjectPath = Convert-ToMappedPath -ActualPath $projectPath -WorkspaceRoot $root -MappedRoot $mapping.Root

        $cmdGenerate = 'call "{0}" >nul && cd /d "{1}" && "{2}" "{3}" CONFIG+={4} CONFIG-=debug_and_release' -f
            $vcvars, $mappedBuildDir, $fallbackQt.Qmake, $mappedProjectPath, $Configuration.ToLower()
        & $env:ComSpec /d /c $cmdGenerate
        if ($LASTEXITCODE -ne 0) {
            throw "Fallback qmake generation failed."
        }

        $makefile = Join-Path $buildDir "Makefile"
        $text = Get-Content -Raw -LiteralPath $makefile
        $text = $text.Replace((Join-Path $fallbackQt.BinRoot "rcc.exe"), (Join-Path $toolBin "rcc.exe"))
        $text = $text.Replace((Join-Path $fallbackQt.BinRoot "moc.exe"), (Join-Path $toolBin "moc.exe"))
        $text = $text.Replace((Join-Path $fallbackQt.BinRoot "uic.exe"), (Join-Path $toolBin "uic.exe"))
        Set-Content -LiteralPath $makefile -Value $text -Encoding ASCII

        $cmdBuild = 'call "{0}" >nul && cd /d "{1}" && "{2}"' -f $vcvars, $mappedBuildDir, $nmake
        & $env:ComSpec /d /c $cmdBuild
        if ($LASTEXITCODE -ne 0) {
            throw "Fallback MSVC build failed."
        }
    }
    finally {
        Remove-WorkspaceMapping -Mapping $mapping
    }
}

$exePath = Join-Path $buildDir "$TargetName.exe"
if (-not (Test-Path -LiteralPath $exePath)) {
    $exeCandidate = Get-ChildItem -LiteralPath $buildDir -Filter *.exe -File | Select-Object -First 1
    if ($null -eq $exeCandidate) {
        throw "Build completed but no executable was found in $buildDir"
    }
    $exePath = $exeCandidate.FullName
}

Write-Output "BUILD_DIR=$buildDir"
Write-Output "EXE_PATH=$exePath"
