# JinGo VPN - iOS 构建与打包指南

本文档介绍如何在 iOS 平台上构建、打包和分发 JinGo VPN。

## ⚠️ iOS 平台限制

### VPN 模式限制

iOS 上 JinGo VPN **仅支持 TUN 模式**，不支持 Proxy 模式：

| 功能 | iOS | macOS/Windows/Linux |
|------|-----|---------------------|
| TUN 模式 | ✅ 支持 | ✅ 支持 |
| Proxy 模式 | ❌ 需要 MDM | ✅ 支持 |
| Local Proxy | ❌ 沙箱限制 | ✅ 支持 |
| 分应用代理 | ❌ 不支持 | ✅ 支持 (Android) |

**原因说明**：
1. **Local Proxy**: iOS 沙箱限制，其他应用无法访问本应用的本地代理端口
2. **分应用代理**: iOS 的 Network Extension 不支持应用级别的流量控制

### UI 自动隐藏

在 iOS 上，以下 UI 元素会自动隐藏：
- 连接页面的 TUN/Proxy 模式切换开关
- 设置页面的 Local Proxy 端口设置
- 设置页面的分应用代理设置

### App Group 数据共享

iOS 主应用与 Network Extension 通过 App Group 共享数据：
- **App Group ID**: `group.cfd.jingo.acc`
- **共享内容**: 延时信息、IP 信息、流量统计

---

## 📋 前置要求

### 必需工具

1. **macOS**
   - iOS 开发只能在 macOS 上进行

2. **Xcode** (>= 14.0)
   ```bash
   # 从 Mac App Store 安装 Xcode
   # 安装命令行工具
   xcode-select --install
   ```

3. **CMake** (>= 3.20)
   ```bash
   brew install cmake
   ```

4. **Qt for iOS** (>= 6.5)
   - 下载并安装 Qt 6 for iOS: https://www.qt.io/download
   - 确保安装了 iOS 组件

### 开发者账号和证书

#### 免费开发者账号
- 可以在模拟器和个人设备上测试
- 应用有效期 7 天，需要重新签名
- 不能分发给其他用户

#### 付费开发者账号 ($99/年)
- 可以创建 Ad Hoc 和 App Store 分发
- 应用有效期 1 年
- 可以通过 TestFlight 或 App Store 分发

**注册地址**: https://developer.apple.com/programs/

### 证书和 Provisioning Profile

1. **开发证书** (iOS App Development)
   - 用于在设备上测试

2. **分发证书** (iOS Distribution)
   - 用于 Ad Hoc 或 App Store 分发

3. **Provisioning Profile**
   - Development Profile: 开发测试
   - Ad Hoc Profile: 内部分发
   - App Store Profile: App Store 上架

**配置方法**:
1. 打开 Xcode -> Settings -> Accounts
2. 添加 Apple ID
3. 下载 Provisioning Profiles

## 🔨 快速构建

### 方法 1: 使用自动化脚本（推荐）

```bash
# iOS 模拟器构建（快速测试）
./scripts/deploy_ios.sh
# 选择 1

# iOS 真机构建（需要证书）
./scripts/deploy_ios.sh
# 选择 2
```

脚本会自动：
- ✅ 检查所有必需工具
- ✅ 检查证书和 Provisioning Profile
- ✅ 配置 CMake 项目
- ✅ 编译源代码
- ✅ 创建 IPA 安装包（真机）
- ✅ 提供详细的安装说明

### 方法 2: 手动构建

#### 2.1 iOS 模拟器

```bash
# 1. 创建构建目录
mkdir build-ios-simulator && cd build-ios-simulator

# 2. 配置项目
qt-cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"

# 3. 编译
cmake --build . --config Release -j$(sysctl -n hw.ncpu)

# 4. 安装到模拟器
xcrun simctl boot <simulator-id>  # 启动模拟器
xcrun simctl install <simulator-id> bin/JinGo.app
xcrun simctl launch <simulator-id> cfd.jingo.acc
```

#### 2.2 iOS 真机

```bash
# 1. 创建构建目录
mkdir build-ios-device && cd build-ios-device

# 2. 配置项目
qt-cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES="arm64"

# 3. 编译
cmake --build . --config Release -j$(sysctl -n hw.ncpu)

# 4. 创建 IPA
mkdir Payload
cp -R bin/JinGo.app Payload/
zip -r JinGoVPN-1.0.0-iOS.ipa Payload
rm -rf Payload

# 5. 安装到设备（多种方法，见下文）
```

## 📦 应用程序包结构

iOS 构建后的 .app 包结构：

