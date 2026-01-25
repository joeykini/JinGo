# White-Labeling 白标定制

此目录包含白标定制配置，每个子目录代表一个平台/客户的定制内容。

## 平台目录映射

| 目录 | 平台 | 默认 License |
|------|------|--------------|
| 1 | Windows | LIC-5L3U-DZ9C-XL3A-FMVQ |
| 2 | macOS | LIC-3F8Z-NUJK-IBVI-E6XJ |
| 3 | Android | LIC-VEGA-X5EL-6PMX-N3S3 |
| 4 | Linux | LIC-VT0G-C7X5-1TYN-KV7C |
| 5 | iOS | LIC-B4YY-JCDC-6I8F-SERG |

## 目录结构

```
white-labeling/
├── README.md                    # 本说明文件
├── 1/                           # Windows 品牌
│   ├── bundle_config.json       # 签名配置文件
│   ├── license_public_key.pem   # RSA 公钥（用于签名验证）
│   └── icons/                   # 图标资源
│       ├── logo.png             # 应用内 Logo
│       ├── app.icns             # macOS 图标
│       ├── app.ico              # Windows 图标
│       ├── app.png              # Linux 图标
│       ├── ios/                 # iOS 图标集
│       │   ├── Contents.json
│       │   ├── icon-1024.png
│       │   └── ...
│       └── android/             # Android 图标集
│           ├── mipmap-mdpi/ic_launcher.png
│           ├── mipmap-hdpi/ic_launcher.png
│           └── ...
├── 2/                           # macOS 品牌
├── 3/                           # Android 品牌
├── 4/                           # Linux 品牌
└── 5/                           # iOS 品牌
```

## 白标包内容

从后台生成白标包时，会创建以下文件：

| 文件 | 说明 |
|------|------|
| `bundle_config.json` | 签名配置（包含 license、API 地址等） |
| `license_public_key.pem` | 用户的 RSA 公钥（用于验证配置签名） |
| `icons/` | 各平台图标资源 |

## bundle_config.json 配置说明

配置文件必须包含 `__signed` 字段和签名信息，开发和生产环境均需要签名验证。

```json
{
    "__signed": true,
    "__version": "1.0",
    "__algorithm": "RSA-SHA256",
    "__signed_at": "2026-01-12T03:54:19Z",
    "config": {
        "panelUrl": "https://cp.example.com",
        "appName": "MyVPN",
        "supportEmail": "support@example.com",
        "privacyPolicyUrl": "https://example.com/privacy",
        "termsOfServiceUrl": "https://example.com/terms",
        "telegramUrl": "https://t.me/example",
        "discordUrl": "https://discord.gg/example",
        "hideSubscriptionBlock": true,
        "docsUrl": "https://docs.example.com",
        "issuesUrl": "https://github.com/example/issues",
        "latencyTestUrl": "https://www.google.com/generate_204",
        "ipInfoUrl": "https://ipinfo.io/json",
        "speedTestBaseUrl": "https://speed.cloudflare.com/__down?bytes=",
        "updateCheckUrl": "https://api.github.com/repos/example/releases/latest",
        "licenseUrl": "https://github.com/example/blob/main/LICENSE",

        "license": {
            "licenseId": "LIC-XXXX-XXXX-XXXX-XXXX",
            "vendorId": "your_vendor_id",
            "vendorName": "Your Vendor Name",
            "issuedAt": "2026-01-12T11:54:19+08:00"
        },

        "licenseServer": {
            "baseUrl": "https://license.example.com",
            "checkInterval": 86400,
            "offlineGracePeriod": 604800
        }
    },
    "signature": "BASE64_ENCODED_RSA_SHA256_SIGNATURE"
}
```

签名使用 RSA-SHA256 算法，对 `config` 对象的 JSON 字符串进行签名。

### 配置字段说明

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `panelUrl` | 后端 API 地址 | `https://api.example.com` |
| `appName` | 应用显示名称 | `JinGo VPN` |
| `supportEmail` | 支持邮箱 | - |
| `privacyPolicyUrl` | 隐私政策链接 | - |
| `termsOfServiceUrl` | 服务条款链接 | - |
| `telegramUrl` | Telegram 群组链接 | - |
| `discordUrl` | Discord 服务器链接 | - |
| `docsUrl` | 文档链接 | - |
| `issuesUrl` | 问题反馈链接 | - |
| `hideSubscriptionBlock` | 是否隐藏订阅区块 | `false` |
| `latencyTestUrl` | 延迟测试 URL | `https://www.google.com/generate_204` |
| `ipInfoUrl` | IP 信息查询 URL | `https://ipinfo.io/json` |
| `speedTestBaseUrl` | 测速基础 URL | `https://speed.cloudflare.com/__down?bytes=` |
| `updateCheckUrl` | 更新检查 URL | - |
| `licenseUrl` | 许可证链接 | - |

### 授权配置

