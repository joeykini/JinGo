# JinGo VPN - macOS 构建与打包指南

本文档介绍如何在 macOS 平台上构建、打包和分发 JinGo VPN。

## 📋 前置要求

### 必需工具

1. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **CMake** (>= 3.20)
   ```bash
   brew install cmake
   ```

3. **Qt 6** (>= 6.5)
   - 下载并安装 Qt 6 for macOS: https://www.qt.io/download
   - 或使用 Homebrew: `brew install qt@6`
   - 确保 `qt-cmake` 和 `macdeployqt` 在 PATH 中

4. **Python 3** (可选，用于生成图标)
   ```bash
   brew install python3
   pip3 install Pillow
   ```

### 依赖库

项目已包含所有必需的第三方库：

- **LibXray.framework**: `third_party/libxray/apple/LibXray.xcframework/macos-arm64_x86_64/`
- **libhev-socks5-tunnel.a**: `third_party/hev-socks5-tunnel/apple/HevSocks5Tunnel.xcframework/macos-arm64_x86_64/`

## 🔨 快速构建

### 方法 1: 使用自动化脚本（推荐）

```bash
# 构建并打包为 DMG
./scripts/deploy_macos.sh

# 或指定自定义构建目录
./scripts/deploy_macos.sh /path/to/build
```

该脚本会自动：
- ✅ 配置 CMake 项目（Universal Binary: arm64 + x86_64）
- ✅ 编译源代码
- ✅ 复制 LibXray.framework 到 .app 包
- ✅ 运行 macdeployqt 打包 Qt 依赖
- ✅ 生成 DMG 安装包

### 方法 2: 手动构建

```bash
# 1. 创建构建目录
mkdir build-macos && cd build-macos

# 2. 配置项目（Universal Binary）
qt-cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_PACKAGING=ON \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

# 3. 编译（使用所有 CPU 核心）
cmake --build . --config Release -j$(sysctl -n hw.ncpu)

# 4. 运行 macdeployqt（如果构建时未自动执行）
macdeployqt JinGo.app -verbose=1 -qmldir=../resources/qml

# 5. 创建 DMG
cpack -G DragNDrop
```

## 📦 应用程序包结构

构建完成后，`JinGo.app` 的目录结构如下：

```
JinGo.app/
├── Contents/
│   ├── Info.plist                    # 应用程序元数据
│   ├── MacOS/
│   │   └── JinGo                     # 主可执行文件
│   ├── Resources/
│   │   ├── app.icns                  # 应用程序图标
│   │   ├── translations/             # 翻译文件 (.qm)
│   │   │   ├── jingo_zh_CN.qm
│   │   │   ├── jingo_en_US.qm
│   │   │   └── ...
│   │   └── dat/                      # GeoIP/GeoSite 数据
│   │       ├── geoip.dat
│   │       └── geosite.dat
│   └── Frameworks/                   # 所有依赖库
│       ├── LibXray.framework/        # Xray 核心（由 CMake 复制）
│       ├── QtCore.framework/         # Qt 框架（由 macdeployqt 复制）
│       ├── QtGui.framework/
│       ├── QtQml.framework/
│       ├── QtQuick.framework/
│       └── ...                       # 其他 Qt 依赖
```

## 🔍 验证应用程序包

### 检查依赖关系

```bash
# 检查主可执行文件的依赖
otool -L JinGo.app/Contents/MacOS/JinGo

# 应该看到类似输出:
#   @rpath/QtCore.framework/Versions/A/QtCore
#   @rpath/QtGui.framework/Versions/A/QtGui
#   @rpath/LibXray.framework/LibXray
```

### 检查 RPATH 设置

```bash
# 查看 RPATH（运行时库搜索路径）
otool -l JinGo.app/Contents/MacOS/JinGo | grep -A 2 LC_RPATH

# 应该包含:
#   path @executable_path/../Frameworks
```

### 测试运行

```bash
# 直接运行应用程序
open JinGo.app

# 或从命令行运行（可看到日志）
./JinGo.app/Contents/MacOS/JinGo
```

## 📀 DMG 打包

### 使用 CPack（自动）

CMakeLists.txt 已配置了 CPack 支持，运行：

```bash
cd build-macos
cpack -G DragNDrop
```

生成的 DMG 文件特性：
- 📦 格式：UDBZ (bzip2 压缩，体积小)
- 🏷️ 卷标：JinGoVPN
- 📁 包含：JinGo.app 和所有依赖

### 手动创建 DMG（可选）

如果需要自定义 DMG 布局：

```bash
# 创建简单的 DMG
hdiutil create -volname "JinGoVPN" \
  -srcfolder JinGo.app \
  -ov -format UDBZ \
  JinGoVPN-1.0.0.dmg

# 创建带背景图和应用程序链接的高级 DMG
# 1. 创建临时文件夹
mkdir dmg-temp
cp -R JinGo.app dmg-temp/
ln -s /Applications dmg-temp/Applications

# 2. 创建 DMG
hdiutil create -volname "JinGoVPN" \
  -srcfolder dmg-temp \
  -ov -format UDBZ \
  JinGoVPN-1.0.0.dmg

rm -rf dmg-temp
```

