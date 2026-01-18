#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$AppName = "omni"
$GithubRepo = "edgeleap/omni"
$DownloadBase = "https://github.com/$GithubRepo/releases/latest/download"

Write-Host "Installing $AppName..." -ForegroundColor Cyan
Write-Host ""

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

# Build artifact name
$Artifact = "$AppName-windows-$ArchName.zip"
$Url = "$DownloadBase/$Artifact"

Write-Host "-> Downloading from: $Url"

# Install directory
$InstallDir = "$env:LOCALAPPDATA\Programs\$AppName"

# Create temp directory
$TmpDir = New-Item -ItemType Directory -Path "$env:TEMP\$AppName-install-$(Get-Random)" -Force

try {
    # Download
    $ZipPath = "$TmpDir\$AppName.zip"
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing

    # Extract
    Write-Host "-> Extracting..."
    Expand-Archive -Path $ZipPath -DestinationPath $TmpDir -Force

    # Install
    Write-Host "-> Installing to $InstallDir..."
    
    # Remove old version if exists
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    
    # Move all extracted files
    Get-ChildItem -Path $TmpDir -Exclude "*.zip" | Move-Item -Destination $InstallDir -Force

    # Add to PATH for current user (if not already)
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable(
            "Path", 
            "$UserPath;$InstallDir", 
            "User"
        )
        Write-Host "-> Added to PATH"
    }

    Write-Host ""
    Write-Host "Installed to $InstallDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "Restart your terminal, then run: $AppName" -ForegroundColor Yellow
    Write-Host "Or open from: $InstallDir\$AppName.exe"
    
} finally {
    # Cleanup
    Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
