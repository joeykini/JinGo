#!/usr/bin/env pwsh
<#
.SYNOPSIS
    JinGo VPN - Windows MinGW Build Script

.DESCRIPTION
    Build Windows application using MinGW toolchain

.PARAMETER Clean
    Clean build directory before building

.PARAMETER UpdateTranslations
    Run lupdate/lrelease to update translation files before building

.PARAMETER Release
    Build in Release mode (default: Release)

.PARAMETER Debug
    Build in Debug mode

.PARAMETER Brand
    Apply white-label customization from white-labeling/<Brand> directory

.EXAMPLE
    .\build-windows.ps1
    .\build-windows.ps1 -Clean
    .\build-windows.ps1 -Debug
    .\build-windows.ps1 -Brand jingo
#>

[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$DebugBuild,
    [switch]$TranslationsOnly,
    [switch]$UpdateTranslations,
    [string]$Brand = ""
)

# 支持环境变量 BRAND_NAME (优先级: 命令行参数 > 环境变量 > 默认值)
if (-not $Brand -and $env:BRAND_NAME) {
    $Brand = $env:BRAND_NAME
}

$ErrorActionPreference = "Stop"

# ============================================================================
# 环境自动检测函数
# ============================================================================

function Get-QtVersion {
    # 开发环境使用 6.10.0，打包环境使用 6.10.1
    $devPath = "D:\Qt\6.10.0"
    $prodPath = "D:\Qt\6.10.1"

    if (Test-Path $prodPath) {
        return "6.10.1"
    } elseif (Test-Path $devPath) {
        return "6.10.0"
    } else {
        # 搜索最新版本
        $qtBase = "D:\Qt"
        if (Test-Path $qtBase) {
            $versions = Get-ChildItem -Path $qtBase -Directory |
                Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
                Sort-Object { [version]$_.Name } -Descending
            if ($versions.Count -gt 0) {
                return $versions[0].Name
            }
        }
        return "6.10.0"
    }
}

