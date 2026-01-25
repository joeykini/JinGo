# JinGo VPN - 脚本工具集

本目录包含 JinGo VPN 项目的自动化脚本和工具，用于跨平台编译、打包和发布。

## ⚙️ 配置说明

每个构建脚本开头都有一个醒目的 **"平台配置"** 区域，包含该平台所有可配置的选项：

```bash
# ============================================================================
# ██████╗  ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
#                    平台配置 - 修改这里的值来调整构建设置
# ============================================================================

# --------------------- Qt 配置 ---------------------
QT_MACOS_PATH="/Volumes/mindata/Applications/Qt/6.10.0/macos"

# --------------------- Apple 开发者配置 ---------------------
TEAM_ID="****"
CODE_SIGN_IDENTITY="Apple Development"
...
```

**修改配置的方法：**
1. 直接编辑脚本开头的配置区域（推荐）
2. 使用环境变量覆盖（如 `export QT_MACOS_PATH=/your/path`）

---

## 📋 目录结构

```
scripts/
├── README.md                      # 本文档
├── config.sh                      # 🔧 公共配置 (加载 env.sh)
├── env.sh                         # 🔧 环境变量配置
├── setup/                         # 🛠️ 环境配置脚本
│   ├── install-deps.sh           # 依赖安装 (macOS/Linux)
│   └── install-deps.ps1          # 依赖安装 (Windows)
├── build/                         # 🔨 编译脚本
│   ├── build-macos.sh            # macOS 编译
│   ├── build-ios.sh              # iOS 编译
│   ├── build-android.sh          # Android 编译
│   ├── build-linux.sh            # Linux 编译
│   ├── build-windows.ps1         # Windows 编译
│   ├── copy-brand-assets.sh      # 白标资源复制
│   └── translate_ts.py           # 翻译脚本（国际化）
├── deploy/                        # 🚀 发布脚本
│   ├── deploy-macos.sh           # macOS: DMG / Mac App Store
│   ├── deploy-ios.sh             # iOS: IPA / TestFlight / App Store
│   ├── deploy-android.sh         # Android: APK / AAB / Google Play
│   ├── deploy-linux.sh           # Linux: DEB / RPM / TGZ / AppImage
│   └── deploy-windows.ps1        # Windows: ZIP / MSI
└── signing/                       # 🔐 签名工具
    ├── setup_macos_signing.sh    # macOS 签名
    ├── setup_ios_signing.sh      # iOS 签名
    ├── setup_android_signing.sh  # Android 签名
    └── cmake_sign_frameworks.sh  # CMake 构建时签名
```

## 🛠️ 环境配置

### 自动安装依赖

在开始编译前，可以使用依赖安装脚本自动配置开发环境：

```bash
# macOS
./scripts/setup/install-deps.sh

# Linux (Ubuntu/Debian)
./scripts/setup/install-deps.sh
```

```bat
REM Windows (需要管理员权限)
scripts\setup\install-deps.ps1
```

**安装的依赖：**

| 平台 | 包管理器 | 安装的软件 |
|------|---------|-----------|
| macOS | Homebrew | cmake, ninja, qt@6, imagemagick |
| Ubuntu | apt | cmake, ninja-build, qt6-*, imagemagick |
| Windows | winget/chocolatey | cmake, ninja, Qt 6, ImageMagick |

---

## 🎨 白标定制

图标由 Web 端生成，放入 `white-labeling/<brand>/` 目录：

```
white-labeling/<brand>/
├── bundle_config.json          # 应用配置
└── icons/
    ├── app.png                 # 通用图标
    ├── app.icns                # macOS
    ├── app.ico                 # Windows
    ├── ios/                    # iOS 全尺寸图标
    └── android/mipmap-*/       # Android 各密度图标
```

**编译时自动复制资源：**

```bash
# 使用默认品牌 (1)
./scripts/build/build-macos.sh

# 指定品牌
./scripts/build/build-macos.sh --brand 2
```

**更新公钥：**