## 🔐 代码签名与公证（分发用）

如果要在 Mac App Store 之外分发，需要签名和公证：

### 1. 签名应用程序

```bash
# 签名应用程序包（需要 Apple Developer ID）
codesign --deep --force \
  --options runtime \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  JinGo.app

# 验证签名
codesign --verify --verbose JinGo.app
spctl --assess --verbose JinGo.app
```

### 2. 签名 DMG

```bash
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
  JinGoVPN-1.0.0.dmg

# 验证 DMG 签名
codesign --verify --verbose JinGoVPN-1.0.0.dmg
```

### 3. 公证（Notarization）

```bash
# 上传到 Apple 公证服务
xcrun notarytool submit JinGoVPN-1.0.0.dmg \
  --apple-id your-email@example.com \
  --team-id TEAM_ID \
  --password APP_SPECIFIC_PASSWORD \
  --wait

# 绑定公证票据
xcrun stapler staple JinGoVPN-1.0.0.dmg

# 验证公证
spctl --assess --type open --context context:primary-signature \
  --verbose JinGoVPN-1.0.0.dmg
```

## 🐛 常见问题

### Q1: macdeployqt 未找到

**解决方案**：
```bash
# 添加 Qt 的 bin 目录到 PATH
export PATH="/path/to/Qt/6.x.x/macos/bin:$PATH"

# 或使用完整路径
/path/to/Qt/6.x.x/macos/bin/macdeployqt JinGo.app
```

### Q2: 应用程序无法启动，提示缺少库

**解决方案**：
1. 确保运行了 `macdeployqt`
2. 检查 `JinGo.app/Contents/Frameworks/` 目录是否包含 Qt 框架
3. 验证 LibXray.framework 是否已复制

```bash
# 检查缺少的依赖
otool -L JinGo.app/Contents/MacOS/JinGo | grep -v "@rpath" | grep -v "/usr/lib"
```

### Q3: 应用程序在其他 Mac 上无法运行

**可能原因**：
- 缺少依赖库 → 运行 macdeployqt
- 未签名 → 签名应用程序
- 需要公证 → 完成公证流程
- 最低系统版本不匹配 → 检查 `CMAKE_OSX_DEPLOYMENT_TARGET` (默认 10.15)

### Q4: DMG 创建失败

**解决方案**：
```bash
# 清理旧的构建文件
rm -rf build-macos/_CPack_Packages

# 重新运行 CPack
cd build-macos
cpack -G DragNDrop --verbose
```

### Q5: 在 Apple Silicon (M1/M2) Mac 上运行 Intel 版本报错

**解决方案**：
构建 Universal Binary（同时支持 arm64 和 x86_64）：
```bash
qt-cmake .. -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

检查架构：
```bash
lipo -info JinGo.app/Contents/MacOS/JinGo
# 应输出: Architectures in the fat file: ... are: x86_64 arm64
```

## 📝 自定义配置

### 修改应用程序图标

编辑 `platform/macos/Info.plist` 和替换 `resources/icons/app.icns`：

```bash
# 从 PNG 生成 ICNS（需要 512x512 或更大的 PNG）
mkdir app.iconset
sips -z 16 16     app.png --out app.iconset/icon_16x16.png
sips -z 32 32     app.png --out app.iconset/icon_16x16@2x.png
sips -z 32 32     app.png --out app.iconset/icon_32x32.png
sips -z 64 64     app.png --out app.iconset/icon_32x32@2x.png
sips -z 128 128   app.png --out app.iconset/icon_128x128.png
sips -z 256 256   app.png --out app.iconset/icon_128x128@2x.png
sips -z 256 256   app.png --out app.iconset/icon_256x256.png
sips -z 512 512   app.png --out app.iconset/icon_256x256@2x.png
sips -z 512 512   app.png --out app.iconset/icon_512x512.png
sips -z 1024 1024 app.png --out app.iconset/icon_512x512@2x.png

iconutil -c icns app.iconset
mv app.icns resources/icons/
rm -rf app.iconset
```

### 修改 DMG 背景

创建 `platform/macos/dmg_background.png` (至少 600x400 像素)

### 调整最低系统版本

编辑 CMakeLists.txt:
```cmake
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15" CACHE STRING "Minimum macOS version")
# 可改为 "11.0", "12.0" 等
```

## 📚 参考资料

- [Qt macOS Deployment](https://doc.qt.io/qt-6/macos-deployment.html)
- [CMake CPack DragNDrop](https://cmake.org/cmake/help/latest/cpack_gen/dmg.html)
- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

## 🆘 获取帮助

如有问题，请：
1. 查看构建日志：`build-macos/CMakeFiles/CMakeOutput.log`
2. 查看错误日志：`build-macos/CMakeFiles/CMakeError.log`
3. 提交 Issue：[GitHub Issues](https://github.com/your-repo/issues)