function Get-QtDir {
    # 优先使用环境变量 (GitHub Actions 使用 Qt6_DIR)
    if ($env:Qt6_DIR -and (Test-Path $env:Qt6_DIR)) {
        return $env:Qt6_DIR
    }
    if ($env:QT_DIR -and (Test-Path $env:QT_DIR)) {
        return $env:QT_DIR
    }

    $qtVersion = Get-QtVersion

    # 搜索路径优先级
    $searchPaths = @(
        "D:\Qt\$qtVersion\mingw_64",
        "C:\Qt\$qtVersion\mingw_64",
        "$env:USERPROFILE\Qt\$qtVersion\mingw_64"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # 通配符搜索
    $qtBases = @("D:\Qt", "C:\Qt", "$env:USERPROFILE\Qt")
    foreach ($base in $qtBases) {
        if (Test-Path $base) {
            $mingwDirs = Get-ChildItem -Path $base -Directory -Recurse -Filter "mingw_64" -ErrorAction SilentlyContinue |
                Where-Object { $_.Parent.Name -match '^\d+\.\d+\.\d+$' } |
                Sort-Object { [version]$_.Parent.Name } -Descending
            if ($mingwDirs.Count -gt 0) {
                return $mingwDirs[0].FullName
            }
        }
    }

    return "D:\Qt\6.10.0\mingw_64"
}

function Get-MinGWDir {
    # 优先使用环境变量
    if ($env:MINGW_DIR -and (Test-Path $env:MINGW_DIR)) {
        return $env:MINGW_DIR
    }

    # 搜索 Qt Tools 目录下的 MinGW
    $qtBases = @("D:\Qt", "C:\Qt", "$env:USERPROFILE\Qt")
    foreach ($base in $qtBases) {
        $toolsPath = Join-Path $base "Tools"
        if (Test-Path $toolsPath) {
            $mingwDirs = Get-ChildItem -Path $toolsPath -Directory -Filter "mingw*_64" -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending
            if ($mingwDirs.Count -gt 0) {
                return $mingwDirs[0].FullName
            }
        }
    }

    return "D:\Qt\Tools\mingw1310_64"
}

function Get-EnvironmentType {
    # 通过 Qt 版本判断环境类型
    $qtVersion = Get-QtVersion
    if ($qtVersion -eq "6.10.1") {
        return "production"
    } else {
        return "development"
    }
}

function Ensure-CMake {
    # 检查 CMake 是否可用，如果不在 PATH 中，尝试添加 Qt Tools 的 CMake
    $cmakeAvailable = $null -ne (Get-Command cmake -ErrorAction SilentlyContinue)

    if (-not $cmakeAvailable) {
        # 尝试查找 Qt Tools 下的 CMake
        $qtCMakePaths = @(
            "D:\Qt\Tools\CMake_64\bin",
            "C:\Qt\Tools\CMake_64\bin",
            "$env:USERPROFILE\Qt\Tools\CMake_64\bin"
        )

        foreach ($path in $qtCMakePaths) {
            if (Test-Path "$path\cmake.exe") {
                Write-Host "[INFO] Adding Qt CMake to PATH: $path" -ForegroundColor Cyan
                $env:Path = "$path;$env:Path"
                return $true
            }
        }

        Write-Host "[ERROR] CMake not found!" -ForegroundColor Red
        Write-Host "Please install CMake:" -ForegroundColor Yellow
        Write-Host "  - Download from: https://cmake.org/download/" -ForegroundColor Yellow
        Write-Host "  - Or install via: winget install Kitware.CMake" -ForegroundColor Yellow
        exit 1
    }

    return $true
}

function Copy-BrandAssets {
    param(
        [string]$BrandId = "1"
    )

    $brandDir = Join-Path $ProjectRoot "white-labeling\$BrandId"
    $resourcesDir = Join-Path $ProjectRoot "resources"

    if (-not (Test-Path $brandDir)) {
        Write-Host "[WARNING] Brand directory not found: $brandDir" -ForegroundColor Yellow
        return $false
    }

    Write-Host "[BRAND] Copying brand assets (Brand: $BrandId)" -ForegroundColor Cyan

    $copiedCount = 0

    # 1. Copy bundle_config.json to resources/
    $srcConfig = Join-Path $brandDir "bundle_config.json"
    $dstConfig = Join-Path $resourcesDir "bundle_config.json"
    if (Test-Path $srcConfig) {
        Copy-Item $srcConfig $dstConfig -Force
        Write-Host "[BRAND] bundle_config.json -> resources/" -ForegroundColor Green
        $copiedCount++
    }

    # 2. Copy icons to resources/icons/
    $srcIcons = Join-Path $brandDir "icons"
    $dstIcons = Join-Path $resourcesDir "icons"
    if (Test-Path $srcIcons) {
        # Copy root level icons (app.png, app.icns, app.ico, logo.png)
        Get-ChildItem -Path $srcIcons -File -Filter "*.png" | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $dstIcons $_.Name) -Force
            Write-Host "[BRAND] icons/$($_.Name) -> resources/icons/" -ForegroundColor Green
            $copiedCount++
        }
        Get-ChildItem -Path $srcIcons -File -Filter "*.ico" | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $dstIcons $_.Name) -Force
            Write-Host "[BRAND] icons/$($_.Name) -> resources/icons/" -ForegroundColor Green
            $copiedCount++
        }
        Get-ChildItem -Path $srcIcons -File -Filter "*.icns" | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $dstIcons $_.Name) -Force
            Write-Host "[BRAND] icons/$($_.Name) -> resources/icons/" -ForegroundColor Green
            $copiedCount++
        }
    }

    # 3. Replace public key in RsaCrypto.cpp
    $srcPubKey = Join-Path $brandDir "license_public_key.pem"
    $rsaCryptoFile = Join-Path $ProjectRoot "src\utils\RsaCrypto.cpp"

    if ((Test-Path $srcPubKey) -and (Test-Path $rsaCryptoFile)) {
        Write-Host "[BRAND] Replacing public key in RsaCrypto.cpp..." -ForegroundColor Cyan

        $newPubKey = Get-Content $srcPubKey -Raw
        $rsaContent = Get-Content $rsaCryptoFile -Raw

        # Replace the public key block using regex
        $pattern = '(?s)(const char\* RsaCrypto::EMBEDDED_PUBLIC_KEY = R"\().*?(\)";)'
        $replacement = "`$1`n$newPubKey`$2"

        $newContent = $rsaContent -replace $pattern, $replacement

        if ($newContent -match "BEGIN PUBLIC KEY") {
            Set-Content -Path $rsaCryptoFile -Value $newContent -NoNewline
            Write-Host "[BRAND] license_public_key.pem -> src/utils/RsaCrypto.cpp" -ForegroundColor Green
            $copiedCount++
        } else {
            Write-Host "[WARNING] Public key replacement failed, keeping original file" -ForegroundColor Yellow
        }
    } elseif (-not (Test-Path $srcPubKey)) {
        Write-Host "[WARNING] Public key file not found: $srcPubKey" -ForegroundColor Yellow
    }

    Write-Host "[BRAND] Brand assets copied ($copiedCount items)" -ForegroundColor Green
    return $true
}

