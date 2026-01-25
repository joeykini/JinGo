# JinGo VPN - Android 平台指南

## 概述

本文档涵盖 Android 平台的编译、调试和发布。

### 系统要求

| 项目 | 要求 |
|------|------|
| Android SDK | API 28+ (Android 9.0) |
| Android NDK | 26.1.10909125 |
| Java | JDK 17+ |
| Qt | 6.10.0+ (Android 组件) |
| CMake | 3.21+ |

### 支持的架构

| 架构 | 说明 |
|------|------|
| arm64-v8a | 64位 ARM (主流设备) |
| armeabi-v7a | 32位 ARM (旧设备) |
| x86_64 | 64位 x86 (模拟器) |

## 环境配置

### 安装 Android SDK

```bash
# 下载 Android Studio 或命令行工具
# https://developer.android.com/studio

# 设置环境变量
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/26.1.10909125
export JAVA_HOME=/path/to/jdk17
export PATH=$JAVA_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH
```

### 安装 SDK 组件

```bash
# 使用 sdkmanager 安装
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
sdkmanager "ndk;26.1.10909125"
sdkmanager "cmake;3.22.1"
```

### 安装 Qt Android 组件

使用 Qt 在线安装器安装：
- Qt 6.10.0
  - Android (arm64-v8a)
  - Android (armeabi-v7a)
  - Android (x86_64)

## 编译

### 单架构编译

```bash
cd ~/OpineWork/JinGo

# arm64-v8a (推荐)
./scripts/build/build-android.sh --release --abi arm64-v8a

# armeabi-v7a
./scripts/build/build-android.sh --release --abi armeabi-v7a

# x86_64 (模拟器)
./scripts/build/build-android.sh --release --abi x86_64
```

### 全架构编译

```bash
# 编译包含所有架构的 APK
./scripts/build/build-android.sh --release --abi all

# 清理后全架构编译
./scripts/build/build-android.sh --clean --release --abi all
```

### 编译选项

| 选项 | 说明 |
|------|------|
| `--clean` | 清理构建目录 |
| `--debug` | Debug 模式 |
| `--release` | Release 模式 |
| `--abi <ABI>` | 指定架构 (arm64-v8a/armeabi-v7a/x86_64/all) |
| `--sign` | 签名 APK |
| `--brand <NAME>` | 白标定制 |

### 输出目录

```
build-android-arm64/           # 单架构构建目录
build-android-multi/           # 多架构构建目录

release/
└── jingo-*-android.apk        # 发布 APK
```

## 签名

### 生成签名密钥

```bash
keytool -genkey -v \
    -keystore jingo.keystore \
    -alias jingo \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
```

### 签名 APK

```bash
# 编译时签名
./scripts/build/build-android.sh --release --sign

# 手动签名
apksigner sign \
    --ks jingo.keystore \
    --ks-key-alias jingo \
    --out signed.apk \
    unsigned.apk

# 验证签名
apksigner verify signed.apk
```

### 签名配置

创建 `signing.properties`：
```properties
storeFile=jingo.keystore
storePassword=your_store_password
keyAlias=jingo
keyPassword=your_key_password
```

## 安装和调试

### 安装 APK

```bash
# 安装到设备
adb install -r release/jingo-*-android.apk

# 卸载
adb uninstall com.jingo.vpn
```

### 查看日志

```bash
# 过滤 JinGo 日志
adb logcat -s JinGo:V SuperRay-JNI:V Qt:W

# 全部日志
adb logcat | grep -E "JinGo|SuperRay|Qt"

# 保存到文件
adb logcat -s JinGo:V > jingo.log
```

### 调试模式

```bash
# 编译 Debug 版本
./scripts/build/build-android.sh --debug --abi arm64-v8a

# 安装并启动
adb install -r build-android-arm64/android-build/*.apk
adb shell am start -n com.jingo.vpn/.MainActivity
```

## VPN 权限

### AndroidManifest.xml 权限

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<service
    android:name=".JinGoVpnService"
    android:permission="android.permission.BIND_VPN_SERVICE"
    android:exported="false">
    <intent-filter>
        <action android:name="android.net.VpnService" />
    </intent-filter>
</service>
```

### VPN 权限请求

应用首次连接 VPN 时会弹出系统权限对话框，用户需要手动确认。

### Socket 保护

为防止 VPN 流量回环，必须使用 `VpnService.protect()` 保护代理 socket：

```java
// JNI 调用保护 socket
public boolean protectSocket(int fd) {
    return protect(fd);
}
```

## 故障排除

### NDK 找不到

**错误：**
```
CMake Error: Android NDK not found
```

**解决：**
```bash
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/26.1.10909125
```

### Qt Android 组件缺失

**错误：**
```
Could not find Qt6 for Android
```

**解决：**

确保安装了 Qt Android 组件：
```bash
# 检查 Qt 安装
ls $Qt6_DIR/../android_arm64_v8a
```

### APK 安装失败

**错误：**
```
INSTALL_FAILED_UPDATE_INCOMPATIBLE
```

**解决：**
```bash
# 卸载旧版本
adb uninstall com.jingo.vpn

# 重新安装
adb install release/jingo-*-android.apk
```

### VPN 连接失败

**可能原因：**
1. VPN 权限未授予
2. 服务器不可达
3. Socket 未保护

**排查：**
```bash
# 查看 VPN 相关日志
adb logcat -s JinGo:V | grep -i vpn
```

### 应用被后台杀死

**解决：**
1. 添加应用到电池优化白名单
2. 锁定应用在最近任务中
3. 启用前台服务通知

## 发布

### Google Play 发布

1. 生成签名的 Release APK
2. 创建 Google Play 开发者账号
3. 创建应用并上传 APK
4. 填写应用信息和截图
5. 提交审核

### APK 优化

```bash
# 使用 zipalign 优化
zipalign -v 4 input.apk output.apk

# 使用 R8 混淆（自动启用）
```

### 多渠道打包

```bash
# 不同品牌
./scripts/build/build-android.sh --release --brand brand1
./scripts/build/build-android.sh --release --brand brand2
```

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [白标定制](04_WHITE_LABELING.md)
- [故障排除](05_TROUBLESHOOTING.md)
