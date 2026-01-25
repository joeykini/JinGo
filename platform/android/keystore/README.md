# JinGo Android Release Keystore

## Keystore 信息

- **文件名**: `jingo-release.keystore`
- **别名 (Alias)**: `jingo`
- **密钥算法**: RSA 2048-bit
- **签名算法**: SHA384withRSA
- **有效期**: 10000 天（约27年，到 2053年4月15日）
- **证书类型**: 自签名证书

## 证书详情

- **所有者 (Owner)**:
  - CN=JinGo VPN
  - OU=Development
  - O=OpineWork
  - L=Shanghai
  - ST=Shanghai
  - C=CN

## 密码信息

⚠️ **重要**: 请妥善保管以下密码

- **Keystore 密码**: `jingo1101`
- **Key 密码**: `jingo1101`

## SHA-256 指纹

```
7E:23:51:80:B3:11:95:09:12:BB:28:28:E1:03:47:43:40:9C:08:F3:DA:4F:CF:B7:4E:90:F1:2F:35:B0:AD:D8
```

## SHA-1 指纹

```
71:99:63:70:AA:B0:30:1F:C3:74:32:CB:C0:B6:5F:89:A0:BD:0D:FC
```

## 使用说明

### 手动签名 APK

```bash
# 使用 jarsigner 签名
jarsigner -verbose \
  -sigalg SHA256withRSA \
  -digestalg SHA256 \
  -keystore platform/android/keystore/jingo-release.keystore \
  -storepass jingo1101 \
  -keypass jingo1101 \
  your-app.apk jingo

# 或使用 apksigner (推荐)
apksigner sign \
  --ks platform/android/keystore/jingo-release.keystore \
  --ks-key-alias jingo \
  --ks-pass pass:jingo1101 \
  --key-pass pass:jingo1101 \
  your-app.apk
```

### Gradle 配置

在 `build.gradle` 中配置：

```gradle
android {
    signingConfigs {
        release {
            storeFile file("../../platform/android/keystore/jingo-release.keystore")
            storePassword "jingo1101"
            keyAlias "jingo"
            keyPassword "jingo1101"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

## 安全建议

1. ✅ 已生成 - 用于开发测试
2. ⚠️ **生产环境建议**:
   - 使用更强的密码
   - 将密码存储在环境变量或密钥管理系统中
   - 不要将 keystore 文件提交到公开的代码仓库
   - 定期备份 keystore 文件

3. 🔒 **保护措施**:
   - 已添加到 `.gitignore`
   - 建议加密存储
   - 仅授权人员访问

## 备份

⚠️ **重要**: 如果丢失此 keystore，将无法更新已发布的应用！

建议：
1. 将 keystore 文件备份到安全的位置
2. 记录所有密码信息
3. 保存证书指纹信息

## 创建日期

2025-12-19

## 注意事项

- 此 keystore 用于 JinGo VPN Android 应用的 release 版本签名
- 所有通过 Google Play 或其他应用商店发布的版本都必须使用此 keystore 签名
- 更换 keystore 将导致用户无法正常更新应用