```
JinGo.app/
├── JinGo                       # 可执行文件
├── Info.plist                  # 应用程序元数据
├── PkgInfo                     # 包类型信息
├── Frameworks/                 # 所有依赖框架
│   ├── LibXray.framework/      # Xray 核心
│   ├── QtCore.framework/       # Qt 框架
│   ├── QtGui.framework/
│   ├── QtQml.framework/
│   └── ...
├── PlugIns/                    # Qt 插件
│   ├── platforms/
│   ├── imageformats/
│   └── ...
└── Resources/                  # 资源文件
    ├── translations/           # 翻译文件
    ├── dat/                    # GeoIP/GeoSite 数据
    └── ...
```

## 📱 安装到设备

### 方法 1: Xcode Devices 窗口（推荐）

1. 连接 iOS 设备到 Mac
2. Xcode -> Window -> Devices and Simulators
3. 选择设备
4. 将 .ipa 文件拖拽到 "Installed Apps" 列表
5. 等待安装完成

### 方法 2: 命令行工具

```bash
# 1. 查找设备 UDID
xcrun devicectl list devices

# 2. 安装应用
xcrun devicectl device install app \
  --device <UDID> \
  JinGoVPN-1.0.0-iOS.ipa

# 3. 启动应用
xcrun devicectl device process launch \
  --device <UDID> \
  cfd.jingo.acc
```

### 方法 3: Apple Configurator

1. 从 Mac App Store 安装 Apple Configurator
2. 连接设备
3. 双击设备
4. 点击 "Add" -> "Apps"
5. 选择 .ipa 文件

### 方法 4: iOS App Signer（第三方工具）

用于重新签名 IPA 文件：
- 下载: https://dantheman827.github.io/ios-app-signer/

## 🚀 分发方法

### 1. TestFlight（推荐用于测试）

**优点**：
- 最多 10,000 个外部测试者
- 自动分发和更新
- 收集崩溃报告和反馈
- 90 天测试期

**步骤**：
1. 在 App Store Connect 创建应用
2. 使用 Xcode Archive 创建构建
3. 上传到 App Store Connect
4. 添加测试者邮箱
5. 测试者通过 TestFlight App 安装

**命令行上传**：
```bash
# 使用 Xcode
xcodebuild archive \
  -project JinGo.xcodeproj \
  -scheme JinGo \
  -archivePath JinGo.xcarchive

xcodebuild -exportArchive \
  -archivePath JinGo.xcarchive \
  -exportPath . \
  -exportOptionsPlist ExportOptions.plist

# 上传
xcrun altool --upload-app \
  --type ios \
  --file JinGoVPN.ipa \
  --username your-email@example.com \
  --password app-specific-password
```

### 2. Ad Hoc 分发

**优点**：
- 最多 100 个设备
- 设备 UDID 需要预先注册
- 应用有效期 1 年

**步骤**：
1. 在 Apple Developer 注册设备 UDID
2. 创建 Ad Hoc Provisioning Profile
3. 使用 Ad Hoc Profile 签名应用
4. 分发 IPA 文件给测试者
5. 测试者使用上述方法安装

### 3. Enterprise 分发

**要求**：
- Apple Developer Enterprise Program ($299/年)
- 仅限内部员工使用

**注意**：
- 不能用于公开分发
- 违规可能导致证书被吊销

### 4. App Store

**优点**：
- 公开分发，用户量大
- 自动更新
- Apple 推广

**步骤**：
1. 在 App Store Connect 创建应用记录
2. 填写应用信息和截图
3. 上传构建
4. 提交审核
5. 通过审核后发布

## 🔐 代码签名

### 自动签名（推荐）

在 Xcode 中：
1. 选择项目 -> Signing & Capabilities
2. 勾选 "Automatically manage signing"
3. 选择 Team

### 手动签名

```bash
# 1. 查看可用的签名身份
security find-identity -v -p codesigning

# 2. 签名应用
codesign --sign "iPhone Developer: Your Name (TEAM_ID)" \
  --entitlements JinGo.entitlements \
  --timestamp \
  JinGo.app

# 3. 验证签名
codesign --verify --verbose JinGo.app

# 4. 显示签名信息
codesign -d --entitlements - JinGo.app
```

### Entitlements

iOS VPN 应用需要特殊权限，在 `platform/ios/JinGo.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- VPN 配置权限 -->
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>packet-tunnel-provider</string>
        <string>dns-proxy</string>
    </array>

    <!-- 后台模式 -->
    <key>UIBackgroundModes</key>
    <array>
        <string>network-authentication</string>
    </array>

    <!-- Keychain 访问 -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)cfd.jingo.acc</string>
    </array>
</dict>
</plist>
```