# ============================================================================
# Configuration (自动检测)
# ============================================================================

# Qt MinGW installation path (自动检测)
$QT_DIR = Get-QtDir

# MinGW compiler path (自动检测)
$MINGW_DIR = Get-MinGWDir

# 确保 CMake 可用
Ensure-CMake | Out-Null

# 添加 MinGW 和 Qt 到 PATH（确保编译工具可用）
$env:Path = "$MINGW_DIR\bin;$QT_DIR\bin;$env:Path"

# 显示检测到的环境
$ENV_TYPE = Get-EnvironmentType

# Build type: Debug or Release
$BUILD_TYPE = if ($DebugBuild) { "Debug" } else { "Release" }

# Build directory
$BUILD_DIR = "build-windows"

# Release output directory
$RELEASE_DIR = "release"

# Package temp directory (intermediate)
$PKG_DIR = "pkg"

# Application version
$VERSION = "1.0.0"

# Application name
$APP_NAME = "JinGo"

# --------------------- 输出命名 ---------------------
# 获取构建日期 (YYYYMMDD 格式)
$BUILD_DATE = Get-Date -Format "yyyyMMdd"

# 生成输出文件名: {brand}-{version}-{date}-{platform}.{ext}
function Get-OutputName {
    param(
        [string]$Version = "1.0.0",
        [string]$Extension = ""
    )
    $brand = if ($Brand) { $Brand } else { "jingo" }
    $platform = "windows"

    if ($Extension) {
        return "$brand-$Version-$BUILD_DATE-$platform.$Extension"
    } else {
        return "$brand-$Version-$BUILD_DATE-$platform"
    }
}

# Navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\..\.."
Set-Location $ProjectRoot

Write-Host "=" * 76
Write-Host "JinGo Windows MinGW Build and Package"
Write-Host "=" * 76
Write-Host "Environment: $ENV_TYPE"
Write-Host "Qt Path:    $QT_DIR"
Write-Host "MinGW Path: $MINGW_DIR"
Write-Host "Build Dir:  $BUILD_DIR"
Write-Host "Build Type: $BUILD_TYPE"
if ($Brand) {
    Write-Host "Brand:      $Brand"
}
if ($TranslationsOnly) {
    Write-Host "Mode:       Translations Only"
}
Write-Host "=" * 76
Write-Host ""

# ============================================================================
# 复制白标资源 (默认品牌 1，或指定品牌)
# ============================================================================

# Windows 平台默认使用品牌 1
$brandId = if ($Brand) { $Brand } else { "1" }
Write-Host "[0/4] Copying white-label assets (Brand: $brandId)" -ForegroundColor Cyan
Copy-BrandAssets -BrandId $brandId
Write-Host ""

if ($TranslationsOnly) {
    Write-Host "This script will:"
    Write-Host "  [1/2] Configure CMake (if needed)"
    Write-Host "  [2/2] Build translations"
} else {
    Write-Host "This script will:"
    Write-Host "  [1/4] Configure CMake"
    Write-Host "  [2/4] Build application"
    Write-Host "  [3/4] Deploy dependencies (windeployqt)"
    Write-Host "  [4/4] Create ZIP package"
}
Write-Host ""

# ============================================================================
# [0/4] Clean build directory (if requested)
# ============================================================================

if ($Clean -and (Test-Path $BUILD_DIR)) {
    Write-Host "Cleaning previous build..."
    Remove-Item -Path $BUILD_DIR -Recurse -Force
}

