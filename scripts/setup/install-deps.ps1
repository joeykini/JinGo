#!/usr/bin/env pwsh
<#
.SYNOPSIS
    JinGo VPN - Windows Dependency Installation Script

.DESCRIPTION
    Install build dependencies for Windows

.EXAMPLE
    .\install-deps.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=" * 42
Write-Host "   JinGo VPN Windows Dependencies Setup"
Write-Host "=" * 42
Write-Host ""

# Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[WARNING] It's recommended to run this script as Administrator" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# Check/Install Chocolatey
# ============================================================================

Write-Host "Checking Chocolatey..." -ForegroundColor Cyan

$chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
if (-not $chocoInstalled) {
    Write-Host "[INFO] Installing Chocolatey..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "[SUCCESS] Chocolatey installed" -ForegroundColor Green
} else {
    Write-Host "[SUCCESS] Chocolatey already installed" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# Install Dependencies
# ============================================================================

Write-Host "[INFO] Installing build dependencies..." -ForegroundColor Cyan
Write-Host ""

function Refresh-EnvironmentPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Install-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string]$ChocoPackage
    )

    $toolExists = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $toolExists) {
        Write-Host "[INFO] Installing $Name..."
        choco install $ChocoPackage -y

        # Refresh environment variables after installation
        Refresh-EnvironmentPath

        # Check again after refresh
        $toolExists = Get-Command $Command -ErrorAction SilentlyContinue
        if ($toolExists) {
            Write-Host "[SUCCESS] $Name installed successfully" -ForegroundColor Green
        }
    } else {
        Write-Host "[SUCCESS] $Name already installed" -ForegroundColor Green
    }
}

# CMake
Install-Tool -Name "CMake" -Command "cmake" -ChocoPackage "cmake --installargs 'ADD_CMAKE_TO_PATH=System'"

# Ninja
Install-Tool -Name "Ninja" -Command "ninja" -ChocoPackage "ninja"

# Git
Install-Tool -Name "Git" -Command "git" -ChocoPackage "git"

# Go
Install-Tool -Name "Go" -Command "go" -ChocoPackage "golang"

# jq
Install-Tool -Name "jq" -Command "jq" -ChocoPackage "jq"

# WiX Toolset (for creating MSI installers)
Write-Host "Checking WiX Toolset..." -ForegroundColor Cyan
$candleExists = Get-Command candle -ErrorAction SilentlyContinue
if (-not $candleExists) {
    Write-Host "[INFO] Installing WiX Toolset..."
    choco install wixtoolset -y

    # Refresh environment variables
    Refresh-EnvironmentPath

    # Check again
    $candleExists = Get-Command candle -ErrorAction SilentlyContinue
    if ($candleExists) {
        Write-Host "[SUCCESS] WiX Toolset installed successfully" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] WiX Toolset installed but not yet in PATH" -ForegroundColor Yellow
        Write-Host "[INFO] Please restart PowerShell/CMD to refresh environment variables" -ForegroundColor Cyan
    }
} else {
    Write-Host "[SUCCESS] WiX Toolset already installed" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# Check MinGW
# ============================================================================

Write-Host "Checking MinGW..." -ForegroundColor Cyan

$gppExists = Get-Command g++ -ErrorAction SilentlyContinue
if (-not $gppExists) {
    Write-Host "[WARNING] MinGW compiler not detected" -ForegroundColor Yellow
    Write-Host "[INFO] MinGW is typically installed with Qt"
    Write-Host "[INFO] Or download from: https://www.mingw-w64.org/"
} else {
    Write-Host "[SUCCESS] MinGW compiler found" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# Check Qt
# ============================================================================

Write-Host "Checking Qt (MinGW version)..." -ForegroundColor Cyan

if (-not $env:QT_DIR) {
    $qtPaths = @("D:\Qt", "C:\Qt")
    $qtFound = $false

    foreach ($path in $qtPaths) {
        if (Test-Path $path) {
            Write-Host "[SUCCESS] Qt directory exists: $path" -ForegroundColor Green
            $qtFound = $true
            break
        }
    }

    if (-not $qtFound) {
        Write-Host "[WARNING] Qt not detected" -ForegroundColor Yellow
        Write-Host "[INFO] Please install Qt 6.5+ with MinGW from https://www.qt.io/download"
        Write-Host "[INFO] During installation, select 'MinGW 64-bit' component"
        Write-Host "[INFO] After installation, set environment variable:"
        Write-Host "[INFO]   `$env:QT_DIR='D:\Qt\6.x.x\mingw_64'"
    }
} else {
    Write-Host "[SUCCESS] QT_DIR configured: $env:QT_DIR" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# Dependency Status Check
# ============================================================================

Write-Host "=" * 42
Write-Host "       Dependency Status Check"
Write-Host "=" * 42
Write-Host ""

function Test-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string[]]$Args = @("--version")
    )

    try {
        $toolExists = Get-Command $Command -ErrorAction SilentlyContinue
        if ($toolExists) {
            Write-Host "[SUCCESS] $Name is ready" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] $Name not installed or not in PATH" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] $Name not installed or not in PATH" -ForegroundColor Red
    }
}

# CMake
cmake --version 2>&1 | Select-Object -First 1 | Write-Host
Test-Tool -Name "CMake" -Command "cmake"

# Go
go version 2>&1 | Write-Host
Test-Tool -Name "Go" -Command "go" -Args @("version")

# Ninja
ninja --version 2>&1 | Write-Host
Test-Tool -Name "Ninja" -Command "ninja"

# WiX Toolset
try {
    $candleExists = Get-Command candle.exe -ErrorAction SilentlyContinue
    if ($candleExists) {
        $candleVer = & candle.exe -? 2>&1 | Select-String "version" | Select-Object -First 1
        if ($candleVer) {
            Write-Host $candleVer
        }
        Write-Host "[SUCCESS] WiX Toolset is ready" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] WiX Toolset not installed or not in PATH" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] WiX Toolset not installed or not in PATH" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 42
Write-Host "     Dependency Installation Complete"
Write-Host "=" * 42
Write-Host ""
Write-Host "IMPORTANT: Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. CLOSE this PowerShell/CMD window" -ForegroundColor Cyan
Write-Host "  2. OPEN a NEW PowerShell/CMD window" -ForegroundColor Cyan
Write-Host "     (This is required to load updated environment variables)" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Run build script:" -ForegroundColor Cyan
Write-Host "     scripts\build\build-windows-wrapper.bat"
Write-Host ""
Write-Host "  4. Create deployment package:" -ForegroundColor Cyan
Write-Host "     scripts\deploy\deploy-windows-wrapper.bat -Zip -Version 1.0.0"
Write-Host ""
Write-Host "=" * 42
Write-Host ""

Read-Host "Press Enter to close this window..."