将公钥文件放入白标目录 `white-labeling/<brand>/license_public_key.pem`，构建时会自动替换。

详细白标定制说明请参考 `docs/11_WHITE_LABELING.md`。

---

## 🖥️ 编译平台依赖

| 目标平台 | 编译环境 | 构建脚本 | 说明 |
|---------|---------|---------|------|
| macOS   | macOS   | `build/build-macos.sh` | 需要 Xcode |
| iOS     | macOS   | `build/build-ios.sh` | 需要 Xcode |
| Android | macOS   | `build/build-android.sh` | 需要 Android SDK/NDK |
| Linux   | Linux   | `build/build-linux.sh` | 需要 GCC/Clang |
| Windows | Windows | `build/build-windows-wrapper.bat` 或 `build/build-windows.ps1` | 需要 Qt 6.10+ MinGW，使用 JinDoCore 静态库，自动部署运行时依赖 |

## 📂 输出路径

**编译输出：**
| 平台 | 构建目录 | 可执行文件 |
|------|---------|-----------|
| macOS | `build-macos/` | `build-macos/bin/Release/JinGo.app` |
| iOS | `build-ios/` | `build-ios/bin/Debug-iphoneos/JinGo.app` |
| Android | `build-android/` | `build-android/android-build/*.apk` |
| Linux | `build-linux/` | `build-linux/bin/JinGo` |
| Windows | `build-windows/` | `build-windows/bin/JinGo.exe` |

**打包输出（统一目录）：**
| 格式 | 输出目录 | 示例文件名 |
|------|---------|-----------|
| DMG | `pkg/` | `JinGoVPN-1.0.0-macOS.dmg` |
| IPA | `pkg/` | `JinGoVPN-1.0.0-iOS.ipa` |
| APK/AAB | `pkg/` | `JinGo-1.0.0-signed.apk` |
| DEB/RPM | `pkg/` | `jingo-vpn_1.0.0_amd64.deb` |
| ZIP/MSI | `pkg/` | `JinGoVPN-1.0.0-Windows.msi` |

## 📦 打包依赖工具