# ============================================================================
# [0.5] Update translations (if requested)
# ============================================================================

if ($UpdateTranslations) {
    Write-Host "[0.5] Updating translations with lupdate/lrelease..." -ForegroundColor Cyan
    
    $lupdate = Join-Path $QT_DIR "bin\lupdate.exe"
    $lrelease = Join-Path $QT_DIR "bin\lrelease.exe"
    
    if (-not (Test-Path $lupdate)) {
        Write-Host "[ERROR] lupdate not found at: $lupdate" -ForegroundColor Red
        exit 1
    }
    
    # Run lupdate to extract strings
    Write-Host "  Running lupdate to extract translatable strings..."
    $tsFiles = @(
        "resources/translations/jingo_zh_CN.ts",
        "resources/translations/jingo_zh_TW.ts",
        "resources/translations/jingo_en_US.ts",
        "resources/translations/jingo_fa_IR.ts",
        "resources/translations/jingo_ru_RU.ts"
    )
    
    & $lupdate -recursive src resources/qml -ts $tsFiles
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] lupdate failed!" -ForegroundColor Red
        exit 1
    }
    
    # Run lrelease to compile .qm files
    Write-Host "  Running lrelease to compile .qm files..."
    & $lrelease $tsFiles
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] lrelease failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Translations updated successfully" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# [1/4] Configure CMake (or [1/2] for translations only)
# ============================================================================

if ($TranslationsOnly) {
    Write-Host "[1/2] Checking CMake configuration..." -ForegroundColor Cyan
    if (-not (Test-Path "$BUILD_DIR/CMakeCache.txt")) {
        Write-Host "CMake not configured yet, configuring now..."

        $cmakeArgs = @(
            "-B", $BUILD_DIR
            "-G", "MinGW Makefiles"
            "-DCMAKE_PREFIX_PATH=$QT_DIR"
            "-DCMAKE_C_COMPILER=$MINGW_DIR\bin\gcc.exe"
            "-DCMAKE_CXX_COMPILER=$MINGW_DIR\bin\g++.exe"
            "-DCMAKE_MAKE_PROGRAM=$MINGW_DIR\bin\mingw32-make.exe"
            "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
        )

        & cmake $cmakeArgs

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "[ERROR] CMake configuration failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[OK] CMake already configured" -ForegroundColor Green
    }
} else {
    Write-Host "[1/4] Configuring CMake with MinGW..." -ForegroundColor Cyan

    $cmakeArgs = @(
        "-B", $BUILD_DIR
        "-G", "MinGW Makefiles"
        "-DCMAKE_PREFIX_PATH=$QT_DIR"
        "-DCMAKE_C_COMPILER=$MINGW_DIR\bin\gcc.exe"
        "-DCMAKE_CXX_COMPILER=$MINGW_DIR\bin\g++.exe"
        "-DCMAKE_MAKE_PROGRAM=$MINGW_DIR\bin\mingw32-make.exe"
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    )

    & cmake $cmakeArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] CMake configuration failed!" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# [2/4] Build application (or [2/2] Build translations only)
# ============================================================================