## 🐛 常见问题

### Q1: 编译错误 "Could not find Qt for iOS"

**解决方案**：
```bash
# 确保安装了 Qt for iOS
# 设置 Qt CMake 工具路径
export PATH="/Applications/Qt/6.x.x/ios/bin:$PATH"

# 使用 qt-cmake
qt-cmake ..
```

### Q2: 签名错误 "No signing certificate found"

**解决方案**：
1. Xcode -> Settings -> Accounts
2. 添加 Apple ID
3. 下载证书和 Provisioning Profiles
4. 重新构建

### Q3: 应用安装后打不开，提示"未受信任"

**解决方案**：
1. 设置 -> 通用 -> VPN与设备管理
2. 找到开发者证书
3. 点击"信任"

### Q4: VPN 权限申请失败

**解决方案**：
1. 确保 Bundle ID 正确：`cfd.jingo.acc`
2. 确保 Entitlements 配置正确
3. 在 Apple Developer 网站启用 Network Extensions capability
4. 重新生成 Provisioning Profile

### Q5: 应用在模拟器上运行正常，真机崩溃

**可能原因**：
- 架构不匹配（模拟器是 x86_64/arm64，真机是 arm64）
- 缺少必需的框架或库
- 权限配置不正确

**解决方案**：
1. 检查构建架构配置
2. 使用 Xcode 查看崩溃日志
3. 验证所有依赖都已正确打包

### Q6: LibXray.framework 找不到或加载失败

**解决方案**：
```bash
# 检查框架是否存在
ls -la JinGo.app/Frameworks/LibXray.framework/

# 检查框架签名
codesign -v JinGo.app/Frameworks/LibXray.framework/

# 重新签名
codesign --sign "iPhone Developer" \
  --timestamp \
  JinGo.app/Frameworks/LibXray.framework/
```

## 📝 配置文件

### Info.plist

关键配置项：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>cfd.jingo.acc</string>

    <key>CFBundleDisplayName</key>
    <string>JinGo VPN</string>

    <key>CFBundleVersion</key>
    <string>1.0.0</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>

    <!-- 最低 iOS 版本 -->
    <key>MinimumOSVersion</key>
    <string>14.0</string>

    <!-- VPN 配置 -->
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.networkextension.packet-tunnel</string>
    </dict>

    <!-- 隐私权限说明 -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>JinGo VPN需要访问本地网络以建立VPN连接</string>

    <key>NSVPNUsageDescription</key>
    <string>JinGo VPN需要VPN权限以保护您的网络连接</string>
</dict>
</plist>
```

## 🎯 最佳实践

### 版本管理

1. **版本号规范**：
   - `CFBundleVersion`: 构建号（整数递增）
   - `CFBundleShortVersionString`: 显示版本（x.y.z）

2. **自动递增**：
   ```bash
   # 每次构建自动递增构建号
   BUILD_NUMBER=$(($(date +%Y%m%d%H%M)))
   /usr/libexec/PlistBuddy \
     -c "Set :CFBundleVersion $BUILD_NUMBER" \
     Info.plist
   ```

### 性能优化

1. **编译优化**：
   ```cmake
   set(CMAKE_BUILD_TYPE Release)
   set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
   ```

2. **App Thinning**：
   - App Store 会自动为不同设备优化
   - 只下载需要的架构和资源

3. **资源优化**：
   - 使用 Asset Catalog
   - 压缩图片和资源
   - 按需加载

### 测试

1. **模拟器测试**：
   - 快速迭代
   - 覆盖不同设备和系统版本

2. **真机测试**：
   - 性能测试
   - VPN 功能测试
   - 网络切换测试

3. **TestFlight Beta 测试**：
   - 多用户并发测试
   - 不同网络环境测试
   - 收集真实用户反馈

## 📚 参考资料

- [iOS App Distribution Guide](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/AppDistributionGuide/)
- [Network Extension Programming Guide](https://developer.apple.com/documentation/networkextension)
- [Qt for iOS](https://doc.qt.io/qt-6/ios.html)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

## 🆘 获取帮助

如有问题，请：
1. 查看 Xcode 构建日志
2. 查看设备控制台日志：Xcode -> Window -> Devices and Simulators -> 选择设备 -> View Device Logs
3. 提交 Issue：[GitHub Issues](https://github.com/your-repo/issues)

---

**注意**: VPN 应用在 App Store 上架需要满足额外要求：
- 不能用于绕过地理限制
- 必须有清晰的隐私政策
- 需要说明数据收集和使用方式
- 可能需要额外的审核时间
