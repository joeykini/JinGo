#!/usr/bin/env pwsh
<#
.SYNOPSIS
    JinGoVPN Windows Deployment Script

.DESCRIPTION
    Deploy Windows application as MSI/ZIP installer

.PARAMETER Version
    Version number (e.g., 1.0.0)

.PARAMETER Msi
    Create MSI installer (requires WiX Toolset)

.PARAMETER Zip
    Create ZIP package

.PARAMETER All
    Create all formats

.PARAMETER SkipBuild
    Skip build step (use existing build)

.EXAMPLE
    .\deploy-windows.ps1 -All -Version 1.0.0
    .\deploy-windows.ps1 -Zip -Version 1.0.0
    .\deploy-windows.ps1 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Version = "1.0.0",

    [switch]$Msi,
    [switch]$Zip,
    [switch]$All,
    [switch]$SkipBuild
)

# Set error action
$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\..\.."
$BuildDir = Join-Path $ProjectRoot "build-windows\bin"
$PkgDir = Join-Path $ProjectRoot "pkg"
$WixSource = Join-Path $ProjectRoot "scripts\deploy\wix"

# If only version provided as positional parameter, default to MSI
if ($PSBoundParameters.Count -eq 1 -and $PSBoundParameters.ContainsKey('Version')) {
    $Msi = $true
    $SkipBuild = $true
}

# If -All specified, enable both formats
if ($All) {
    $Msi = $true
    $Zip = $true
}

# Default to skip build (use existing build)
if (-not $PSBoundParameters.ContainsKey('SkipBuild')) {
    $SkipBuild = $true
}

# ============================================================================
# Validation
# ============================================================================

Write-Host ""
Write-Host "=" * 50
Write-Host "     JinGoVPN Windows Deployment"
Write-Host "=" * 50
Write-Host "Version:      $Version"
Write-Host "Build Dir:    $BuildDir"
Write-Host "Deploy Dir:   $PkgDir"
Write-Host "=" * 50
Write-Host ""

# Check if at least one format is selected
if (-not $Msi -and -not $Zip) {
    Write-Host "[ERROR] Please specify at least one deployment target: -Msi, -Zip, or -All" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage examples:"
    Write-Host "  .\deploy-windows.ps1 -All -Version 1.0.0"
    Write-Host "  .\deploy-windows.ps1 -Zip -Version 1.0.0"
    Write-Host "  .\deploy-windows.ps1 1.0.0"
    exit 1
}

# Parse version number
if ($Version -match '^(\d+)\.(\d+)\.(\d+)$') {
    $VersionMajor = $Matches[1]
    $VersionMinor = $Matches[2]
    $VersionPatch = $Matches[3]
} else {
    Write-Host "[ERROR] Invalid version format. Use X.Y.Z (e.g., 1.0.0)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# [1/5] Check Required Tools
# ============================================================================

Write-Host "[1/5] Checking required tools..." -ForegroundColor Cyan
Write-Host ""

# Check build output
$ExePath = Join-Path $BuildDir "JinGo.exe"
if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] JinGo.exe not found: $ExePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the project first:"
    Write-Host "  scripts\build\build-windows_mingw.bat"
    Write-Host ""
    exit 1
}
Write-Host "[OK] Found build output: JinGo.exe" -ForegroundColor Green

# Check WiX (if creating MSI)
if ($Msi) {
    $candleExists = Get-Command candle.exe -ErrorAction SilentlyContinue

    # If not in PATH, try to find WiX installation
    if (-not $candleExists) {
        Write-Host "Searching for WiX Toolset installation..." -ForegroundColor Cyan

        $wixPaths = @(
            "C:\Program Files (x86)\WiX Toolset v3.14\bin",
            "C:\Program Files (x86)\WiX Toolset v3.11\bin",
            "C:\Program Files (x86)\WiX Toolset v4.0\bin",
            "C:\Program Files\WiX Toolset v3.14\bin",
            "C:\Program Files\WiX Toolset v3.11\bin",
            "C:\Program Files\WiX Toolset v4.0\bin"
        )

        foreach ($wixPath in $wixPaths) {
            if (Test-Path (Join-Path $wixPath "candle.exe")) {
                Write-Host "Found WiX at: $wixPath" -ForegroundColor Green
                $env:Path += ";$wixPath"
                $candleExists = $true
                break
            }
        }

        # Try wildcard search as last resort
        if (-not $candleExists) {
            $wixInstall = Get-ChildItem "C:\Program Files (x86)\WiX Toolset*\bin\candle.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($wixInstall) {
                $wixBinPath = Split-Path $wixInstall.FullName
                Write-Host "Found WiX at: $wixBinPath" -ForegroundColor Green
                $env:Path += ";$wixBinPath"
                $candleExists = $true
            }
        }
    }

    if (-not $candleExists) {
        Write-Host "[WARNING] WiX Toolset not found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Cannot create MSI installer. Please install WiX Toolset:"
        Write-Host "  Download: https://wixtoolset.org/"
        Write-Host "  Or use: winget install WiX.Toolset"
        Write-Host ""
        $Msi = $false
    } else {
        Write-Host "[OK] WiX Toolset available" -ForegroundColor Green
    }
}

