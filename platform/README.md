# JinGo VPN - 平台专用资源

本目录包含各平台特定的资源文件、配置和原生代码。

## 📁 目录结构

```
platform/
├── README.md                      # 本文档
├── android/                       # Android 平台
│   ├── AndroidManifest.xml       # 应用清单
│   ├── build.gradle              # Gradle 配置
│   ├── assets/                   # 静态资源
│   │   ├── dat/                  # GeoIP 数据
│   │   └── translations/         # 翻译文件 (.qm)
│   ├── keystore/                 # 签名密钥
│   ├── libs/                     # 预编译库 (.so)
│   ├── res/                      # Android 资源
│   │   ├── drawable-*/           # 各密度图标
│   │   ├── values/               # 样式定义
│   │   └── xml/                  # 网络安全配置
│   └── src/                      # Java 源码
│       └── work/opine/jingo/     # 主包
├── ios/                          # iOS 平台
│   ├── Info.plist               # 应用配置
│   ├── *.entitlements           # 授权文件
│   ├── LaunchScreen.storyboard  # 启动画面
│   ├── Assets.xcassets/         # App 图标
│   ├── cert/                    # 证书和描述文件
│   └── README.md                # iOS 构建指南
├── macos/                        # macOS 平台
│   ├── Info.plist               # 应用配置
│   ├── *.entitlements           # 授权文件
│   ├── cert/                    # 证书和描述文件
│   └── README.md                # macOS 签名指南
├── windows/                      # Windows 平台
│   ├── JinGo.manifest           # 管理员权限清单
│   ├── *.rc                     # 资源文件
│   ├── generate_icon.py         # 图标生成工具
│   └── README.md                # Windows 配置指南
└── linux/                        # Linux 平台
    └── jingo.desktop            # 桌面快捷方式
```

---

## 📱 Android 平台

### 核心文件

| 文件 | 用途 |
|------|------|
| `AndroidManifest.xml` | 声明应用权限、组件、VPN 服务 |
| `build.gradle` | Gradle 构建配置 |
| `proguard-rules.pro` | ProGuard 混淆规则 |

### Java 源码 (`src/work/opine/jingo/`)

| 文件 | 用途 |
|------|------|
| `JinGoActivity.java` | 主 Activity |
| `JinGoVpnService.java` | VPN 服务实现 |
| `HevSocks5Manager.java` | hev-socks5-tunnel 管理 |
| `SuperRayManager.java` | Xray 核心管理 |
| `SecureStorage.java` | 安全存储 |
| `BootCompletedReceiver.java` | 开机自启动 |

### 签名密钥 (`keystore/`)

```bash
# 密钥存放位置
platform/android/keystore/jingo-release.keystore

# 使用签名脚本进行签名
./scripts/signing/post_build_android.sh --sign <apk文件>
```

### 资源说明

- `assets/dat/` - GeoIP 数据文件（geoip.dat, geosite.dat）
- `assets/translations/` - 编译后的翻译文件（.qm）
- `res/drawable-*/` - 不同密度的应用图标
- `res/xml/network_security_config.xml` - 网络安全配置

---

## 🍎 iOS 平台

### 核心文件

| 文件 | 用途 |
|------|------|
| `Info.plist` | 应用配置（Bundle ID、权限说明等） |
| `JinGo.entitlements` | 主应用授权（App Groups、Network Extension） |
| `PacketTunnelProvider.entitlements` | TUN 模式 Extension 授权 |
| `LaunchScreen.storyboard` | 启动画面 |

### 证书和描述文件 (`cert/`)

| 文件 | 用途 |
|------|------|
| `JinGo_Accelerator_iOS.mobileprovision` | 主应用描述文件 |
| `PacketTunnelProvider_iOS.mobileprovision` | TUN Extension 描述文件 |

### App Group

iOS 主应用与 Network Extension 通过 App Group 共享数据：
- **App Group ID**: `group.cfd.jingo.acc`
- **共享内容**: VPN 状态、延迟信息、流量统计

### VPN 模式限制

| 功能 | iOS | 其他平台 |
|------|-----|---------|
| TUN 模式 | ✅ | ✅ |
| Local Proxy | ❌ 沙箱限制 | ✅ |

详细说明请参考：[iOS README](ios/README.md)

---

## 💻 macOS 平台

### 核心文件

| 文件 | 用途 |
|------|------|
| `Info.plist` | 应用配置 |
| `JinGo.entitlements` | 主应用授权 |
| `PacketTunnelProvider.entitlements` | TUN Extension 授权 |

### 证书和描述文件 (`cert/`)

| 文件 | 用途 |
|------|------|
| `JinGo_Accelerator_MacOS.provisionprofile` | 主应用描述文件 |
| `PacketTunnelProvider_MacOS.provisionprofile` | TUN Extension 描述文件 |

### 签名流程

```bash
# 使用签名脚本
./scripts/signing/setup_macos_signing.sh check    # 检查当前签名
./scripts/signing/setup_macos_signing.sh sign     # 重新签名
./scripts/signing/setup_macos_signing.sh notarize # 公证
```

详细说明请参考：[macOS README](macos/README.md)

---

## 🪟 Windows 平台

### 核心文件

| 文件 | 用途 |
|------|------|
| `JinGo.manifest` | 管理员权限清单（UAC） |
| `JinGo.rc` | 主资源文件（图标、版本信息） |
| `app.rc` | 应用资源配置 |

### 管理员权限

VPN 应用需要管理员权限来：
- 创建虚拟网卡（WinTUN）
- 修改路由表
- 管理网络配置

`JinGo.manifest` 配置了 `requireAdministrator` 权限。

### 图标生成

```bash
# 从 PNG 生成 ICO
python platform/windows/generate_icon.py \
    resources/icons/app.png \
    resources/icons/app.ico
```

详细说明请参考：[Windows README](windows/README.md)

---

## 🐧 Linux 平台

### 桌面集成

`jingo.desktop` 文件用于：
- 在应用菜单中显示图标
- 配置启动命令
- 设置文件类型关联

安装位置：`~/.local/share/applications/` 或 `/usr/share/applications/`

### TUN 权限

Linux 上需要特殊权限来操作 TUN 设备：

```bash
# 设置 CAP_NET_ADMIN 能力
sudo setcap cap_net_admin+eip /path/to/JinGo
```

---

## 🔗 与构建脚本的关系

| 平台 | 构建脚本 | 使用的平台资源 |
|------|----------|---------------|
| Android | `scripts/build/build-android.sh` | `platform/android/*` |
| iOS | `scripts/build/build-ios.sh` | `platform/ios/*` |
| macOS | `scripts/build/build-macos.sh` | `platform/macos/*` |
| Windows | `scripts/build/build-windows_mingw.bat` | `platform/windows/*` |
| Linux | `scripts/build/build-linux.sh` | `platform/linux/*` |

构建脚本会自动将这些平台资源复制到输出目录。

---

## 📝 注意事项

1. **证书和密钥安全**
   - `cert/` 和 `keystore/` 目录中的文件不应提交到公开仓库
   - 使用 `.gitignore` 排除敏感文件

2. **资源同步**
   - 修改图标后需要在所有平台目录中更新
   - 使用 `scripts/tools/` 中的工具批量生成图标

3. **权限配置**
   - Apple 平台需要正确配置 entitlements
   - Android 需要在 AndroidManifest.xml 中声明权限
   - Windows 需要 UAC 清单
   - Linux 需要 setcap 权限
