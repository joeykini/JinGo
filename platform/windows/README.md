# Windows 平台配置

本目录包含 Windows 平台特定的资源和配置文件。

## 📁 文件说明

### 资源文件

| 文件 | 用途 | 使用方式 |
|-----|------|----------|
| `JinGo.rc` | 主资源文件 | CMake 自动包含到编译中 |
| `app.rc` | 应用程序资源配置 | 由 JinGo.rc 引用 |
| `JinGo.manifest` | 管理员权限清单 | 嵌入到 EXE 中 |

### 图标生成

| 文件 | 用途 |
|-----|------|
| `generate_icon.py` | PNG 转 ICO 工具 |
| `ICON_README.md` | 图标配置详细说明 |
| `icon_usage_example.cpp` | C++ 图标使用示例 |
| `icon_usage_example.qml.txt` | QML 图标使用示例 |

## 🔧 资源文件详解

### JinGo.rc

主资源文件，定义：
- 应用程序图标（`IDI_ICON1`）
- 版本信息（`VS_VERSION_INFO`）
- 包含 `app.rc` 和 `JinGo.manifest`

### app.rc

应用程序资源配置，包含：
- 图标资源定义
- 可自定义其他资源（字符串表、对话框等）

### JinGo.manifest

Windows 应用程序清单文件，配置：
- 管理员权限要求（`requireAdministrator`）
- DPI 感知设置
- Windows 版本兼容性
- 安全策略

**重要**：VPN 应用需要管理员权限来创建虚拟网卡和修改网络配置。

## 🎨 图标配置

### 自动生成

CMake 配置时会自动从 `resources/icons/app.png` 生成 `app.ico`：

```bash
# 源文件
resources/icons/app.png  (512x512 或更大)

# 生成的 ICO 文件
resources/icons/app.ico  (多尺寸: 16, 32, 48, 64, 128, 256)
```

### 手动生成

```bash
# 需要 Pillow 库
pip install Pillow

# 生成图标
python platform/windows/generate_icon.py \
    resources/icons/app.png \
    resources/icons/app.ico
```

详细说明请参考：[ICON_README.md](ICON_README.md)

## 🏗️ 构建说明

### 资源编译

CMake 会自动处理资源文件：

```cmake
# Platform-Windows.cmake 中的配置
if(TARGET_WINDOWS)
    set(PLATFORM_RC platform/windows/JinGo.rc)
    target_sources(JinGo PRIVATE ${PLATFORM_RC})
endif()
```

### RC 编译器

- **MinGW**: 使用 `windres.exe`
- **MSVC**: 使用 `rc.exe`

CMake 会自动选择合适的 RC 编译器。

## 📦 Windows 构建和打包

### 环境要求

1. **Qt 6.10.1 或 6.10.0** (推荐 6.10.1)
   - 安装路径示例：`D:\Qt\6.10.1\mingw_64`
   - 安装路径示例：`C:\Qt\6.10.1\mingw_64`

2. **MinGW 编译器**
   - 通过 Qt Maintenance Tool 安装（推荐）
   - 路径示例：`D:\Qt\Tools\mingw1310_64` 或 `mingw1400_64`

3. **CMake**
   - 通过 Qt Maintenance Tool 安装（推荐）
   - 或从 https://cmake.org/download/ 下载
   - 或使用 winget：`winget install Kitware.CMake`

4. **JinDoCore 静态库**
   - 位置：`third_party/jindo/windows/mingw64/libJinDoCore.a`
   - 头文件：`third_party/jindo/windows/mingw64/include/`
   - 桥接文件：需要以下文件配合 JinDoCore 使用
     - `src/platform/windows/WinTunDriverInstaller.cpp/h` - WinTun 驱动管理
     - `src/utils/RsaCrypto_windows.cpp` - Windows BCrypt 加密实现
   - 注意：已使用静态库替代源码编译，减少编译时间

### 构建脚本

Windows 平台使用以下脚本进行构建和打包：

```bash
# 一键构建和打包（推荐，自动检测环境）
scripts\build\build-windows-wrapper.bat

# 或使用 PowerShell 脚本
scripts\build\build-windows.ps1

# 输出文件：
# - build-windows/bin/JinGo.exe              (可执行文件)
# - build-windows/bin/*.dll                  (运行时依赖，自动复制)
# - pkg/jingo-1.0.0-20260125-windows.zip     (ZIP 便携版)
# - pkg/jingo-1.0.0-20260125-windows.msi     (MSI 安装包，可选)
# - release/jingo-1.0.0-20260125-windows.zip (发布版)
```

### 运行时依赖（自动处理）

