# JinGo VPN - 构建指南

## 概述

JinGo 使用 JinDoCore 静态库作为核心依赖，构建时会自动链接。

**前提条件**: JinDoCore 静态库已编译并放置在 `../JinDo/lib/` 目录。

## 环境要求

### 通用要求

| 工具 | 版本 | 说明 |
|------|------|------|
| Qt | 6.10.0+ | UI 框架 |
| CMake | 3.21+ | 构建系统 |
| Git | 2.0+ | 版本控制 |

### 平台特定要求

| 平台 | 编译器 | 其他 |
|------|--------|------|
| Android | NDK 26.1+ | Android SDK, Java 17+ |
| iOS | Xcode 15+ | Apple Developer 账号 |
| macOS | Xcode 15+ | Apple Developer 账号 |
| Windows | VS 2022 | Windows SDK |
| Linux | GCC 11+ / Clang 14+ | libsecret, OpenSSL |

## 项目设置

### 1. 克隆项目

```bash
# 创建工作目录
mkdir -p ~/OpineWork
cd ~/OpineWork

# 克隆 JinDo (核心库)
git clone <jindo-repo-url> JinDo

# 克隆 JinGo (应用)
git clone <jingo-repo-url> JinGo

# 目录结构
# ~/OpineWork/
# ├── JinDo/    # 核心静态库
# └── JinGo/    # 应用项目
```

### 2. 安装 Qt

#### macOS

```bash
# 下载 Qt 在线安装器
# https://www.qt.io/download-qt-installer

# 安装组件：
# - Qt 6.10.0
#   - macOS
#   - iOS
#   - Android (arm64-v8a, armeabi-v7a, x86_64)
```

#### Linux

```bash
# 下载 Qt 在线安装器
wget https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x qt-unified-linux-x64-online.run
./qt-unified-linux-x64-online.run

# 安装组件：
# - Qt 6.10.0
#   - Desktop gcc 64-bit

# 安装系统依赖
sudo apt install -y \
    build-essential cmake ninja-build \
    libglib2.0-dev libsecret-1-dev \
    libgl1-mesa-dev libxcb1-dev libxcb-*-dev \
    libxkbcommon-dev libxkbcommon-x11-dev
```

#### Windows

```powershell
# 下载 Qt 在线安装器
# https://www.qt.io/download-qt-installer

# 安装组件：
# - Qt 6.10.0
#   - MSVC 2022 64-bit

# 安装 Visual Studio 2022
# https://visualstudio.microsoft.com/
# 选择 "Desktop development with C++"
```

## Android 构建

### 1. 环境配置

```bash
# 设置环境变量
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/26.1.10909125
export JAVA_HOME=/path/to/jdk17
```

### 2. 编译 JinGo APK

```bash
cd ~/OpineWork/JinGo

# 编译全架构 APK
./scripts/build/build-android.sh --clean --release --abi all

# 或单架构
./scripts/build/build-android.sh --clean --release --abi arm64-v8a

# 输出位置
# release/jingo-1.0.0-YYYYMMDD-android.apk
```

### 4. 签名 APK (可选)

```bash
# 生成签名密钥
keytool -genkey -v -keystore jingo.keystore \
    -alias jingo -keyalg RSA -keysize 2048 -validity 10000

# 签名
./scripts/build/build-android.sh --release --sign
```

## iOS 构建

### 1. 环境配置

```bash
# 确保 Xcode 命令行工具已安装
xcode-select --install

# 设置签名身份
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export CODE_SIGN_IDENTITY="Apple Development"
```

### 2. 编译 JinGo IPA

```bash
cd ~/OpineWork/JinGo

# 编译
./scripts/build/build-ios.sh --clean --release

# 输出位置
# release/jingo-1.0.0-YYYYMMDD-ios.ipa
```

### 4. 配置 Provisioning Profiles

1. 在 Apple Developer 创建 App ID
2. 创建 Provisioning Profile (Development/Distribution)
3. 下载并安装到 Xcode

## macOS 构建

### 编译 JinGo App