if ($TranslationsOnly) {
    Write-Host ""
    Write-Host "[2/2] Building translations..." -ForegroundColor Cyan

    & cmake --build $BUILD_DIR --config $BUILD_TYPE --target release_translations

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Translation build failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "=" * 76
    Write-Host "[SUCCESS] Translations built successfully!"
    Write-Host "=" * 76
    Write-Host ""
    Write-Host "Translation files:"
    Get-ChildItem -Path $BUILD_DIR -Filter "*.qm" | ForEach-Object {
        Write-Host "  $($_.Name)"
    }
    Write-Host ""

    exit 0
} else {
    Write-Host ""
    Write-Host "[2/4] Building JinGo with MinGW..." -ForegroundColor Cyan

    & cmake --build $BUILD_DIR --config $BUILD_TYPE -j4

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Build failed!" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# [3/4] Dependencies deployed automatically
# ============================================================================

Write-Host ""
Write-Host "[3/4] Qt dependencies deployed automatically by CMake (windeployqt)" -ForegroundColor Cyan
Write-Host "[OK] All Qt DLLs, plugins, and QML modules copied" -ForegroundColor Green
Write-Host ""

# ============================================================================
# [4/4] Create deployment package
# ============================================================================

Write-Host ""
Write-Host "[4/4] Creating deployment package..." -ForegroundColor Cyan
Write-Host ""

# Set deployment directory
$PKG_TEMP_DIR = Join-Path $PKG_DIR "JinGo-$VERSION"
# 使用统一命名: {brand}-{version}-{date}-{platform}.{ext}
$PACKAGE_NAME = Get-OutputName -Version $VERSION -Extension "zip"

# Create deployment directory
if (Test-Path $PKG_TEMP_DIR) {
    Write-Host "Cleaning existing deployment..."
    Remove-Item -Path $PKG_TEMP_DIR -Recurse -Force
}

New-Item -ItemType Directory -Path $PKG_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $PKG_TEMP_DIR -Force | Out-Null

Write-Host "Copying files to $PKG_TEMP_DIR..."

# Copy main executable
$BUILD_BIN = Join-Path $BUILD_DIR "bin"
Copy-Item -Path (Join-Path $BUILD_BIN "JinGo.exe") -Destination $PKG_TEMP_DIR

# Copy all DLLs from bin directory
# This includes:
#   - Qt DLLs (deployed by windeployqt)
#   - MinGW runtime DLLs (libgcc_s_seh-1.dll, libstdc++-6.dll, libwinpthread-1.dll)
#   - superray.dll, wintun.dll (copied by CMake POST_BUILD)
Write-Host "Copying DLLs from build directory..."
$dllCount = 0
Get-ChildItem -Path $BUILD_BIN -Filter "*.dll" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $PKG_TEMP_DIR
    $dllCount++
}
Write-Host "  ✓ Copied $dllCount DLL files" -ForegroundColor Green

# Copy Qt plugins and QML
$qtDirs = @("bearer", "iconengines", "imageformats", "platforms", "styles", "translations", "tls", "qml")
foreach ($dir in $qtDirs) {
    $sourcePath = Join-Path $BUILD_BIN $dir
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $PKG_TEMP_DIR -Recurse
    }
}

# Copy GeoIP data
$datPath = Join-Path $BUILD_BIN "dat"
if (Test-Path $datPath) {
    Copy-Item -Path $datPath -Destination $PKG_TEMP_DIR -Recurse
}

# Create README
$readmeContent = @"
JinGo VPN - Windows Distribution
================================

Version: $VERSION
Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Platform: Windows 10/11 (64-bit)

Installation
------------
1. Extract all files to a directory
2. Run JinGo.exe

Requirements
------------
- Windows 10 version 1809 or later
- Administrator privileges for VPN functionality

Support
-------
- GitHub: https://github.com/your-repo/JinGo

"@

Set-Content -Path (Join-Path $PKG_TEMP_DIR "README.txt") -Value $readmeContent

Write-Host "Files copied successfully." -ForegroundColor Green
Write-Host ""

# Create ZIP package
Write-Host "Creating ZIP package: $PACKAGE_NAME..."
$zipPath = Join-Path $PKG_DIR $PACKAGE_NAME
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path "$PKG_TEMP_DIR\*" -DestinationPath $zipPath -Force