构建完成后，以下 DLL 会自动复制到 `build-windows/bin/` 目录：

**Qt 依赖** (由 windeployqt 自动部署)
- Qt6Core.dll, Qt6Gui.dll, Qt6Widgets.dll 等
- Qt 插件和 QML 模块

**MinGW 运行时** (由 CMake POST_BUILD 自动复制)
- libgcc_s_seh-1.dll - GCC 运行时库
- libstdc++-6.dll - C++ 标准库
- libwinpthread-1.dll - pthread 线程库

**VPN 核心库** (由 CMake POST_BUILD 自动复制)
- superray.dll - Xray VPN 核心库（29.5 MB）
- wintun.dll - WinTun 虚拟网卡驱动

**打包时**，所有这些 DLL 会自动包含在 ZIP 和 MSI 包中。

### 构建选项

```bash
# 清理构建
scripts\build\build-windows-wrapper.bat --clean

# Debug 模式
scripts\build\build-windows-wrapper.bat --debug

# 仅构建翻译文件
scripts\build\build-windows-wrapper.bat --translations

# 使用 PowerShell 指定品牌
scripts\build\build-windows.ps1 -Brand jingo

# 更新翻译后构建
scripts\build\build-windows.ps1 -UpdateTranslations
```

### 环境检测

构建脚本会自动检测：
- Qt 安装路径（优先 6.10.1，然后 6.10.0）
- MinGW 编译器路径（支持多个版本）
- CMake（Qt Tools 或系统安装）
- 自动将工具添加到 PATH

**注意**：不需要 MSYS2 环境，使用 Windows CMD 或 PowerShell 即可。

### MSI 安装包

生成 MSI 需要 WiX Toolset 6.0：

```bash
# 安装 WiX
dotnet tool install --global wix

# 构建会自动生成 MSI（如果 WiX 可用）
scripts\build\build-windows-wrapper.bat
```

详细说明请参考：
- [部署脚本说明](../../scripts/README.md)

## 🔐 管理员权限

### 为什么需要管理员权限？

JinGo VPN 需要管理员权限来执行以下操作：
1. 安装 WinTun 虚拟网卡驱动
2. 创建和配置虚拟网络接口
3. 修改系统路由表
4. 配置防火墙规则

### 如何工作？

通过 `JinGo.manifest` 文件请求管理员权限：

```xml
<requestedExecutionLevel
    level="requireAdministrator"
    uiAccess="false" />
```

运行时 Windows 会显示 UAC 提示，要求用户授权。

## 🛠️ 自定义配置

### 修改图标

替换 `resources/icons/app.png`，然后重新生成：

```bash
rm resources/icons/app.ico
python platform/windows/generate_icon.py \
    resources/icons/app.png \
    resources/icons/app.ico
```

### 修改权限要求

编辑 `JinGo.manifest`，修改 `level` 属性：

```xml
<!-- 选项：asInvoker, requireAdministrator, highestAvailable -->
<requestedExecutionLevel level="requireAdministrator" />
```

**注意**：改为 `asInvoker` 会导致 VPN 功能无法正常工作。

### 添加其他资源

在 `app.rc` 中添加自定义资源：

```rc
// 字符串表
STRINGTABLE
BEGIN
    IDS_APP_NAME "JinGo VPN"
    IDS_APP_VERSION "1.0.0"
END

// 自定义数据文件
IDR_CONFIG_FILE RCDATA "config.json"
```

## 📚 参考资料

- [Windows 应用程序清单](https://docs.microsoft.com/en-us/windows/win32/sbscs/application-manifests)
- [资源定义语句](https://docs.microsoft.com/en-us/windows/win32/menurc/resource-definition-statements)
- [WinTun 官方文档](https://www.wintun.net/)
- [MinGW RC 编译器](https://sourceware.org/binutils/docs/binutils/windres.html)

## 🆘 常见问题

### Q: 图标没有正确显示？

A: 确保：
1. `app.ico` 文件存在且有效
2. 重新编译项目
3. 清空图标缓存：`ie4uinit.exe -ClearIconCache`

### Q: 运行时没有请求管理员权限？

A: 检查：
1. `JinGo.manifest` 是否正确嵌入到 EXE
2. 使用 `mt.exe` 查看清单：
   ```bash
   mt.exe -inputresource:JinGo.exe -out:manifest.xml
   ```

### Q: RC 编译失败？

A: 常见原因：
1. 路径包含非 ASCII 字符
2. 文件编码问题（使用 UTF-8 BOM）
3. MinGW 工具链未正确配置

---

**维护者**: JinGo Team
**最后更新**: 2025-01-25
**适用版本**: JinGo VPN 1.0.0+