| 字段 | 说明 |
|------|------|
| `license.licenseId` | 授权 ID（每个平台不同） |
| `license.vendorId` | 供应商 ID |
| `license.vendorName` | 供应商名称 |
| `license.issuedAt` | 签发时间 |
| `licenseServer.baseUrl` | 授权服务器 URL（默认：`https://license.opine.work`） |
| `licenseServer.checkInterval` | 授权检查间隔（秒，默认：86400 = 24小时） |
| `licenseServer.offlineGracePeriod` | 离线宽限期（秒，默认：604800 = 7天） |

## 公钥验证

构建时会自动将 `license_public_key.pem` 的内容嵌入到 `src/utils/RsaCrypto.cpp` 中的 `EMBEDDED_PUBLIC_KEY`，用于验证 `bundle_config.json` 的签名。

**重要**: 每个用户/供应商的公钥不同，必须确保公钥与签名配置匹配。

## 图标尺寸要求

### iOS 图标
- 1024x1024 (App Store)
- 180x180 (icon-60@3x, iPhone @3x)
- 120x120 (icon-60@2x, icon-40@3x, iPhone @2x)
- 167x167 (Icon-83.5@2x, iPad Pro @2x)
- 152x152 (Icon-76@2x, iPad @2x)
- 87x87 (icon-29@3x)
- 80x80 (icon-40@2x)
- 76x76 (Icon-76, iPad @1x)
- 60x60 (icon-20@3x)
- 58x58 (icon-29@2x)
- 40x40 (Icon-40, icon-20@2x)
- 29x29 (Icon-29)
- 20x20 (Icon-20)

### Android 图标
| 目录 | 尺寸 |
|------|------|
| mipmap-xxxhdpi | 192x192 |
| mipmap-xxhdpi | 144x144 |
| mipmap-xhdpi | 96x96 |
| mipmap-hdpi | 72x72 |
| mipmap-mdpi | 48x48 |

### macOS 图标 (.icns)
包含多种尺寸：16, 32, 64, 128, 256, 512, 1024

### Windows 图标 (.ico)
包含多种尺寸：16, 32, 48, 64, 128, 256

### Linux 图标
- 建议提供 512x512 PNG

### Logo
- 建议提供 512x512 或更大的 PNG

## 使用方法

### 编译特定平台（使用默认品牌）

每个平台的构建脚本会自动使用对应的默认品牌：

```bash
# Windows (默认品牌 1)
.\scripts\build\build-windows.ps1

# macOS (默认品牌 2)
./scripts/build/build-macos.sh

# Android (默认品牌 3)
./scripts/build/build-android.sh

# Linux (默认品牌 4)
./scripts/build/build-linux.sh

# iOS (默认品牌 5)
./scripts/build/build-ios.sh
```

### 指定品牌编译

```bash
# 使用命令行参数
./scripts/build/build-macos.sh --brand 2

# 或使用环境变量
BRAND_NAME=2 ./scripts/build/build-macos.sh

# Windows PowerShell
$env:BRAND_NAME="1"; .\scripts\build\build-windows.ps1
# 或
.\scripts\build\build-windows.ps1 -Brand 1
```

**优先级**: 命令行参数 > 环境变量 `BRAND_NAME` > 平台默认值

### 创建新品牌

1. 在后台生成白标包，下载包含以下文件：
   - `bundle_config.json` - 签名配置
   - `license_public_key.pem` - RSA 公钥
   - `icons/` - 图标资源
2. 将文件放入 `white-labeling/<brand_id>/` 目录
3. 运行构建脚本时指定品牌 ID

### 配置文件查找路径

应用启动时会按以下顺序查找 `bundle_config.json`：

| 平台 | 查找路径 |
|------|----------|
| macOS | `<Bundle>/Contents/Resources/bundle_config.json`<br>`<Bundle>/bundle_config.json` |
| iOS | `<Bundle>/bundle_config.json` |
| Android | `assets:/bundle_config.json`<br>`:/bundle_config.json` |
| Windows | `<exe目录>/bundle_config.json`<br>`<exe目录>/resources/bundle_config.json` |
| Linux | `<exe目录>/bundle_config.json`<br>`<exe目录>/resources/bundle_config.json`<br>`/usr/share/jingo/bundle_config.json`<br>`/usr/local/share/jingo/bundle_config.json` |

## 构建流程

构建脚本会自动执行以下步骤：

1. **复制 bundle_config.json** → `resources/bundle_config.json`
2. **复制图标** → `resources/icons/`、`platform/ios/`、`platform/android/`
3. **替换公钥** → 将 `license_public_key.pem` 内容嵌入 `src/utils/RsaCrypto.cpp`
4. **编译应用**

## 注意事项

1. 图标替换时请保持原有尺寸
2. iOS 图标必须符合 Apple 规范（无透明度、圆角由系统处理）
3. Android 图标建议使用自适应图标格式
4. 修改 Bundle ID 会影响应用签名和分发
5. 配置文件必须包含 `__signed` 字段和有效签名，否则应用将拒绝加载配置
6. **公钥必须与签名配置匹配**，否则验证将失败
7. 授权信息由 `LicenseManager` 从服务器动态验证