```bash
cd ~/OpineWork/JinGo

# 编译
./scripts/build/build-macos.sh --clean --release

# 创建 DMG
./scripts/build/create-dmg.sh

# 公证 (可选)
./scripts/build/notarize-macos.sh

# 输出位置
# release/jingo-1.0.0-YYYYMMDD-macos.dmg
```

## Windows 构建

### 1. 环境配置

```powershell
# 打开 "Developer Command Prompt for VS 2022"
# 或设置环境变量
$env:Qt6_DIR = "C:\Qt\6.10.0\msvc2022_64"
```

### 2. 编译 JinGo

```powershell
cd C:\OpineWork\JinGo

# 编译
.\scripts\build\build-windows.ps1 -Clean -Release

# 输出位置
# release\jingo-1.0.0-YYYYMMDD-windows.exe
```

## Linux 构建

### 1. 安装依赖

```bash
# Ubuntu/Debian
sudo apt install -y \
    build-essential cmake ninja-build \
    libglib2.0-dev libsecret-1-dev libssl-dev \
    libgl1-mesa-dev libxcb1-dev libxcb-*-dev \
    libxkbcommon-dev libxkbcommon-x11-dev \
    libdbus-1-dev

# Fedora
sudo dnf install -y \
    @development-tools cmake ninja-build \
    glib2-devel libsecret-devel openssl-devel \
    mesa-libGL-devel libxcb-devel xcb-util-*-devel \
    libxkbcommon-devel libxkbcommon-x11-devel \
    dbus-devel
```

### 2. 编译 JinGo

```bash
cd ~/OpineWork/JinGo

# 编译
./scripts/build/build-linux.sh --clean --release

# 部署 Qt 依赖
./scripts/build/build-linux.sh --deploy

# 创建安装包
./scripts/build/build-linux.sh --package

# 输出位置
# release/jingo-1.0.0-YYYYMMDD-linux.tar.gz
```

### 4. 运行前设置

```bash
# 设置 TUN 权限
sudo setcap cap_net_admin+eip build-linux/bin/JinGo

# 验证
getcap build-linux/bin/JinGo
```

## 构建选项参考

### 构建脚本选项

| 选项 | 说明 |
|------|------|
| `--clean` | 清理构建目录 |
| `--release` | Release 模式 |
| `--debug` | Debug 模式 |
| `--abi <ABI>` | Android: 指定架构 (或 `all`) |
| `--sign` | 签名应用 |
| `--deploy` | Linux: 部署 Qt 依赖 |
| `--package` | Linux: 创建安装包 |
| `--notarize` | macOS: 公证应用 |
| `--brand <ID>` | 使用指定白标资源 |

## 常见问题

### Qt 找不到

```bash
# 设置 Qt 路径
export Qt6_DIR=/path/to/Qt/6.10.0/gcc_64  # Linux
export Qt6_DIR=/path/to/Qt/6.10.0/macos   # macOS
```

### Android NDK 版本不匹配

```bash
# 指定 NDK 版本
export ANDROID_NDK_VERSION=26.1.10909125
./scripts/build/build-android.sh --release
```

### 链接错误 (PIC)

确保 JinDoCore 使用 `-fPIC` 编译：
```cmake
# JinDo/CMakeLists.txt
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
```

### macOS 签名问题

```bash
# 检查签名身份
security find-identity -v -p codesigning

# 指定签名身份
export CODE_SIGN_IDENTITY="Apple Development: Your Name (XXXXXXXXXX)"
```

## CI/CD 集成

### GitHub Actions 示例

```yaml
# .github/workflows/build.yml
name: Build

on: [push, pull_request]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Qt
        uses: jurplel/install-qt-action@v3
        with:
          version: '6.10.0'
          target: 'android'
      - name: Build JinDoCore
        run: |
          cd ../JinDo
          ./scripts/build-android.sh --all-abis
      - name: Build APK
        run: ./scripts/build/build-android.sh --release --abi all
```

## 下一步

- [开发指南](03_DEVELOPMENT.md) - 了解如何修改和调试
- [白标定制](04_WHITE_LABELING.md) - 了解如何定制品牌
- [故障排除](05_TROUBLESHOOTING.md) - 解决常见问题