Write-Host ""

# ============================================================================
# [2/5] Build Application
# ============================================================================

if ($SkipBuild) {
    Write-Host "[2/5] Skipping build step" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "[2/5] Building application..." -ForegroundColor Cyan
    Write-Host ""

    $BuildScript = Join-Path $ScriptDir "..\build\build-windows_mingw.bat"
    if (Test-Path $BuildScript) {
        & cmd /c $BuildScript
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Build failed" -ForegroundColor Red
            exit 1
        }
        Write-Host "[OK] Build completed" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Build script not found, using existing build" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ============================================================================
# [3/5] Create Deployment Directory
# ============================================================================

Write-Host "[3/5] Creating deployment directory..." -ForegroundColor Cyan
Write-Host ""

$DeployDir = Join-Path $PkgDir "JinGo-$Version"

if (Test-Path $DeployDir) {
    Write-Host "Cleaning existing deployment directory..."
    Remove-Item -Path $DeployDir -Recurse -Force
}

New-Item -ItemType Directory -Path $PkgDir -Force | Out-Null
New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null

Write-Host "[OK] Deployment directory created: $DeployDir" -ForegroundColor Green
Write-Host ""

# ============================================================================
# [4/5] Copy Application Files
# ============================================================================

Write-Host "[4/5] Copying application files..." -ForegroundColor Cyan
Write-Host ""

# Copy main executable
Write-Host "  - JinGo.exe"
Copy-Item -Path (Join-Path $BuildDir "JinGo.exe") -Destination $DeployDir

# Copy all DLLs
Write-Host "  - DLL files"
Get-ChildItem -Path $BuildDir -Filter "*.dll" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $DeployDir
}

# Copy Qt plugins and resources
@("bearer", "iconengines", "imageformats", "platforms", "styles", "translations", "tls", "qml") | ForEach-Object {
    $PluginDir = Join-Path $BuildDir $_
    if (Test-Path $PluginDir) {
        Write-Host "  - $_\"
        Copy-Item -Path $PluginDir -Destination $DeployDir -Recurse
    }
}

# Copy GeoIP data
$DatDir = Join-Path $BuildDir "dat"
if (Test-Path $DatDir) {
    Write-Host "  - dat\ (GeoIP data)"
    Copy-Item -Path $DatDir -Destination $DeployDir -Recurse
}

Write-Host "[OK] All files copied" -ForegroundColor Green
Write-Host ""

# ============================================================================
# [5/5] Create Installer Packages
# ============================================================================

Write-Host "[5/5] Creating installer packages..." -ForegroundColor Cyan
Write-Host ""

# Create ZIP Package
if ($Zip) {
    Write-Host "Creating ZIP package..."

    $ZipFile = Join-Path $PkgDir "JinGoVPN-$Version-Windows.zip"

    if (Test-Path $ZipFile) {
        Remove-Item -Path $ZipFile -Force
    }

    Compress-Archive -Path "$DeployDir\*" -DestinationPath $ZipFile -Force

    if (Test-Path $ZipFile) {
        $ZipSize = (Get-Item $ZipFile).Length
        Write-Host "[OK] ZIP created: JinGoVPN-$Version-Windows.zip" -ForegroundColor Green
        Write-Host "     Size: $ZipSize bytes"
        Write-Host "     Path: $ZipFile"
    } else {
        Write-Host "[ERROR] ZIP creation failed" -ForegroundColor Red
    }
    Write-Host ""
}

