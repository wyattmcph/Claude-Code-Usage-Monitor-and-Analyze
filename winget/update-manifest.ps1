#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the winget manifest with the latest Claude Monitor binary hash and metadata.

.DESCRIPTION
    This script downloads the latest Claude Monitor Windows binary from GitHub releases,
    calculates its SHA256 hash, and updates the winget manifest files accordingly.

.PARAMETER Version
    The version to update. If not provided, uses the latest release from GitHub.

.PARAMETER BinaryPath
    Path to a local binary file. If provided, uses this file instead of downloading.

.EXAMPLE
    # Update to latest version from GitHub
    .\update-manifest.ps1

    # Update to a specific version
    .\update-manifest.ps1 -Version 3.5.0

    # Use a local binary file
    .\update-manifest.ps1 -BinaryPath "C:\path\to\claude-monitor-windows.exe"

.NOTES
    Requires PowerShell 5.0+ and internet connectivity to fetch release information.
    The script preserves other manifest content while updating hash and URLs.
#>

[CmdletBinding()]
param(
    [string]$Version,
    [string]$BinaryPath
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $SuccessColor
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $ErrorColor
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $InfoColor
}

Write-Info "Claude Monitor winget Manifest Updater"
Write-Info "======================================="
Write-Host ""

# Determine version and binary path
if ($BinaryPath) {
    if (-not (Test-Path $BinaryPath)) {
        Write-Error-Custom "Binary file not found: $BinaryPath"
        exit 1
    }
    $Version = if ($Version) { $Version } else { "local" }
    Write-Info "Using local binary: $BinaryPath"
} else {
    # Fetch latest release if version not specified
    if (-not $Version) {
        Write-Info "Fetching latest release from GitHub..."
        try {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/wyattmcph/wyattmcph-claude-monitor/releases" -ErrorAction Stop
            $latest = $releases | Where-Object { -not $_.prerelease -and -not $_.draft } | Select-Object -First 1

            if (-not $latest) {
                Write-Error-Custom "No published releases found"
                exit 1
            }

            $Version = $latest.tag_name -replace '^v', ''
            Write-Success "Latest version: $Version"
        } catch {
            Write-Error-Custom "Failed to fetch releases: $_"
            exit 1
        }
    }

    # Download the binary
    Write-Info "Downloading binary for version $Version..."
    $DownloadUrl = "https://github.com/wyattmcph/wyattmcph-claude-monitor/releases/download/v$Version/claude-monitor-windows.exe"
    $BinaryPath = "$env:TEMP\claude-monitor-windows-$Version.exe"

    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $BinaryPath -ErrorAction Stop | Out-Null
        Write-Success "Binary downloaded to: $BinaryPath"
    } catch {
        Write-Error-Custom "Failed to download binary: $_"
        exit 1
    }
}

# Calculate SHA256 hash
Write-Info "Calculating SHA256 hash..."
try {
    $hash = (Get-FileHash -Path $BinaryPath -Algorithm SHA256 -ErrorAction Stop).Hash
    Write-Success "SHA256: $hash"
} catch {
    Write-Error-Custom "Failed to calculate hash: $_"
    exit 1
}

# Get file info
$fileInfo = Get-Item $BinaryPath
$fileSize = "{0:N0}" -f ($fileInfo.Length / 1MB)
Write-Info "File size: $fileSize MB"

# Ensure manifest directory exists
$manifestDir = Join-Path $PSScriptRoot "wyattmcph.ClaudeMonitor" "3.5.0"
if (-not (Test-Path $manifestDir)) {
    Write-Info "Creating manifest directory: $manifestDir"
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
}

# Update installer manifest
$installerPath = Join-Path $manifestDir "wyattmcph.ClaudeMonitor.installer.yaml"
Write-Info "Updating installer manifest..."

try {
    $installerContent = @"
PackageIdentifier: wyattmcph.ClaudeMonitor
PackageVersion: $Version
MinimumOSVersion: 10.0.0.0
InstallerType: portable
Scope: user
InstallModes:
  - interactive
  - silent
UpgradeBehavior: install
ReleaseDate: $(Get-Date -Format "yyyy-MM-dd")
Installers:
  - Architecture: x64
    InstallerUrl: https://github.com/wyattmcph/wyattmcph-claude-monitor/releases/download/v$Version/claude-monitor-windows.exe
    InstallerSha256: $hash
    InstallerLocale: en-US
    ProductCode: wyattmcph-claude-monitor
ManifestType: installer
ManifestVersion: 1.4.0
"@

    Set-Content -Path $installerPath -Value $installerContent -Encoding UTF8
    Write-Success "Installer manifest updated: $installerPath"
} catch {
    Write-Error-Custom "Failed to update installer manifest: $_"
    exit 1
}

# Update root manifest
$rootPath = Join-Path $manifestDir "wyattmcph.ClaudeMonitor.yaml"
Write-Info "Updating root manifest..."

try {
    $rootContent = @"
PackageIdentifier: wyattmcph.ClaudeMonitor
PackageVersion: $Version
DefaultLocale: en-US
ManifestType: metadata
ManifestVersion: 1.4.0
"@

    Set-Content -Path $rootPath -Value $rootContent -Encoding UTF8
    Write-Success "Root manifest updated: $rootPath"
} catch {
    Write-Error-Custom "Failed to update root manifest: $_"
    exit 1
}

# Display next steps
Write-Host ""
Write-Info "Next steps:"
Write-Host "1. Review the updated manifest files in: $manifestDir"
Write-Host "2. Test the manifest locally using winget CLI"
Write-Host "3. Create a pull request to microsoft/winget-pkgs with the updated manifests"
Write-Host ""
Write-Host "Manifest files:"
Get-ChildItem -Path $manifestDir -Filter "*.yaml" | ForEach-Object {
    Write-Host "  - $($_.Name)"
}

Write-Success "Manifest update complete!"
