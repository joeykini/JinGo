# JinGo VPN

跨平台 VPN 客户端，基于 Qt 6 和 Xray 核心构建。

## 特性

- **跨平台支持**: Android、iOS、macOS、Windows、Linux
- **现代化界面**: Qt 6 QML 构建的流畅用户界面
- **多协议支持**: 基于 Xray 核心，支持 VMess、VLESS、Trojan、Shadowsocks 等
- **多语言**: 支持 8 种语言（中文、英文、越南语、高棉语、缅甸语、俄语、波斯语等）
- **白标定制**: 支持品牌定制和多租户部署

## 项目架构

```
JinGo/                          # 主应用项目
├── src/                        # 应用入口和平台特定代码
│   ├── main.cpp               # 应用入口
│   └── platform/              # 平台适配层
├── qml/                        # QML 界面文件
├── resources/                  # 资源文件（图标、翻译、GeoIP数据）
├── platform/                   # 平台配置（Android/iOS）
├── third_party/               # 第三方依赖
│   ├── superray/              # SuperRay (Xray 封装库)
│   └── android_openssl/       # Android OpenSSL
└── scripts/                   # 构建和部署脚本

JinDo/                          # 核心静态库项目（独立仓库）
```

## 快速开始

### 前置条件

- **Qt**: 6.10.0 或更高版本
- **CMake**: 3.21+
- **编译器**:
  - macOS/iOS: Xcode 15+
  - Android: NDK 26.1+
  - Windows: Visual Studio 2022
  - Linux: GCC 11+ 或 Clang 14+

### 编译步骤

#### 1. 编译 JinDoCore 静态库

```bash
# 进入 JinDo 项目目录
cd ../JinDo

# Android (全架构)
./scripts/build-android.sh --clean --all-abis

# macOS
./scripts/build-macos.sh --clean

# iOS
./scripts/build-ios.sh --clean

# Linux
./scripts/build-linux.sh --clean

# Windows (PowerShell)
.\scripts\build-windows.ps1 -Clean
```

#### 2. 编译 JinGo 应用

```bash
# 进入 JinGo 项目目录
cd ../JinGo

# Android APK (全架构)
./scripts/build/build-android.sh --clean --release --abi all

# macOS App
./scripts/build/build-macos.sh --clean --release

# iOS App
./scripts/build/build-ios.sh --clean --release

# Linux
./scripts/build/build-linux.sh --clean --release

# Windows (PowerShell)
.\scripts\build\build-windows.ps1 -Clean -Release
```

### 输出位置

| 平台 | 输出文件 | 位置 |
|------|---------|------|
| Android | APK | `release/jingo-*-android.apk` |
| macOS | DMG | `release/jingo-*-macos.dmg` |
| iOS | IPA | `release/jingo-*-ios.ipa` |
| Windows | EXE/MSI | `release/jingo-*-windows.exe` |
| Linux | tar.gz | `release/jingo-*-linux.tar.gz` |

## 平台支持

| 平台 | 架构 | 最低版本 | 状态 |
|------|------|---------|------|
| Android | arm64-v8a, armeabi-v7a, x86_64 | API 28 (Android 9) | ✅ |
| iOS | arm64 | iOS 15.0 | ✅ |
| macOS | arm64, x86_64 | macOS 12.0 | ✅ |
| Windows | x64 | Windows 10 | ✅ |
| Linux | x64 | Ubuntu 20.04+ | ✅ |

## 文档

详细文档请查看 [docs/](docs/) 目录：

- [架构说明](docs/01_ARCHITECTURE.md)
- [构建指南](docs/02_BUILD_GUIDE.md)
- [开发指南](docs/03_DEVELOPMENT.md)
- [白标定制](docs/04_WHITE_LABELING.md)
- [故障排除](docs/05_TROUBLESHOOTING.md)

### 平台指南

- [Linux](docs/06_LINUX.md)
- [Android](docs/07_ANDROID.md)
- [iOS](docs/08_IOS.md)
- [macOS](docs/09_MACOS.md)
- [Windows](docs/10_WINDOWS.md)

## 目录结构

```
JinGo/
├── CMakeLists.txt              # 主 CMake 配置
├── cmake/                      # CMake 模块
│   ├── Platform-Android.cmake
│   ├── Platform-iOS.cmake
│   ├── Platform-macOS.cmake
│   └── ...
├── src/
│   ├── main.cpp               # 应用入口
│   └── platform/              # 平台适配代码
├── qml/                        # QML 界面
│   ├── Main.qml
│   ├── pages/
│   └── components/
├── resources/
│   ├── icons/                 # 应用图标
│   ├── translations/          # 翻译文件 (*.ts)
│   └── geoip/                 # GeoIP 数据
├── platform/
│   ├── android/               # Android 配置
│   ├── ios/                   # iOS 配置
│   └── macos/                 # macOS 配置
├── third_party/
│   ├── superray/              # Xray 核心封装
│   └── android_openssl/       # Android OpenSSL
├── scripts/
│   ├── build/                 # 构建脚本
│   ├── deploy/                # 部署脚本
│   └── signing/               # 签名脚本
├── white-labeling/            # 白标资源
│   ├── brand1/
│   ├── brand2/
│   └── ...
└── release/                   # 构建输出
```

## 多语言支持

| 语言 | 代码 | 状态 |
|------|------|------|
| English | en_US | ✅ |
| 简体中文 | zh_CN | ✅ |
| 繁體中文 | zh_TW | ✅ |
| Tiếng Việt | vi_VN | ✅ |
| ភាសាខ្មែរ | km_KH | ✅ |
| မြန်မာဘာသာ | my_MM | ✅ |
| Русский | ru_RU | ✅ |
| فارسی | fa_IR | ✅ |

## 技术栈

- **UI 框架**: Qt 6.10.0+ (QML/Quick)
- **VPN 核心**: Xray-core (通过 SuperRay 封装)
- **网络**: Qt Network + OpenSSL
- **存储**: SQLite (Qt SQL)
- **安全存储**:
  - macOS/iOS: Keychain
  - Android: EncryptedSharedPreferences
  - Windows: DPAPI
  - Linux: libsecret

## 构建选项

### CMake 选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `USE_JINDO_LIB` | ON | 使用 JinDoCore 静态库 |
| `JINDO_ROOT` | `../JinDo` | JinDo 项目路径 |
| `CMAKE_BUILD_TYPE` | Debug | 构建类型 (Debug/Release) |

### 构建脚本选项

```bash
# 通用选项
--clean          # 清理构建目录
--release        # Release 模式
--debug          # Debug 模式

# Android 特定
--abi <ABI>      # 指定架构 (arm64-v8a/armeabi-v7a/x86_64/all)
--sign           # 签名 APK

# macOS/iOS 特定
--notarize       # 公证应用

# Linux 特定
--deploy         # 部署 Qt 依赖
--package        # 创建安装包
```

## 开发

### 代码风格

- C++17 标准
- Qt 编码规范
- 使用 `clang-format` 格式化

### 调试

```bash
# 启用详细日志
QT_LOGGING_RULES="*.debug=true" ./JinGo

# Android logcat
adb logcat -s JinGo:V SuperRay-JNI:V
```

## 许可证

私有软件，保留所有权利。

## 联系方式

- Telegram 频道: [@OpineWorkPublish](https://t.me/OpineWorkPublish)
- Telegram 群组: [@OpineWorkOfficial](https://t.me/OpineWorkOfficial)

---

**版本**: 1.0.0
**Qt 版本**: 6.10.0+
**最后更新**: 2025-01
