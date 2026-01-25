# JinGo VPN - macOS 平台指南

## 概述

本文档涵盖 macOS 平台的编译、调试和发布。

### 系统要求

| 项目 | 要求 |
|------|------|
| macOS | 12.0+ (Monterey) |
| Xcode | 15.0+ |
| Qt | 6.10.0+ (macOS 组件) |
| CMake | 3.21+ |

### 支持的架构

| 架构 | 说明 |
|------|------|
| arm64 | Apple Silicon (M1/M2/M3) |
| x86_64 | Intel Mac |

## 环境配置

### 安装 Xcode

```bash
# 从 App Store 安装 Xcode

# 安装命令行工具
xcode-select --install

# 接受许可
sudo xcodebuild -license accept
```

### 安装 Qt

使用 Qt 在线安装器安装：
- Qt 6.10.0
  - macOS

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
./scripts/build/build-macos.sh --debug

# Release 版本
./scripts/build/build-macos.sh --release

# 清理后编译
./scripts/build/build-macos.sh --clean --release
```

### 编译选项

| 选项 | 说明 |
|------|------|
| `--clean` | 清理构建目录 |
| `--debug` | Debug 模式 |
| `--release` | Release 模式 |
| `--notarize` | 公证应用 |
| `--brand <NAME>` | 白标定制 |

### Universal Binary (可选)

```bash
# 编译双架构
./scripts/build/build-macos.sh --release --universal
```

### 输出目录

```
build-macos/
├── JinGo.app              # 应用包
└── bin/                   # 可执行文件

release/
├── jingo-*-macos.app      # 应用包
└── jingo-*-macos.dmg      # 磁盘镜像
```

## VPN 模式

macOS 支持两种 VPN 模式：

### 1. 管理员 TUN 模式 (当前使用)

使用管理员权限创建 TUN 设备：

**优点：**
- 无需 Network Extension
- 配置简单
- 无需 Apple Developer 账号

**缺点：**
- 需要管理员密码
- 无法上架 Mac App Store

```bash
# 运行时需要管理员权限
sudo ./JinGo.app/Contents/MacOS/JinGo
```

### 2. Network Extension 模式 (沙盒)

使用系统 Network Extension：

**优点：**
- 无需管理员权限
- 可上架 Mac App Store

**缺点：**
- 需要 Apple Developer 账号
- 配置复杂

## 签名和公证

### 代码签名

```bash
# 签名应用
codesign --force --deep --sign "Apple Development: Your Name" JinGo.app

# 验证签名
codesign --verify --verbose JinGo.app
```

### 公证

```bash
# 公证应用
./scripts/build/notarize-macos.sh

# 或手动公证
xcrun notarytool submit JinGo.dmg \
    --apple-id "your@email.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID" \
    --wait

# 装订公证票据
xcrun stapler staple JinGo.dmg
```

### 创建 DMG

```bash
# 使用脚本创建
./scripts/build/create-dmg.sh

# 或手动创建
hdiutil create -volname "JinGo VPN" \
    -srcfolder build-macos/JinGo.app \
    -ov -format UDZO \
    JinGo.dmg
```

## 调试

### 运行调试

```bash
# Debug 模式运行
./build-macos/JinGo.app/Contents/MacOS/JinGo

# 启用日志
QT_LOGGING_RULES="*.debug=true" ./build-macos/JinGo.app/Contents/MacOS/JinGo
```

### 使用 LLDB

```bash
# 附加调试器
lldb ./build-macos/JinGo.app/Contents/MacOS/JinGo

# 在 LLDB 中
(lldb) run
(lldb) bt  # 查看调用栈
```

### 查看日志

```bash
# 使用 Console.app
# 打开 Console.app → 搜索 JinGo

# 命令行查看
log stream --predicate 'processImagePath contains "JinGo"'
```

## 故障排除

### 签名错误

**错误：**
```
Code Sign error: No identity found
```

**解决：**
```bash
# 检查可用身份
security find-identity -v -p codesigning

# 设置签名身份
export CODE_SIGN_IDENTITY="Apple Development: Your Name (XXXXXXXXXX)"
```

### 公证失败

**错误：**
```
The signature of the binary is invalid
```

**解决：**
1. 确保使用 Developer ID 签名
2. 启用 Hardened Runtime
3. 检查 entitlements

### TUN 设备创建失败

**错误：**
```
Failed to create TUN device
```

**解决：**
```bash
# 检查权限
ls -la /dev/tun*

# 使用管理员权限运行
sudo ./JinGo.app/Contents/MacOS/JinGo
```

### 系统扩展被阻止

**解决：**
1. 系统偏好设置 → 安全性与隐私
2. 点击"允许"加载系统扩展
3. 可能需要重启

### Keychain 访问被拒绝

**错误：**
```
SecItemCopyMatching: User interaction is not allowed
```

**解决：**
1. 解锁 Keychain
2. 或在代码中请求用户交互

## 发布

### Mac App Store

1. 使用 Network Extension 模式
2. 配置正确的 entitlements
3. 通过 Xcode 上传
4. 提交审核

### 直接分发

1. 使用 Developer ID 签名
2. 公证应用
3. 创建 DMG
4. 上传到网站

### Homebrew Cask (可选)

```ruby
cask "jingo-vpn" do
  version "1.0.0"
  sha256 "..."

  url "https://example.com/jingo-#{version}.dmg"
  name "JinGo VPN"
  homepage "https://jingo.example.com"

  app "JinGo.app"
end
```

## Entitlements

### 管理员 TUN 模式

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
```

### Network Extension 模式

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
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [iOS 平台指南](08_IOS.md)
- [故障排除](05_TROUBLESHOOTING.md)
