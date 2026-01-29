# OpenSSL 3.0.7 for Apple (XCFramework)

本目录包含为 Apple 平台构建的 OpenSSL 3.0.7 XCFramework。

## 目录结构

```
apple_openssl/
├── build/                       # 构建缓存与默认tarball
│   └── android_openssl_3.0.7.tar.gz
├── include/                     # OpenSSL头文件
│   └── openssl/
├── libcrypto.xcframework/       # 静态库 XCFramework
├── libssl.xcframework/          # 静态库 XCFramework
└── build_xcframework.sh         # 构建脚本
```

## 重新编译

```bash
./third_party/apple_openssl/build_xcframework.sh
```

## 产物

- `libcrypto.xcframework`
- `libssl.xcframework`
- `include/openssl`

XCFramework 内包含：
- macOS: arm64 / x86_64
- iOS device: arm64
- iOS simulator: arm64 / x86_64

## 构建要求

- macOS + Xcode
- clang / xcodebuild / lipo
- curl

## 默认 tarball 与环境变量

默认使用 `build/android_openssl_3.0.7.tar.gz`，若不存在会自动下载。

常用环境变量：
- `OPENSSL_VERSION` (默认 3.0.7)
- `OPENSSL_TARBALL` (指定 tarball 路径)
- `OPENSSL_CONFIG_OPTS` (自定义 OpenSSL Configure 选项)

## 清理说明

脚本完成后会清理 `build/` 下的临时目录，但会保留默认 tarball。