# Create MSI Package
if ($Msi) {
    Write-Host "Creating MSI installer..."
    Write-Host ""

    # Create WiX source directory
    if (-not (Test-Path $WixSource)) {
        New-Item -ItemType Directory -Path $WixSource -Force | Out-Null
    }

    # Generate unique GUIDs
    $ProductGuid = [guid]::NewGuid().ToString().ToUpper()
    $UpgradeGuid = [guid]::NewGuid().ToString().ToUpper()

    Write-Host "  Product GUID: $ProductGuid"
    Write-Host "  Upgrade GUID: $UpgradeGuid"
    Write-Host ""

    # Create WiX source file
    $WixContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="$ProductGuid"
           Name="JinGo VPN"
           Language="1033"
           Version="$VersionMajor.$VersionMinor.$VersionPatch.0"
           Manufacturer="JinGo Team"
           UpgradeCode="$UpgradeGuid">

    <Package InstallerVersion="200"
             Compressed="yes"
             InstallScope="perMachine"
             Description="JinGo VPN Installer"
             Comments="VPN client based on Xray-core" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of JinGo VPN is already installed." />
    <MediaTemplate EmbedCab="yes" />

    <Feature Id="ProductFeature" Title="JinGo VPN" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
      <ComponentRef Id="ApplicationShortcut" />
    </Feature>

    <UIRef Id="WixUI_InstallDir" />
    <Property Id="WIXUI_INSTALLDIR" Value="INSTALLFOLDER" />

  </Product>

  <Fragment>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="JinGo VPN" />
      </Directory>
      <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="JinGo VPN"/>
      </Directory>
    </Directory>
  </Fragment>

  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <Component Id="JinGoExe" Guid="*">
        <File Source="$DeployDir\JinGo.exe" KeyPath="yes">
          <Shortcut Id="JinGoShortcut" Directory="ApplicationProgramsFolder"
                    Name="JinGo VPN" Description="Launch JinGo VPN"
                    WorkingDirectory="INSTALLFOLDER" Advertise="yes" />
        </File>
      </Component>
    </ComponentGroup>

    <Component Id="ApplicationShortcut" Directory="ApplicationProgramsFolder" Guid="*">
      <RemoveFolder Id="ApplicationProgramsFolder" On="uninstall"/>
      <RegistryValue Root="HKCU" Key="Software\JinGo\JinGo VPN"
                     Name="installed" Type="integer" Value="1" KeyPath="yes"/>
    </Component>
  </Fragment>
</Wix>
"@

    $WixFile = Join-Path $WixSource "JinGo.wxs"
    Set-Content -Path $WixFile -Value $WixContent -Encoding UTF8

    Write-Host "  WiX source file generated"
    Write-Host ""

    # Compile WiX source
    Write-Host "  Compiling WiX source..."
    $WixObj = Join-Path $WixSource "JinGo.wixobj"
    & candle.exe $WixFile -dSourceDir="$DeployDir" -dVersion="$Version" -out $WixObj -arch x64 -ext WixUIExtension 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ERROR] Candle compilation failed" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Compilation successful" -ForegroundColor Green
        Write-Host ""

        # Link MSI
        $MsiOutput = Join-Path $PkgDir "JinGoVPN-$Version-Windows.msi"

        Write-Host "  Linking MSI installer..."
        & light.exe $WixObj -out $MsiOutput -ext WixUIExtension -b $DeployDir -spdb -sval 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [ERROR] Light linking failed" -ForegroundColor Red
        } elseif (Test-Path $MsiOutput) {
            $MsiSize = (Get-Item $MsiOutput).Length
            Write-Host "  [OK] MSI created: JinGoVPN-$Version-Windows.msi" -ForegroundColor Green
            Write-Host "       Size: $MsiSize bytes"
            Write-Host "       Path: $MsiOutput"
        } else {
            Write-Host "  [ERROR] MSI file not generated" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "=" * 50
Write-Host "          Deployment Complete"
Write-Host "=" * 50
Write-Host ""
Write-Host "Generated packages:"
Get-ChildItem -Path $PkgDir -Filter "JinGoVPN-$Version-*.zip" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  - $($_.Name)"
}
Get-ChildItem -Path $PkgDir -Filter "JinGoVPN-$Version-*.msi" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  - $($_.Name)"
}
Write-Host ""
Write-Host "Deployment directory: $DeployDir"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Test the installer packages"
if ($Msi) {
    Write-Host "     - Double-click MSI file to install"
}
if ($Zip) {
    Write-Host "     - Extract ZIP and run JinGo.exe"
}
Write-Host ""
Write-Host "  2. Sign the packages (optional):"
Write-Host "     signtool sign /a /t http://timestamp.digicert.com [file]"
Write-Host ""
Write-Host "  3. Distribute the packages"
Write-Host ""
Write-Host "=" * 50
