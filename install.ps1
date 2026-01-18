#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$AppName = "omni"
$GithubRepo = "edgeleap/omni"
$DownloadBase = "https://github.com/$GithubRepo/releases/latest/download"

Write-Host ""
Write-Host "==> Omni Installer" -ForegroundColor Cyan
Write-Host ""

# Detect architecture
$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
switch ($Arch) {
    "X64"   { $Target = "x64" }
    "Arm64" { $Target = "arm64" }
    default { 
        Write-Host "Error: Unsupported architecture: $Arch" -ForegroundColor Red
        exit 1
    }
}

$Artifact = "$AppName-windows-$Target"
$Url = "$DownloadBase/$Artifact.zip"
$InstallDir = "$env:LOCALAPPDATA\Programs\Omni"

Write-Host "--> Detected: Windows ($Target)"
Write-Host "--> Downloading: $Url"

# Create temp directory
$TmpDir = New-Item -ItemType Directory -Path "$env:TEMP\omni-install-$(Get-Random)" -Force

try {
    # Download
    $ZipPath = "$TmpDir\$Artifact.zip"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
    } catch {
        Write-Host "Error: Download failed. Check your internet connection." -ForegroundColor Red
        exit 1
    }

    # Extract
    Write-Host "--> Extracting..."
    Expand-Archive -Path $ZipPath -DestinationPath $TmpDir -Force

    # Install
    Write-Host "--> Installing to $InstallDir..."
    
    # Remove old version if exists
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    
    # Move extracted contents
    Get-ChildItem -Path $TmpDir -Exclude "*.zip" | Move-Item -Destination $InstallDir -Force

    # Add to PATH for current user
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "--> Added to PATH"
    }

    Write-Host ""
    Write-Host "[OK] Installed to $InstallDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "     Restart your terminal, then run: omni" -ForegroundColor Gray
    Write-Host "     Or open from Start Menu" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Done!" -ForegroundColor Green

} finally {
    # Cleanup
    Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
