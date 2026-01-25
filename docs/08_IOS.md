# JinGo VPN - iOS 平台指南

## 概述

本文档涵盖 iOS 平台的编译、调试和发布。

### 系统要求

| 项目 | 要求 |
|------|------|
| macOS | 12.0+ |
| Xcode | 15.0+ |
| iOS 目标 | iOS 15.0+ |
| Qt | 6.10.0+ (iOS 组件) |
| Apple Developer | 需要开发者账号 |

### 支持的架构

| 架构 | 说明 |
|------|------|
| arm64 | 64位 ARM (所有现代 iOS 设备) |

## 环境配置

### 安装 Xcode

```bash
# 从 App Store 安装 Xcode
# 或下载: https://developer.apple.com/xcode/

# 安装命令行工具
xcode-select --install

# 接受许可
sudo xcodebuild -license accept
```

### 安装 Qt iOS 组件

使用 Qt 在线安装器安装：
- Qt 6.10.0
  - iOS

### 配置签名

```bash
# 设置环境变量
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export CODE_SIGN_IDENTITY="Apple Development"

# 查看可用签名身份
security find-identity -v -p codesigning
```

## 编译

### 基本编译

```bash
cd ~/OpineWork/JinGo

# Debug 版本
./scripts/build/build-ios.sh --debug

# Release 版本
./scripts/build/build-ios.sh --release

# 清理后编译
./scripts/build/build-ios.sh --clean --release
```

### 编译选项

| 选项 | 说明 |
|------|------|
| `--clean` | 清理构建目录 |
| `--debug` | Debug 模式 |
| `--release` | Release 模式 |
| `--brand <NAME>` | 白标定制 |

### 输出目录

```
build-ios/
├── JinGo.xcodeproj        # Xcode 项目
└── JinGo.app              # 应用包

release/
└── jingo-*-ios.ipa        # 发布 IPA
```

## 证书和配置

### App ID 配置

在 Apple Developer 创建 App ID：
1. 登录 [Apple Developer](https://developer.apple.com)
2. Certificates, Identifiers & Profiles
3. Identifiers → App IDs → 新建
4. 启用 Network Extensions 能力

### 创建 Provisioning Profile

1. 选择 App ID
2. 选择证书
3. 选择设备（开发版）
4. 下载并双击安装

### Network Extension 配置

iOS VPN 需要 Network Extension：

```xml
<!-- Info.plist -->
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.networkextension.packet-tunnel</string>
    <key>NSExtensionPrincipalClass</key>
    <string>PacketTunnelProvider</string>
</dict>
```

### App Groups 配置

主应用和扩展需要共享数据：

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.jingo.vpn</string>
</array>
```

## 调试

### 真机调试

1. 连接 iOS 设备
2. 在 Xcode 中选择设备
3. 选择正确的签名配置
4. 点击 Run

### 查看日志

```bash
# 使用 Console.app
# 打开 Console.app → 选择设备 → 搜索 JinGo

# 或使用 idevicesyslog
idevicesyslog | grep JinGo
```

### 调试 Network Extension

Network Extension 运行在独立进程：

1. Xcode → Debug → Attach to Process
2. 选择扩展进程
3. 设置断点

## 故障排除

### 签名错误

**错误：**
```
Code Sign error: No matching provisioning profiles found
```

**解决：**
1. 检查 Bundle ID 匹配
2. 确认证书有效
3. 重新下载 Provisioning Profile

### Network Extension 加载失败

**错误：**
```
Failed to load Network Extension
```

**解决：**
1. 检查 App Groups 配置
2. 确认扩展签名正确
3. 检查 entitlements 文件

### 设备未信任

**解决：**
1. 设置 → 通用 → VPN 与设备管理
2. 信任开发者证书

### VPN 配置创建失败

**错误：**
```
NEVPNError: Configuration is invalid
```

**解决：**
1. 检查 Network Extension 能力
2. 验证 VPN 配置参数
3. 查看系统日志

## 发布

### 生成 IPA

```bash
# 编译 Release 版本
./scripts/build/build-ios.sh --clean --release

# IPA 位置
ls release/jingo-*-ios.ipa
```

### TestFlight 测试

1. 登录 App Store Connect
2. 创建应用
3. 上传 IPA (使用 Transporter)
4. 添加测试人员
5. 提交测试

### App Store 发布

1. 完成 TestFlight 测试
2. 准备 App Store 信息
3. 上传截图和描述
4. 提交审核
5. 等待审核通过

### 审核注意事项

VPN 应用审核要点：
- 需要提供服务器端说明
- 说明数据收集和隐私政策
- 可能需要额外审核时间

## Entitlements

### 主应用 entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>packet-tunnel-provider</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.jingo.vpn</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.jingo.vpn</string>
    </array>
</dict>
</plist>
```

### 扩展 entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>packet-tunnel-provider</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.jingo.vpn</string>
    </array>
</dict>
</plist>
```

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [macOS 平台指南](09_MACOS.md)
- [故障排除](05_TROUBLESHOOTING.md)