| 平台 | 格式 | 依赖工具 | 安装方式 |
|------|------|---------|---------|
| macOS | DMG | `hdiutil` | 系统自带 |
| iOS | IPA | `zip` | 系统自带 |
| Android | APK/AAB | Gradle | Android SDK 自带 |
| Linux | DEB | `dpkg-deb` | Debian/Ubuntu 自带 |
| Linux | RPM | `rpmbuild` | `sudo apt install rpm` |
| Linux | AppImage | `appimagetool` | 手动下载 |
| Windows | ZIP | PowerShell | 系统自带 |
| Windows | MSI | WiX Toolset | [wixtoolset.org](https://wixtoolset.org/) |

---

## 🔨 编译 vs 🚀 发布

| 功能 | 编译脚本 (build/) | 发布脚本 (deploy/) |
|-----|-----------------|-------------------|
| **用途** | 开发和测试阶段 | 正式发布阶段 |
| **功能** | CMake 配置 + 源码编译 | 编译 + 签名 + 打包 + 上传 |
| **输出** | 未签名的应用包 (.app / .apk) | 签名的分发包 (DMG / IPA / AAB) |
| **代码签名** | ❌ 不签名（或 ad-hoc 签名） | ✅ Apple Developer / 企业签名 |
| **版本管理** | ❌ 不修改版本号 | ✅ 设置版本号和构建号 |
| **应用商店** | ❌ 不上传 | ✅ 上传到 App Store / Google Play |
| **示例** | `build-ios.sh --debug` | `deploy-ios.sh --testflight --version 1.0.0` |

**简单来说：**
- **build 脚本** = 编译代码（用于日常开发测试）
- **deploy 脚本** = build + 签名 + 打包 + 上传商店（用于正式发布）

---

## 🚀 快速开始

### 1️⃣ 开发阶段 - 编译和测试

```bash
# iOS - 生成 Xcode 项目
./scripts/build/build-ios.sh --xcode

# iOS - 命令行编译并安装到模拟器
./scripts/build/build-ios.sh --debug --simulator --install

# macOS - 编译并生成 DMG
./scripts/build/build-macos.sh --release --package

# Linux - 编译并部署 Qt 依赖
./scripts/build/build-linux.sh --release --deploy

# Android - 编译所有架构并安装到设备
./scripts/build/build-android.sh --abi all --install
```

```bat
REM Windows - 编译 Release 版本
scripts\build\build-windows.ps1 --release
```

### 2️⃣ 发布阶段 - 打包和上传

```bash
# iOS - 上传到 TestFlight
export APPLE_ID="your@email.com"
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./scripts/deploy/deploy-ios.sh --testflight --version 1.0.0 --build 1

# iOS - 提交到 App Store
./scripts/deploy/deploy-ios.sh --appstore --version 1.0.0

# iOS - 交互式选择（推荐新手）
./scripts/deploy/deploy-ios.sh --interactive

# macOS - 创建 DMG 并公证
./scripts/deploy/deploy-macos.sh --dmg --version 1.0.0 --notarize

# macOS - 提交到 Mac App Store
./scripts/deploy/deploy-macos.sh --mas --version 1.0.0 --build 1

# Linux - 创建所有格式安装包
./scripts/deploy/deploy-linux.sh --all --version 1.0.0

# Linux - 仅创建 DEB 包
./scripts/deploy/deploy-linux.sh --deb --version 1.0.0

# Android - 上传到 Google Play 内部测试
export KEYSTORE_PASSWORD="your-password"
./scripts/deploy/deploy-android.sh --playstore --internal --version 1.0.0 --code 1

# Android - 发布到生产环境
./scripts/deploy/deploy-android.sh --playstore --production --version 1.0.1 --code 2
```

```bat
REM Windows - 创建 MSI 安装包
scripts\deploy\deploy-windows.ps1 --msi --version 1.0.0

REM Windows - 创建所有格式（MSI + ZIP）
scripts\deploy\deploy-windows.ps1 --all --version 1.0.0
```

### 3️⃣ 代码签名（macOS/iOS）

```bash
# macOS - 检查开发环境
./scripts/signing/setup_macos_signing.sh --check-env

# macOS - 签名应用（包含 Framework、Plugin、Extension）
./scripts/signing/setup_macos_signing.sh build-macos/bin/Release/JinGo.app "Apple Development"

# iOS - 获取设备 UDID 并配置环境
./scripts/signing/setup_ios_signing.sh --get-udid
./scripts/signing/setup_ios_signing.sh --check

# iOS - 签名应用
./scripts/signing/setup_ios_signing.sh --sign build-ios/JinGo.app
```

---

## 📦 脚本详解

### 🔨 编译脚本（开发测试用）

| 脚本 | 平台 | 特性 | 用途 |
|-----|------|------|-----|
| `build/build-ios.sh` | iOS | ✅ Xcode 项目生成<br>✅ 命令行编译<br>✅ 模拟器支持<br>✅ 设备安装 | 开发和测试 iOS 应用 |
| `build/build-macos.sh` | macOS | ✅ Xcode 项目生成<br>✅ Universal Binary (arm64+x86_64)<br>✅ 自动代码签名<br>✅ Extension 签名验证<br>✅ 编译时间/大小统计 | 开发和测试 macOS 应用 |
| `build/build-linux.sh` | Linux | ✅ CMake 配置<br>✅ Qt 依赖部署<br>✅ DEB/RPM/TGZ 打包<br>✅ Ninja 支持 | 开发和测试 Linux 应用 |
| `build/build-android.sh` | Android | ✅ 多 ABI 支持<br>✅ APK 签名<br>✅ 设备安装 | 开发和测试 Android 应用 |
| `build/build-windows.ps1` | Windows | ✅ MinGW 构建<br>✅ Qt 依赖部署<br>✅ JinDoCore 静态库<br>✅ 运行时 DLL 自动复制<br>✅ Release/Debug | 开发和测试 Windows 应用 |
| `build/build_openssl.sh` | 跨平台 | ✅ OpenSSL 3.0.7 静态库 | 依赖库构建 |
| `translate_ts.py` | 跨平台 | ✅ 自动翻译 Qt .ts 文件<br>✅ 内置多语言词典<br>✅ 增量翻译 | 国际化翻译 |

**主要选项：**
- iOS: `--xcode` (生成项目), `--simulator` (模拟器), `--debug/--release`, `--install`
- macOS: `-x/--xcode` (仅生成项目), `-d/--debug` (Debug模式), `-r/--release` (Release模式), `-c/--clean` (清理构建), `-o/--open` (编译后打开), `-s/--skip-sign` (跳过签名)
- Linux: `--deploy` (部署依赖), `--package` (打包), `--debug/--release`, `--clean`
- Android: `--abi` (架构选择), `--sign` (签名), `--install`, `--release`
- Windows: `--release`, `--debug`, `--clean`

**Windows 特殊说明：**

Windows 平台使用 **JinDoCore 静态库** (libJinDoCore.a) 代替源码编译，以保护核心代码。构建系统会自动处理以下内容：

1. **桥接实现文件** (自动编译):
   - `src/platform/windows/WinTunDriverInstaller.cpp/h` - WinTun 驱动管理
   - `src/utils/RsaCrypto_windows.cpp` - Windows BCrypt 加密实现

2. **运行时依赖** (CMake POST_BUILD 自动复制到 bin/):
   - MinGW 运行时: `libgcc_s_seh-1.dll`, `libstdc++-6.dll`, `libwinpthread-1.dll`
   - VPN 核心库: `superray.dll` (29.5 MB), `wintun.dll`
   - Qt 依赖: 由 `windeployqt` 自动部署

3. **打包时**: `build-windows.ps1` 会将所有 DLL 从 `build-windows/bin/` 复制到 `pkg/` 目录，无需手动配置。

详细信息请参考 [platform/windows/README.md](../../platform/windows/README.md)。

---

### 🚀 发布脚本（正式发布用）

| 脚本 | 平台 | 输出格式 | 功能 |
|-----|------|---------|-----|
| `deploy/deploy-ios.sh` | iOS | IPA | ✅ TestFlight 上传<br>✅ App Store 提交<br>✅ 交互式选择<br>✅ 模拟器支持<br>✅ 简单 IPA 创建 |
| `deploy/deploy-macos.sh` | macOS | DMG / PKG | ✅ DMG 公证<br>✅ Mac App Store<br>✅ macdeployqt<br>✅ 代码签名<br>✅ Universal Binary |
| `deploy/deploy-android.sh` | Android | AAB / APK | ✅ Google Play 上传<br>✅ 多轨道发布<br>✅ 签名管理<br>✅ 版本管理 |
| `deploy/deploy-linux.sh` | Linux | DEB / RPM / TGZ / AppImage | ✅ 多格式打包<br>✅ Qt 依赖部署<br>✅ 启动脚本生成<br>✅ 一键打包 |
| `deploy/deploy-windows.ps1` | Windows | MSI / ZIP | ✅ WiX MSI 安装包<br>✅ ZIP 压缩包<br>✅ 自动文件收集<br>✅ 签名支持 |

**主要选项：**
- iOS: `--testflight`, `--appstore`, `--ipa`, `--simulator`, `--interactive`, `--version`, `--build`
- macOS: `--dmg`, `--mas`, `--notarize`, `--version`, `--build`, `--skip-build`
- Android: `--playstore`, `--internal/alpha/beta/production`, `--aab/apk`, `--version`, `--code`
- Linux: `--deb`, `--rpm`, `--tgz`, `--appimage`, `--all`, `--version`, `--deploy-deps`
- Windows: `--msi`, `--zip`, `--all`, `--version`, `--skip-build`

---

### 🔐 签名工具

| 脚本 | 平台 | 功能 | 特性 |
|-----|------|-----|------|
| `signing/setup_macos_signing.sh` | macOS | 应用签名 + 环境配置 | ✅ 开发环境检查<br>✅ 证书验证<br>✅ Frameworks 签名<br>✅ Extensions 签名<br>✅ 签名验证<br>✅ Gatekeeper 检查 |
| `signing/setup_ios_signing.sh` | iOS | 环境配置 + 应用签名 | ✅ UDID 获取<br>✅ Profile 管理<br>✅ 证书检查<br>✅ 应用签名<br>✅ Extensions 签名<br>✅ 签名验证 |

**主要命令：**
- macOS: `--check-env` (环境检查), `--setup` (环境设置), `<app_path> [identity]` (签名应用)
- iOS: `--get-udid` (获取UDID), `--check` (检查配置), `--sign <app>` (签名应用), `--open-portal` (打开开发者门户)

---

## 📋 完整工作流示例

### iOS 应用发布流程

```bash
# 步骤 0: 配置开发环境（首次）
./scripts/signing/setup_ios_signing.sh --get-udid        # 获取设备 UDID
./scripts/signing/setup_ios_signing.sh --open-portal     # 在开发者门户添加设备
./scripts/signing/setup_ios_signing.sh --check           # 检查签名配置

# 步骤 1: 开发测试
./scripts/build/build-ios.sh --simulator --install       # 模拟器测试

# 步骤 1b: 真机测试（可选）
./scripts/build/build-ios.sh --debug                     # 编译真机版本
./scripts/signing/setup_ios_signing.sh --sign build/ios/JinGo.app  # 签名应用
xcrun devicectl device install app --device <device-id> build/ios/JinGo.app  # 安装到设备

# 步骤 2: 创建 IPA 用于手动分发
./scripts/deploy/deploy-ios.sh --ipa --version 1.0.0

# 步骤 3: 上传到 TestFlight 内测
export APPLE_ID="your@email.com"
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./scripts/deploy/deploy-ios.sh --testflight --version 1.0.0 --build 1

# 步骤 4: 提交到 App Store
./scripts/deploy/deploy-ios.sh --appstore --version 1.0.1
```

### macOS 应用发布流程

```bash
# 步骤 0: 配置开发环境（首次）
./scripts/signing/setup_macos_signing.sh --check-env     # 检查环境
./scripts/signing/setup_macos_signing.sh --setup         # 设置环境（如需要）

# 步骤 1: 开发测试
./scripts/build/build-macos.sh --debug                   # 编译 Debug 版本

# 步骤 1b: 手动签名（可选）
./scripts/signing/setup_macos_signing.sh build/macos/bin/Debug/JinGo.app "Apple Development"

# 步骤 2: 创建未签名 DMG
./scripts/build/build-macos.sh --release --package

# 步骤 3: 创建签名并公证的 DMG
./scripts/deploy/deploy-macos.sh --dmg --version 1.0.0 --notarize

# 步骤 4: 提交到 Mac App Store
./scripts/deploy/deploy-macos.sh --mas --version 1.0.0 --build 1
```

### Android 应用发布流程

```bash
# 步骤 1: 开发测试
./scripts/build/build-android.sh --abi arm64-v8a --install

# 步骤 2: 生成签名 APK
./scripts/build/build-android.sh --abi all --sign --release

# 步骤 3: 上传到 Google Play 内测
export KEYSTORE_PASSWORD="your-password"
./scripts/deploy/deploy-android.sh --playstore --internal --version 1.0.0 --code 1

# 步骤 4: 发布到生产环境
./scripts/deploy/deploy-android.sh --playstore --production --version 1.0.1 --code 2
```

### Linux 应用发布流程

```bash
# 步骤 1: 开发测试
./scripts/build/build-linux.sh --debug --deploy

# 步骤 2: 创建 DEB 包
./scripts/deploy/deploy-linux.sh --deb --version 1.0.0

# 步骤 3: 创建所有格式
./scripts/deploy/deploy-linux.sh --all --version 1.0.0
```

### Windows 应用发布流程

```bat
REM 步骤 1: 开发测试
scripts\build\build-windows.ps1 --debug

REM 步骤 2: 创建 Release 构建
scripts\build\build-windows.ps1 --release --clean

REM 步骤 3: 创建 MSI 安装包
scripts\deploy\deploy-windows.ps1 --msi --version 1.0.0

REM 步骤 4: 创建所有格式（MSI + ZIP）
scripts\deploy\deploy-windows.ps1 --all --version 1.0.0
```

---

## 🔐 代码签名

### macOS 应用签名

`setup_macos_signing.sh` 脚本提供完整的 macOS 应用签名解决方案，支持：

- ✅ 开发环境配置检查
- ✅ 嵌入式 Frameworks 签名
- ✅ Qt 插件签名
- ✅ App Extensions (如 PacketTunnelProvider) 签名
- ✅ 主应用签名
- ✅ 签名验证

**使用方法：**

```bash
# 检查开发环境配置
./scripts/signing/setup_macos_signing.sh --check-env

# 设置开发环境（首次使用）
./scripts/signing/setup_macos_signing.sh --setup

# 签名应用包 - 基本用法
./scripts/signing/setup_macos_signing.sh <app_bundle_path> [signing_identity]

# 示例 - 使用 Apple Development 证书（开发）
./scripts/signing/setup_macos_signing.sh build/macos/bin/Release/JinGo.app "Apple Development"

# 示例 - 使用 Developer ID Application 证书（DMG 分发）
./scripts/signing/setup_macos_signing.sh build/macos/bin/Release/JinGo.app "Developer ID Application"

# 示例 - 使用 3rd Party Mac Developer Application 证书（Mac App Store）
./scripts/signing/setup_macos_signing.sh build/macos/bin/Release/JinGo.app "3rd Party Mac Developer Application"
```

**环境检查功能：**
- ✅ 检查 Xcode 安装和版本
- ✅ 检查签名证书（Apple Development 等）
- ✅ 验证 Team ID 配置
- ✅ 检查 Provisioning Profiles
- ✅ 验证 entitlements 文件和权限
- ✅ 检查 codesign 工具

**签名流程（自动执行）：**
1. 递归查找并签名所有 Frameworks
2. 签名所有 Qt 插件 (.dylib)
3. 签名 App Extensions (.appex)
4. 签名主应用程序
5. 验证签名结果

---

### iOS 开发环境配置和签名

`setup_ios_signing.sh` 脚本提供 iOS 开发环境配置和应用签名功能：

**功能特性：**
- ✅ 获取设备 UDID（支持 xcrun devicectl、idevice_id、system_profiler）
- ✅ Provisioning Profile 刷新指导
- ✅ 签名配置检查（证书、Profile、entitlements）
- ✅ iOS 应用签名（App + Extensions）
- ✅ Apple Developer Portal 快速访问

**使用方法：**

```bash
# 1. 获取连接设备的 UDID
./scripts/signing/setup_ios_signing.sh --get-udid

# 2. 在 Apple Developer Portal 添加设备
./scripts/signing/setup_ios_signing.sh --open-portal

# 3. 刷新 Provisioning Profile 说明
./scripts/signing/setup_ios_signing.sh --refresh-profile

# 4. 检查签名配置
./scripts/signing/setup_ios_signing.sh --check

# 5. 生成 CMake 配置命令
./scripts/signing/setup_ios_signing.sh --cmake

# 6. 签名 iOS 应用
./scripts/signing/setup_ios_signing.sh --sign build/ios/JinGo.app

# 使用指定的 Provisioning Profile 签名
./scripts/signing/setup_ios_signing.sh --sign build/ios/JinGo.app path/to/profile.mobileprovision

# 使用指定的签名身份
./scripts/signing/setup_ios_signing.sh --sign build/ios/JinGo.app '' 'iPhone Developer'
```

**完整开发流程：**

```bash
# 第一次设置 iOS 开发环境
./scripts/signing/setup_ios_signing.sh --get-udid        # 获取 UDID
./scripts/signing/setup_ios_signing.sh --open-portal     # 在网页添加设备
./scripts/signing/setup_ios_signing.sh --check           # 检查配置
./scripts/signing/setup_ios_signing.sh --cmake           # 获取 CMake 命令

# 编译后签名应用
./scripts/signing/setup_ios_signing.sh --sign build/ios/JinGo.app

# 安装到设备
xcrun devicectl device install app --device <device-id> build/ios/JinGo.app
```

**iOS 签名流程（自动执行）：**
1. 移除现有签名
2. 签名所有动态库 (.dylib / .so)
3. 签名所有 Frameworks
4. 签名 App Extensions (PacketTunnelProvider)
5. 签名主可执行文件
6. 签名整个应用包
7. 验证签名结果

---

## 🌍 国际化翻译

`translate_ts.py` 脚本用于自动翻译 Qt 的 .ts 文件，支持 5 种语言：

| 语言代码 | 语言名称 | 状态 |
|---------|---------|------|
| `zh_CN` | 简体中文 | ✅ 完成 |
| `zh_TW` | 繁體中文 | ✅ 完成 |
| `en_US` | English | ✅ 完成 |
| `ru_RU` | Русский | ✅ 完成 |
| `fa_IR` | فارسی | ✅ 完成 |

### 使用方法

```bash
# 自动翻译所有 .ts 文件
python3 scripts/translate_ts.py

# 输出示例：
# === 处理翻译文件 ===
# 处理: jingo_zh_CN.ts - 已翻译: 678/678
# 处理: jingo_zh_TW.ts - 已翻译: 678/678
# ...
```

### 工作原理

1. 扫描 `resources/translations/` 目录下的所有 .ts 文件
2. 根据文件名识别目标语言（如 `jingo_zh_CN.ts` → 简体中文）
3. 使用内置词典将英文源字符串翻译为目标语言
4. 保持已有翻译不变（增量翻译）
5. 输出翻译统计信息

### 添加新翻译

在 `translate_ts.py` 中的词典部分添加新条目：

```python
translations = {
    'zh_CN': {
        'New String': '新字符串',
    },
    'zh_TW': {
        'New String': '新字串',
    },
    # ... 其他语言
}
```

### 构建集成

构建脚本已集成翻译处理：

```bash
# 正常构建（增量检测 .ts/.qm 文件）
./scripts/build/build-macos.sh

# 强制重新生成翻译
./scripts/build/build-macos.sh --translate
```

---

## 🌍 环境变量

### iOS / macOS

```bash
# Apple 开发者账号
export APPLE_DEVELOPMENT_TEAM="****"
export APPLE_ID="your@email.com"
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password
export APPLE_CODE_SIGN_IDENTITY="iPhone Developer"
```

### Android

```bash
# Android 签名
export KEYSTORE_PATH="$HOME/.android/jingo.keystore"
export KEYSTORE_PASSWORD="your-keystore-password"
export KEY_ALIAS="jingo"
export KEY_PASSWORD="your-key-password"

# Google Play 服务账号
export GOOGLE_SERVICE_ACCOUNT_JSON="$HOME/.android/google-play-service-account.json"
```

### Linux

```bash
# Qt 安装路径
export Qt6_DIR="/opt/Qt/6.8.0/gcc_64"
export CMAKE_PREFIX_PATH="$Qt6_DIR"
```

### Windows

```bat
REM Qt 安装路径
set Qt6_DIR=C:\Qt\6.8.0\mingw_64
set PATH=%Qt6_DIR%\bin;%PATH%
```

---

## 📚 常见问题

### Q: 如何选择使用 build 还是 deploy 脚本？

**A:**
- 日常开发和测试使用 **build 脚本**
- 正式发布到应用商店使用 **deploy 脚本**

### Q: deploy 脚本会自动编译吗？

**A:** 是的，deploy 脚本默认会调用 build 脚本进行编译。可以使用 `--skip-build` 跳过编译步骤。

### Q: 如何设置版本号？

**A:**
- 使用 `--version` 参数：`./scripts/deploy/deploy-ios.sh --testflight --version 1.0.0`
- 如果不指定，deploy 脚本会从 `CMakeLists.txt` 自动提取版本号

### Q: iOS 部署脚本的交互模式是什么？

**A:** 使用 `--interactive` 会显示菜单让你选择：
1. iOS 模拟器（快速测试）
2. iOS 真机 IPA（手动安装）
3. TestFlight 测试
4. App Store 发布

### Q: Linux 脚本的 `--all` 参数会生成哪些格式？

**A:** 会生成所有支持的格式：
- DEB（Debian/Ubuntu）
- RPM（Fedora/RHEL）
- TGZ（通用压缩包）
- AppImage（独立可执行）

### Q: Windows MSI 需要什么工具？

**A:** 需要安装 WiX Toolset 6.0：
- 下载：https://wixtoolset.org/
- 或使用：`dotnet tool install --global wix`

### Q: Windows 平台的运行时依赖会自动处理吗？

**A:** 是的，Windows 构建系统会自动处理所有运行时依赖：
- **开发时**: CMake POST_BUILD 命令自动复制 MinGW 运行时 DLL、superray.dll、wintun.dll 到 `build-windows/bin/`
- **打包时**: PowerShell 脚本自动从 bin/ 目录复制所有 DLL 到发布包
- **Qt 依赖**: `windeployqt` 工具自动部署 Qt DLL 和插件

不需要手动复制任何 DLL 文件。

### Q: iOS/macOS 签名时出现 "unable to build chain to self-signed root" 错误？

**A:** 这是因为 CI 服务器缺少 Apple WWDR (Worldwide Developer Relations) 中间证书。

**解决方法：** 在 CI 服务器上下载并安装 Apple 中间证书：

```bash
# 下载 Apple WWDR 中间证书
curl -O https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
curl -O https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer

# 导入到钥匙串
security import AppleWWDRCAG3.cer -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign
security import AppleWWDRCAG4.cer -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign

# 验证证书已安装
security find-certificate -c "Apple Worldwide Developer Relations" ~/Library/Keychains/login.keychain-db
```

**错误示例：**
```
Warning: unable to build chain to self-signed root for signer "Apple Development: xxx"
xxx.app: errSecInternalComponent
```

**原因：** codesign 需要完整的证书链（开发者证书 → WWDR 中间证书 → Apple 根证书）才能正确签名。CI 环境通常没有预装 WWDR 中间证书。

---

## 💡 最佳实践

1. **版本管理**
   - 在 `CMakeLists.txt` 中定义主版本号
   - 使用 deploy 脚本的 `--version` 覆盖版本号
   - 每次发布增加构建号 `--build`

2. **代码签名**
   - 开发测试使用 Development 证书
   - DMG 分发使用 Developer ID 证书
   - App Store 使用 Distribution 证书

3. **测试流程**
   - 先用 build 脚本在本地测试
   - 再用 deploy 脚本创建 IPA/DMG 测试
   - 最后上传到 TestFlight/Google Play 内测
   - 确认无误后发布到生产环境

4. **CI/CD 集成**
   - 所有脚本都支持命令行参数，易于集成到 CI/CD
   - 使用环境变量存储敏感信息（密码、证书）
   - 建议使用 GitHub Actions / GitLab CI

---

## 🔗 相关链接

- [JinGo VPN 项目主页](../../README.md)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Google Play Console](https://play.google.com/console/)
- [WiX Toolset](https://wixtoolset.org/)
- [Qt Documentation](https://doc.qt.io/)

---

**文档版本**: 1.3.1
**最后更新**: 2026-01-25
**适用版本**: JinGo VPN 1.0.0+