if (Test-Path $zipPath) {
    Write-Host "[OK] ZIP package created: $PACKAGE_NAME" -ForegroundColor Green
} else {
    Write-Host "[WARNING] ZIP package creation failed" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# [4.5/5] Create MSI installer (if WiX 6.0 available)
# ============================================================================

Write-Host ""
Write-Host "Checking for WiX 6.0..." -ForegroundColor Cyan
Write-Host "  Current user: $env:USERNAME"
Write-Host "  USERPROFILE: $env:USERPROFILE"

$wixAvailable = $false
$wixExe = $null

# 搜索 WiX 可能的安装路径
$wixSearchPaths = @(
    "$env:USERPROFILE\.dotnet\tools\wix.exe",
    "C:\Users\$env:USERNAME\.dotnet\tools\wix.exe",
    "C:\Users\Administrator\.dotnet\tools\wix.exe",
    "C:\Users\onedev\.dotnet\tools\wix.exe",
    "C:\ProgramData\chocolatey\bin\wix.exe"
)

foreach ($path in $wixSearchPaths) {
    Write-Host "  Checking: $path"
    if (Test-Path $path) {
        $wixExe = $path
        Write-Host "    [FOUND]" -ForegroundColor Green
        break
    }
}

# 添加 dotnet tools 到 PATH
$dotnetToolsPath = Join-Path $env:USERPROFILE ".dotnet\tools"
if (Test-Path $dotnetToolsPath) {
    $env:Path = "$dotnetToolsPath;$env:Path"
}

if ($wixExe) {
    try {
        $wixVersion = & $wixExe --version 2>&1
        Write-Host "[OK] WiX found: $wixVersion" -ForegroundColor Green
        Write-Host "  Location: $wixExe"
        $wixAvailable = $true
        # 设置全局变量供后续使用
        $Global:WixExePath = $wixExe
    } catch {
        Write-Host "[WARNING] WiX found but failed to run: $_" -ForegroundColor Yellow
    }
} else {
    # 尝试直接运行 wix 命令
    try {
        $wixCmd = Get-Command wix -ErrorAction SilentlyContinue
        if ($wixCmd) {
            $wixVersion = & wix --version 2>&1
            Write-Host "[OK] WiX found in PATH: $wixVersion" -ForegroundColor Green
            $wixAvailable = $true
            $Global:WixExePath = "wix"
        } else {
            Write-Host "[INFO] WiX not found, skipping MSI creation" -ForegroundColor Yellow
            Write-Host "  Install with: dotnet tool install --global wix"
        }
    } catch {
        Write-Host "[INFO] WiX not available: $_" -ForegroundColor Yellow
    }
}

if ($wixAvailable) {
    Write-Host ""
    Write-Host "Creating MSI installer..." -ForegroundColor Cyan

    $MSI_NAME = Get-OutputName -Version $VERSION -Extension "msi"
    $msiPath = Join-Path $PKG_DIR $MSI_NAME
    $wixDir = Join-Path $ProjectRoot "scripts\deploy\wix"

    # 确保 WiX 目录存在
    if (-not (Test-Path $wixDir)) {
        New-Item -ItemType Directory -Path $wixDir -Force | Out-Null
    }

    # 生成固定的 UpgradeCode (每个产品应该使用相同的 UpgradeCode)
    $UpgradeCode = "05BCDB82-2303-4270-B16D-EE12BDBA7B3B"
    $brandDisplay = if ($Brand) { $Brand.ToUpper() } else { "JinGo" }

    # 创建 WiX 6.0 格式的 .wxs 文件
    $wxsContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
     xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui">

    <Package Name="$brandDisplay VPN"
             Manufacturer="$brandDisplay Team"
             Version="$VERSION.0"
             UpgradeCode="$UpgradeCode"
             Compressed="yes">

        <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />

        <Media Id="1" Cabinet="media1.cab" EmbedCab="yes" />

        <StandardDirectory Id="ProgramFiles64Folder">
            <Directory Id="INSTALLFOLDER" Name="$brandDisplay VPN">
                <Component Id="MainExecutable" Guid="*">
                    <File Id="JinGoExe" Source="$PKG_TEMP_DIR\JinGo.exe" KeyPath="yes" />
                </Component>
                <Component Id="DllFiles" Guid="*">
                    <Files Include="$PKG_TEMP_DIR\*.dll" />
                </Component>
            </Directory>
        </StandardDirectory>

        <StandardDirectory Id="ProgramMenuFolder">
            <Directory Id="ApplicationProgramsFolder" Name="$brandDisplay VPN">
                <Component Id="ApplicationShortcut" Guid="*">
                    <Shortcut Id="ApplicationStartMenuShortcut"
                              Name="$brandDisplay VPN"
                              Description="Launch $brandDisplay VPN"
                              Target="[INSTALLFOLDER]JinGo.exe"
                              WorkingDirectory="INSTALLFOLDER" />
                    <RemoveFolder Id="CleanUpShortCut" On="uninstall" />
                    <RegistryValue Root="HKCU" Key="Software\$brandDisplay\VPN"
                                   Name="installed" Type="integer" Value="1" KeyPath="yes" />
                </Component>
            </Directory>
        </StandardDirectory>

        <Feature Id="ProductFeature" Title="$brandDisplay VPN" Level="1">
            <ComponentRef Id="MainExecutable" />
            <ComponentRef Id="DllFiles" />
            <ComponentRef Id="ApplicationShortcut" />
        </Feature>

        <ui:WixUI Id="WixUI_InstallDir" InstallDirectory="INSTALLFOLDER" />

    </Package>
</Wix>
"@

    $wxsFile = Join-Path $wixDir "Package.wxs"
    Set-Content -Path $wxsFile -Value $wxsContent -Encoding UTF8

    Write-Host "  WiX source file generated: $wxsFile"

    # 使用 WiX 6.0 构建 MSI
    Write-Host "  Building MSI with WiX 6.0..."

    Push-Location $wixDir
    try {
        # 构建 MSI (使用检测到的 WiX 路径)
        & $Global:WixExePath build Package.wxs -o $msiPath -ext WixToolset.UI.wixext 2>&1 | ForEach-Object {
            Write-Host "    $_"
        }

        if (Test-Path $msiPath) {
            $msiSize = (Get-Item $msiPath).Length / 1MB
            Write-Host "[OK] MSI created: $MSI_NAME ($([math]::Round($msiSize, 2)) MB)" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] MSI creation failed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] MSI creation failed: $_" -ForegroundColor Yellow
    }
    Pop-Location
}

