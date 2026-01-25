# OpenSSL 3.0.7 for Android

本目录包含为JinGo Android版本编译的OpenSSL 3.0.7库文件。

## 目录结构

```
android_openssl/
├── arm64-v8a/          # ARM 64位架构 (现代Android设备)
│   ├── libssl_3.so     # SSL库
│   ├── libcrypto_3.so  # 加密库
│   ├── libssl.a        # 静态SSL库
│   └── libcrypto.a     # 静态加密库
├── armeabi-v7a/        # ARM 32位架构 (旧版Android设备)
│   ├── libssl_3.so     # SSL库
│   ├── libcrypto_3.so  # 加密库
│   ├── libssl.a        # 静态SSL库
│   └── libcrypto.a     # 静态加密库
├── x86/                # x86 32位架构 (模拟器)
│   ├── libssl_3.so     # SSL库
│   ├── libcrypto_3.so  # 加密库
│   ├── libssl.a        # 静态SSL库
│   └── libcrypto.a     # 静态加密库
├── x86_64/             # x86 64位架构 (模拟器)
│   ├── libssl_3.so     # SSL库
│   ├── libcrypto_3.so  # 加密库
│   ├── libssl.a        # 静态SSL库
│   └── libcrypto.a     # 静态加密库
├── include/            # OpenSSL头文件
│   └── openssl/
├── build/              # 构建缓存与默认tarball
│   └── android_openssl_3.0.7.tar.gz
├── src/                # OpenSSL源码（如果存在）
└── README.md           # 本文件
```

## 版本信息

- **OpenSSL版本**: 3.0.7
- **支持架构**: arm64-v8a, armeabi-v7a, x86, x86_64
- **最低Android API**: 24 (Android 7.0, 默认值)

## 重新编译

如果需要重新编译OpenSSL库（例如升级版本），运行：

```bash
# 编译所有架构
./third_party/android_openssl/build_android_openssl.sh

# 或只编译特定架构
./third_party/android_openssl/build_android_openssl.sh arm64-v8a
./third_party/android_openssl/build_android_openssl.sh armeabi-v7a x86_64
```

### 编译要求

- Android NDK 27+
- Perl 5
- wget 或 curl
- make

脚本会优先使用环境变量 `ANDROID_NDK` 或 `ANDROID_SDK_ROOT`，并在常见路径中搜索。
当前环境也会尝试 `/Volumes/mindata/Library/Android/aarch64/sdk/ndk`。

### 修改OpenSSL版本

编辑 `third_party/android_openssl/build_android_openssl.sh` 文件，修改：

```bash
OPENSSL_VERSION="3.0.7"  # 改为需要的版本
```

然后运行编译脚本。

## CMake集成

这些库会自动被CMake配置文件识别并打包到APK中：

- `cmake/Platform-Android.cmake` - 配置OpenSSL路径
- `cmake/Platform-Android-Finalize.cmake` - 添加到APK

CMake会根据 `ANDROID_ABI` 变量自动选择正确的架构。

## 默认tarball与环境变量

默认使用 `build/android_openssl_3.0.7.tar.gz`，若不存在会自动下载。

常用环境变量：

- `ANDROID_NDK` / `ANDROID_SDK_ROOT`: NDK路径
- `ANDROID_API_LEVEL`: 最低API级别（默认24）
- `BUILD_SHARED`: 是否构建共享库（默认1）
- `BUILD_STATIC`: 是否构建静态库（默认1）
- `OPENSSL_TARBALL`: 指定OpenSSL tarball路径

## Qt兼容性

这些库与Qt 6.10.0编译时使用的OpenSSL版本匹配（3.0.7），确保运行时版本一致性，避免SSL握手失败。

## 使用注意事项

1. **版本匹配**: 确保OpenSSL版本与Qt编译时使用的版本一致
2. **架构支持**: 编译时选择需要支持的架构以减小APK大小
3. **安全更新**: 定期检查OpenSSL安全公告并更新版本

## 问题排查

### SSL错误: "connection closed"

可能原因：
- OpenSSL版本与Qt不匹配
- SSL库未正确打包到APK
- Android设备加载了系统OpenSSL而非应用的

解决方案：
1. 检查APK中是否包含SSL库：`unzip -l app.apk | grep libssl`
2. 检查CMake日志确认库已配置
3. 查看logcat确认Qt加载的SSL版本

### 编译失败

1. 确认Android NDK已安装并设置 `ANDROID_NDK` 环境变量
2. 确认有Perl 5和make工具
3. 检查网络连接（需要下载OpenSSL源码）

## 参考

- [OpenSSL官网](https://www.openssl.org/)
- [OpenSSL 3.0.7发布说明](https://www.openssl.org/news/openssl-3.0-notes.html)
- [Android NDK文档](https://developer.android.com/ndk)
