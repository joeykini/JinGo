# JinGo VPN - 白标定制指南

## 概述

JinGo VPN 支持完整的白标定制，允许创建独立品牌的 VPN 应用，包括：

- 品牌名称和标识
- 应用图标和启动画面
- 颜色主题
- API 服务器配置
- 应用商店配置

## 白标目录结构

```
white-labeling/
├── brand1/                    # 品牌1
│   ├── brand_config.json      # 品牌配置
│   ├── icons/                 # 图标资源
│   │   ├── icon.png          # 主图标 (1024x1024)
│   │   ├── icon-android/     # Android 各尺寸
│   │   └── icon-ios/         # iOS 各尺寸
│   ├── splash/               # 启动画面
│   │   ├── splash.png
│   │   └── splash@2x.png
│   └── theme/                # 主题资源
│       └── colors.json
├── brand2/                    # 品牌2
│   └── ...
└── default/                   # 默认品牌
    └── ...
```

## 品牌配置文件

### brand_config.json

```json
{
  "brand_id": "mybrand",
  "brand_name": "MyBrand VPN",
  "brand_display_name": "MyBrand",
  "version": "1.0.0",

  "api": {
    "base_url": "https://api.mybrand.com",
    "websocket_url": "wss://ws.mybrand.com"
  },

  "app_store": {
    "android": {
      "package_name": "com.mybrand.vpn",
      "store_url": "https://play.google.com/store/apps/details?id=com.mybrand.vpn"
    },
    "ios": {
      "bundle_id": "com.mybrand.vpn",
      "app_id": "123456789",
      "store_url": "https://apps.apple.com/app/id123456789"
    },
    "macos": {
      "bundle_id": "com.mybrand.vpn.macos",
      "app_id": "987654321"
    }
  },

  "theme": {
    "primary_color": "#007AFF",
    "accent_color": "#34C759",
    "background_color": "#FFFFFF",
    "text_color": "#000000",
    "dark_mode": {
      "background_color": "#1C1C1E",
      "text_color": "#FFFFFF"
    }
  },

  "features": {
    "enable_registration": true,
    "enable_social_login": false,
    "enable_referral": true,
    "enable_tickets": true,
    "enable_announcements": true
  },

  "legal": {
    "privacy_policy_url": "https://mybrand.com/privacy",
    "terms_of_service_url": "https://mybrand.com/terms",
    "support_email": "support@mybrand.com"
  }
}
```

## 创建新品牌

### 1. 复制模板

```bash
cd white-labeling
cp -r default mybrand
```

### 2. 修改配置

编辑 `mybrand/brand_config.json`，更新所有品牌信息。

### 3. 替换图标

#### 主图标要求

| 平台 | 尺寸 | 格式 | 文件名 |
|------|------|------|--------|
| 源文件 | 1024x1024 | PNG | icon.png |
| Android | 多尺寸 | PNG | mipmap-* |
| iOS | 多尺寸 | PNG | AppIcon.appiconset |
| macOS | 多尺寸 | ICNS | AppIcon.icns |
| Windows | 多尺寸 | ICO | app.ico |

#### 生成多尺寸图标

```bash
# 使用脚本生成
./scripts/generate-icons.sh mybrand

# 或手动生成
# Android: 48, 72, 96, 144, 192, 512
# iOS: 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
```

### 4. 自定义启动画面

```bash
# 替换启动画面
cp my_splash.png mybrand/splash/splash.png
cp my_splash@2x.png mybrand/splash/splash@2x.png
```

## 编译白标应用

### Android

```bash
./scripts/build/build-android.sh --release --brand mybrand
```

### iOS

```bash
./scripts/build/build-ios.sh --release --brand mybrand
```

### macOS

```bash
./scripts/build/build-macos.sh --release --brand mybrand
```

### 全平台

```bash
./scripts/build/build-all.sh --release --brand mybrand
```

## 主题定制

### QML 主题变量

主题颜色通过 `BundleConfig` 暴露给 QML：

```qml
// 使用品牌颜色
Rectangle {
    color: bundleConfig.primaryColor
}

Button {
    background: Rectangle {
        color: bundleConfig.accentColor
    }
}

Text {
    color: bundleConfig.textColor
}
```

### 自定义组件样式

```qml
// qml/theme/BrandTheme.qml
pragma Singleton
import QtQuick

QtObject {
    // 从品牌配置读取
    readonly property color primary: bundleConfig.primaryColor
    readonly property color accent: bundleConfig.accentColor
    readonly property color background: bundleConfig.backgroundColor

    // 派生颜色
    readonly property color primaryLight: Qt.lighter(primary, 1.2)
    readonly property color primaryDark: Qt.darker(primary, 1.2)

    // 字体
    readonly property font titleFont: Qt.font({
        family: "SF Pro Display",
        pixelSize: 24,
        weight: Font.Bold
    })
}
```

## 多租户部署

### 服务器端配置

每个品牌可以配置独立的 API 服务器：

```json
{
  "api": {
    "base_url": "https://api.brand1.com",
    "auth_endpoint": "/v1/auth",
    "subscription_endpoint": "/v1/subscription"
  }
}
```

### 数据隔离

- 每个品牌使用独立的数据库
- 用户数据完全隔离
- 订阅和支付独立管理

## 应用签名

### Android 签名

```bash
# 生成品牌专用密钥
keytool -genkey -v \
    -keystore mybrand.keystore \
    -alias mybrand \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000

# 编译时使用
./scripts/build/build-android.sh --release --brand mybrand --sign
```

### iOS/macOS 签名

1. 在 Apple Developer 创建品牌专用 App ID
2. 创建对应的 Provisioning Profile
3. 配置 Xcode 签名设置

```bash
export APPLE_TEAM_ID="BRAND_TEAM_ID"
export CODE_SIGN_IDENTITY="Apple Distribution: Brand Name"
./scripts/build/build-ios.sh --release --brand mybrand
```

## 应用商店提交

### Google Play

1. 使用品牌 package name 创建应用
2. 上传品牌 APK/AAB
3. 配置商店页面（使用品牌资源）

### App Store

1. 在 App Store Connect 创建应用
2. 使用品牌 Bundle ID
3. 上传品牌 IPA
4. 配置 App Store 页面

## 配置验证

### 验证配置文件

```bash
# 验证品牌配置
./scripts/validate-brand.sh mybrand

# 检查项目:
# - JSON 格式正确
# - 必需字段存在
# - 图标尺寸正确
# - URL 可访问
```

### 测试品牌应用

```bash
# 编译测试版本
./scripts/build/build-android.sh --debug --brand mybrand

# 安装测试
adb install -r release/mybrand-debug.apk
```

## 常见问题

### 图标显示不正确

1. 检查图标尺寸是否完整
2. 清理构建缓存重新编译
3. 卸载旧版本再安装

### 主题颜色不生效

1. 检查 `brand_config.json` 格式
2. 确认颜色值格式正确（#RRGGBB）
3. 重新编译应用

### API 连接失败

1. 验证 API URL 配置
2. 检查 SSL 证书
3. 确认服务器允许该品牌访问

## 下一步

- [构建指南](02_BUILD_GUIDE.md) - 了解详细编译流程
- [故障排除](05_TROUBLESHOOTING.md) - 解决常见问题