Write-Host ""

# ============================================================================
# [5/5] Copy to release directory (Release mode only)
# ============================================================================

if ($BUILD_TYPE -eq "Release") {
    Write-Host ""
    Write-Host "[5/5] Copying to release directory..." -ForegroundColor Cyan

    # Create release directory
    if (-not (Test-Path $RELEASE_DIR)) {
        New-Item -ItemType Directory -Path $RELEASE_DIR -Force | Out-Null
    }

    # Copy ZIP to release directory
    $releaseZipPath = Join-Path $RELEASE_DIR $PACKAGE_NAME
    if (Test-Path $zipPath) {
        Copy-Item -Path $zipPath -Destination $releaseZipPath -Force
        Write-Host "[OK] Copied ZIP to: $releaseZipPath" -ForegroundColor Green
    }

    # Copy MSI to release directory (if exists)
    $MSI_NAME = Get-OutputName -Version $VERSION -Extension "msi"
    $msiPath = Join-Path $PKG_DIR $MSI_NAME
    if (Test-Path $msiPath) {
        $releaseMsiPath = Join-Path $RELEASE_DIR $MSI_NAME
        Copy-Item -Path $msiPath -Destination $releaseMsiPath -Force
        Write-Host "[OK] Copied MSI to: $releaseMsiPath" -ForegroundColor Green
    }

    Write-Host "[OK] Release files copied to: $RELEASE_DIR" -ForegroundColor Green
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "=" * 76
Write-Host "*** BUILD AND DEPLOYMENT COMPLETE ***"
Write-Host "=" * 76
Write-Host ""
Write-Host "Output Files:"
Write-Host "  Build:    $BUILD_DIR\bin\JinGo.exe"
Write-Host "  Deploy:   $PKG_TEMP_DIR\"
Write-Host "  ZIP:      $(Join-Path $PKG_DIR $PACKAGE_NAME)"
if ($BUILD_TYPE -eq "Release") {
    Write-Host "  Release:  $(Join-Path $RELEASE_DIR $PACKAGE_NAME)"
}
Write-Host ""
Write-Host "Distribution Options:"
Write-Host "  1. ZIP package (portable):  $PACKAGE_NAME"
$MSI_NAME = Get-OutputName -Version $VERSION -Extension "msi"
$msiPath = Join-Path $RELEASE_DIR $MSI_NAME
if (Test-Path $msiPath) {
    Write-Host "  2. MSI installer:           $MSI_NAME"
}
Write-Host ""
Write-Host "Testing:"
Write-Host "  1. Extract ZIP and run JinGo.exe"
if (Test-Path $msiPath) {
    Write-Host "  2. Run MSI installer"
}
Write-Host ""
Write-Host "=" * 76
