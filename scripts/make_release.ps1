Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$root = Split-Path -Parent $PSScriptRoot
$deployRoot = Join-Path $root "dist\native"
$releaseRoot = Join-Path $root "release"
$projectFile = Join-Path $root "pyproject.toml"
$version = ([regex]::Match((Get-Content -Raw $projectFile), '(?m)^version\s*=\s*"([^"]+)"$')).Groups[1].Value

if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Unable to resolve project version from pyproject.toml."
}

$packageName = "ComfortCues-$version-windows-x64"
$packageDir = Join-Path $releaseRoot $packageName
$zipPath = Join-Path $releaseRoot ($packageName + ".zip")
$zipHashPath = Join-Path $releaseRoot ($packageName + "-SHA256.txt")
$exeName = "ComfortCues.exe"
$exe = Join-Path $deployRoot $exeName

if (-not (Test-Path $exe)) {
    throw "Missing dist\native\ComfortCues.exe. Run scripts\deploy_native.ps1 first."
}

if (Test-Path $packageDir) {
    Remove-Item -Recurse -Force $packageDir
}

if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

if (Test-Path $zipHashPath) {
    Remove-Item -Force $zipHashPath
}

New-Item -ItemType Directory -Force $packageDir | Out-Null
Copy-Item -Path (Join-Path $deployRoot "*") -Destination $packageDir -Recurse -Force

$readmeLines = @(
    "Comfort Cues",
    "",
    "Version: $version",
    "Platform: Windows x64",
    "Package: Portable native runtime directory",
    "",
    "How to use:",
    "1. Extract the zip to a writable folder.",
    "2. Open the extracted folder and double-click ComfortCues.exe.",
    "3. After first run, the app stays in the system tray by default.",
    "4. Click the tray icon to reopen the main window.",
    "5. Only windowed or borderless-windowed game windows are supported.",
    "",
    "Notes:",
    "- This is a portable build produced from dist\\native. No installer is required.",
    "- User state is stored under %APPDATA%\\Comfort Cues\\.",
    "- If the tray icon is hidden, check the Windows tray overflow menu."
)

Set-Content -Path (Join-Path $packageDir "README.txt") -Value $readmeLines -Encoding UTF8

$hashLines = Get-ChildItem -LiteralPath $packageDir -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($packageDir.Length).TrimStart('\')
        "{0}  {1}" -f $relative, (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLowerInvariant()
    }
Set-Content -Path (Join-Path $packageDir "SHA256.txt") -Value $hashLines -Encoding ASCII

function New-ZipFromDirectory {
    param(
        [string]$SourceDirectory,
        [string]$DestinationZip
    )

    $zip = [System.IO.Compression.ZipFile]::Open($DestinationZip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path
        Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | ForEach-Object {
            $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relative, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
    finally {
        $zip.Dispose()
    }
}

New-ZipFromDirectory -SourceDirectory $packageDir -DestinationZip $zipPath

$zipHash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash.ToLowerInvariant()
Set-Content -Path $zipHashPath -Value ("{0}  {1}" -f (Split-Path -Leaf $zipPath), $zipHash) -Encoding ASCII

Write-Output "PACKAGE_DIR=$packageDir"
Write-Output "PACKAGE_ZIP=$zipPath"
Write-Output "PACKAGE_ZIP_SHA256=$zipHashPath"
