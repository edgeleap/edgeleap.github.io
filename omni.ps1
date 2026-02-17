#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$AppName = "omni"
$GithubRepo = "edgeleap/omni"
$DownloadBase = "https://github.com/$GithubRepo/releases/latest/download"

Write-Host "Installing $AppName..." -ForegroundColor Cyan
Write-Host ""

# Mode
# - default: installs GUI + CLI
# - --cli: installs CLI-only
$CliOnly = $args -contains "--cli"

if ($CliOnly) {
    Write-Host "-> Mode: CLI-only" -ForegroundColor Yellow
} else {
    Write-Host "-> Mode: GUI + CLI" -ForegroundColor Yellow
}

# Detect architecture
try {
    $Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
} catch {
    # Fallback for older PowerShell
    $Arch = if ([Environment]::Is64BitOperatingSystem) { "X64" } else { "X86" }
}

switch ($Arch) {
    "X64"   { $ArchName = "x64" }
    "Arm64" { $ArchName = "arm64" }
    default {
        Write-Host "Unsupported architecture: $Arch" -ForegroundColor Red
        exit 1
    }
}

Write-Host "-> Detected: Windows ($ArchName)"

# Install directory
$InstallDir = "$env:LOCALAPPDATA\Programs\$AppName"

# Create temp directory
$TmpDir = New-Item -ItemType Directory -Path "$env:TEMP\$AppName-install-$(Get-Random)" -Force

function Add-ToUserPathIfMissing($PathToAdd) {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$PathToAdd*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$UserPath;$PathToAdd",
            "User"
        )
        Write-Host "-> Added to PATH" -ForegroundColor Cyan
    }
}

function Download-AndExtractZip($Url, $DestDir) {
    $zipName = [IO.Path]::GetFileName($Url)
    $zipPath = Join-Path $TmpDir $zipName
    Write-Host "-> Downloading from: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $zipPath -UseBasicParsing
    Write-Host "-> Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $DestDir -Force
}

try {
    # Ensure install dir
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    if ($CliOnly) {
        # CLI-only
        $CliArtifact = "$AppName-cli-windows-$ArchName.zip"
        $CliUrl = "$DownloadBase/$CliArtifact"
        Download-AndExtractZip $CliUrl $InstallDir

        # Expect omni.exe inside the zip (packaged that way by release.yml)
        $CliExe = Join-Path $InstallDir "$AppName.exe"
        if (!(Test-Path $CliExe)) {
            Write-Host "Expected CLI executable not found: $CliExe" -ForegroundColor Red
            exit 1
        }

        Add-ToUserPathIfMissing $InstallDir

        Write-Host "";
        Write-Host "Installed CLI to $InstallDir" -ForegroundColor Green
        Write-Host "Restart your terminal, then run: $AppName --help" -ForegroundColor Yellow

    } else {
        # GUI + CLI
        $GuiArtifact = "$AppName-windows-$ArchName.zip"
        $GuiUrl = "$DownloadBase/$GuiArtifact"
        Download-AndExtractZip $GuiUrl $InstallDir

        # Also install CLI (same install dir; no shim required)
        $CliArtifact = "$AppName-cli-windows-$ArchName.zip"
        $CliUrl = "$DownloadBase/$CliArtifact"
        Download-AndExtractZip $CliUrl $InstallDir

        Add-ToUserPathIfMissing $InstallDir

        Write-Host "";
        Write-Host "Installed to $InstallDir" -ForegroundColor Green
        Write-Host "";
        Write-Host "Restart your terminal, then run: $AppName --help" -ForegroundColor Yellow
        Write-Host "Open GUI from Start Menu (or run the installed GUI exe in $InstallDir)." -ForegroundColor Yellow
    }

} finally {
    # Cleanup
    Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "";
Write-Host "Done!" -ForegroundColor Green
