# Windows Package Manager (winget) Submission Guide

This directory contains the winget package manifest for Claude Monitor.

## Overview

Claude Monitor is registered in the Windows Package Manager Community Repository under the package identifier `wyattmcph.ClaudeMonitor`.

## Manifest Structure

The manifest is organized following winget's standard structure:

```
winget/
└── wyattmcph.ClaudeMonitor/
    └── 3.5.0/
        ├── wyattmcph.ClaudeMonitor.yaml              (metadata)
        ├── wyattmcph.ClaudeMonitor.installer.yaml    (installer details)
        └── wyattmcph.ClaudeMonitor.locale.en-US.yaml (description & release notes)
```

## Updating the Manifest for New Releases

When a new version of Claude Monitor is released:

### 1. Calculate the Windows Binary Hash

After the GitHub Release is created with `claude-monitor-windows.exe`:

**On PowerShell:**
```powershell
$hash = (Get-FileHash -Path "path\to\claude-monitor-windows.exe" -Algorithm SHA256).Hash
Write-Host $hash
```

**On macOS/Linux:**
```bash
sha256sum claude-monitor-windows.exe
# or
shasum -a 256 claude-monitor-windows.exe
```

**Alternatively, using Python:**
```python
import hashlib
with open("claude-monitor-windows.exe", "rb") as f:
    print(hashlib.sha256(f.read()).hexdigest())
```

### 2. Create a New Version Directory

Create a new directory with the new version number:
```
winget/wyattmcph.ClaudeMonitor/{NEW_VERSION}/
```

### 3. Copy and Update Manifest Files

Copy the three YAML files from the previous version and update:

**wyattmcph.ClaudeMonitor.yaml:**
```yaml
PackageVersion: {NEW_VERSION}
```

**wyattmcph.ClaudeMonitor.installer.yaml:**
```yaml
PackageVersion: {NEW_VERSION}
ReleaseDate: {RELEASE_DATE}  # Format: YYYY-MM-DD
Installers:
  - Architecture: x64
    InstallerUrl: https://github.com/wyattmcph/wyattmcph-claude-monitor/releases/download/v{NEW_VERSION}/claude-monitor-windows.exe
    InstallerSha256: {CALCULATED_SHA256_HASH}
```

**wyattmcph.ClaudeMonitor.locale.en-US.yaml:**
```yaml
PackageVersion: {NEW_VERSION}
ReleaseNotes: |
  [Add release notes from CHANGELOG.md]
ReleaseNotesUrl: https://github.com/wyattmcph/wyattmcph-claude-monitor/releases/tag/v{NEW_VERSION}
```

### 4. Validate the Manifests

Use the Windows Package Manager schema validator:

**Install winget-cli (if not already installed):**
```powershell
winget install Microsoft.DesktopApp.Installer
```

**Validate manifests:**
```powershell
# Download the schema validator
$schema = "https://aka.ms/winget-manifest.schema.json"

# Validate each file (requires a JSON validator like jq or PowerShell JSON parsing)
```

Or validate through the [winget JSON Schema](https://json.schemastore.org/winget-manifest.schema.json).

### 5. Submit to Windows Package Manager Community Repository

The manifest is now ready to be submitted to the Windows Package Manager Community Repository.

**Option A: Automated Submission (via GitHub Actions)**

Create a GitHub Actions workflow in your repository that:
1. Builds the binaries
2. Calculates the SHA256 hash
3. Updates the winget manifest
4. Creates a pull request to the `microsoft/winget-pkgs` repository

**Option B: Manual Submission**

1. Fork the [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs) repository
2. Clone your fork locally
3. Add the manifest files to: `manifests/w/wyattmcph/ClaudeMonitor/{NEW_VERSION}/`
4. Test the manifest with the Windows Package Manager
5. Create a pull request following the repository guidelines

**Example Directory Structure for PR:**
```
manifests/
└── w/
    └── wyattmcph/
        └── ClaudeMonitor/
            └── 3.5.0/
                ├── wyattmcph.ClaudeMonitor.yaml
                ├── wyattmcph.ClaudeMonitor.installer.yaml
                └── wyattmcph.ClaudeMonitor.locale.en-US.yaml
```

## Installation via winget

Once approved and published in the community repository, users can install Claude Monitor using:

```powershell
winget install wyattmcph.ClaudeMonitor
```

Or with a specific version:

```powershell
winget install wyattmcph.ClaudeMonitor --version 3.5.0
```

## Manifest Schema Reference

- [Microsoft winget Manifest Schema](https://github.com/microsoft/winget-cli/tree/master/schemas)
- [winget Documentation](https://docs.microsoft.com/en-us/windows/package-manager/)
- [Community Repository Guidelines](https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md)

## Troubleshooting

### Invalid Manifest
If you encounter validation errors:
1. Check for YAML syntax errors (indentation, quotes)
2. Ensure all required fields are present
3. Verify URLs are correct and accessible
4. Double-check the SHA256 hash format (should be 64 hex characters)

### Hash Mismatch
If the installed binary doesn't match the manifest hash:
1. Re-download the binary from the GitHub release
2. Recalculate the SHA256 hash
3. Update the manifest with the new hash

### Network Issues
If winget can't download the installer:
1. Verify the GitHub release URL is public
2. Test the URL in a browser
3. Check that the binary file hasn't moved or been deleted

## Future Updates

The manifest should be updated for each new release. Consider automating this process through a GitHub Actions workflow that:
1. Monitors releases
2. Calculates the hash automatically
3. Updates the manifest
4. Creates a PR to winget-pkgs

This keeps the package fresh and ensures users get the latest version automatically.
