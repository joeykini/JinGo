# JinGo VPN - Windows 平台指南

## 概述

本文档涵盖 Windows 平台的编译、调试和发布。

### 系统要求

| 项目 | 要求 |
|------|------|
| Windows | 10/11 (64位) |
| Visual Studio | 2022 |
| Qt | 6.10.0+ (MSVC 组件) |
| CMake | 3.21+ |

### 支持的架构

| 架构 | 说明 |
|------|------|
| x64 | 64位 (主流) |

## 环境配置

### 安装 Visual Studio 2022

1. 下载 [Visual Studio 2022](https://visualstudio.microsoft.com/)
2. 选择工作负载："Desktop development with C++"
3. 确保安装 Windows SDK

### 安装 Qt

使用 Qt 在线安装器安装：
- Qt 6.10.0
  - MSVC 2022 64-bit

### 设置环境变量

```powershell
# PowerShell
$env:Qt6_DIR = "C:\Qt\6.10.0\msvc2022_64"
$env:PATH = "$env:Qt6_DIR\bin;$env:PATH"

# 或添加到系统环境变量
[Environment]::SetEnvironmentVariable("Qt6_DIR", "C:\Qt\6.10.0\msvc2022_64", "User")
```

## 编译

### 使用 PowerShell 脚本

```powershell
cd C:\OpineWork\JinGo

# Debug 版本
.\scripts\build\build-windows.ps1 -Debug

# Release 版本
.\scripts\build\build-windows.ps1 -Release

# 清理后编译
.\scripts\build\build-windows.ps1 -Clean -Release
```

### 使用 Developer Command Prompt

```cmd
cd C:\OpineWork\JinGo

:: 配置
cmake -S . -B build-windows -G "Visual Studio 17 2022" -A x64

:: 编译
cmake --build build-windows --config Release

:: 或使用 MSBuild
msbuild build-windows\JinGo.sln /p:Configuration=Release
```

### 编译选项

| 选项 | 说明 |
|------|------|
| `-Clean` | 清理构建目录 |
| `-Debug` | Debug 模式 |
| `-Release` | Release 模式 |
| `-Brand <NAME>` | 白标定制 |

### 输出目录

```
build-windows\
├── Release\
│   └── JinGo.exe          # 可执行文件
└── JinGo.sln              # VS 解决方案

release\
├── jingo-*-windows.exe    # 安装程序
└── jingo-*-windows.zip    # 便携版
```

## WinTun 驱动

JinGo 使用 WinTun 驱动创建虚拟网络设备。

### 自动安装

首次运行时会自动安装 WinTun 驱动。

### 手动安装

```powershell
# 下载 WinTun
Invoke-WebRequest -Uri "https://www.wintun.net/builds/wintun-0.14.1.zip" -OutFile wintun.zip

# 解压
Expand-Archive wintun.zip -DestinationPath wintun

# 复制 DLL (以管理员身份)
Copy-Item wintun\wintun\bin\amd64\wintun.dll C:\Windows\System32\
```

### 验证安装

```powershell
# 检查 DLL
Test-Path C:\Windows\System32\wintun.dll
```

## 调试

### Visual Studio 调试

1. 打开 `build-windows\JinGo.sln`
2. 选择 Debug 配置
3. 按 F5 启动调试

### 命令行调试

```powershell
# 启用 Qt 调试输出
$env:QT_LOGGING_RULES = "*.debug=true"
.\build-windows\Release\JinGo.exe

# 使用 WinDbg
windbg .\build-windows\Release\JinGo.exe
```

### 查看日志

```powershell
# 日志位置
Get-Content "$env:APPDATA\JinGo\logs\*.log"

# 实时查看
Get-Content "$env:APPDATA\JinGo\logs\jingo.log" -Wait
```

## 故障排除

### Qt 找不到

**错误：**
```
Could not find Qt6
```

**解决：**
```powershell
$env:Qt6_DIR = "C:\Qt\6.10.0\msvc2022_64"
```

### MSVC 编译器找不到

**解决：**
```powershell
# 使用 Developer Command Prompt
# 或手动初始化 VS 环境
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

### WinTun 安装失败

**错误：**
```
Failed to install WinTun driver
```

**解决：**
1. 以管理员身份运行
2. 禁用安全软件
3. 手动安装驱动

### DLL 缺失

**错误：**
```
The code execution cannot proceed because VCRUNTIME140.dll was not found
```

**解决：**

安装 Visual C++ Redistributable：
```powershell
# 下载并安装
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile vc_redist.exe
.\vc_redist.exe /install /quiet
```

### 防火墙阻止

**解决：**
```powershell
# 添加防火墙规则 (以管理员身份)
New-NetFirewallRule -DisplayName "JinGo VPN" -Direction Inbound -Program "C:\Program Files\JinGo\JinGo.exe" -Action Allow
New-NetFirewallRule -DisplayName "JinGo VPN" -Direction Outbound -Program "C:\Program Files\JinGo\JinGo.exe" -Action Allow
```

## 发布

### 创建安装程序

使用 Inno Setup 或 NSIS：

```iss
; Inno Setup 脚本示例
[Setup]
AppName=JinGo VPN
AppVersion=1.0.0
DefaultDirName={pf}\JinGo
DefaultGroupName=JinGo VPN
OutputBaseFilename=jingo-setup

[Files]
Source: "build-windows\Release\JinGo.exe"; DestDir: "{app}"
Source: "build-windows\Release\*.dll"; DestDir: "{app}"
Source: "wintun\wintun\bin\amd64\wintun.dll"; DestDir: "{sys}"; Flags: onlyifdoesntexist

[Icons]
Name: "{group}\JinGo VPN"; Filename: "{app}\JinGo.exe"
Name: "{commondesktop}\JinGo VPN"; Filename: "{app}\JinGo.exe"
```

### 创建便携版

```powershell
# 复制所有依赖
windeployqt --release --qmldir qml build-windows\Release\JinGo.exe

# 打包
Compress-Archive -Path build-windows\Release\* -DestinationPath jingo-portable.zip
```

### 代码签名

```powershell
# 使用 signtool
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com JinGo.exe

# 验证签名
signtool verify /pa JinGo.exe
```

### Microsoft Store (可选)

1. 创建 MSIX 包
2. 注册开发者账号
3. 提交到 Microsoft Store

## 安全存储

Windows 使用 DPAPI 进行安全存储：

```cpp
// 使用 Windows Credential Manager
#include <wincred.h>

// 存储凭据
CredWrite(&cred, 0);

// 读取凭据
CredRead(L"JinGo", CRED_TYPE_GENERIC, 0, &pcred);
```

## 系统集成

### 开机启动

```powershell
# 添加到启动项
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\JinGo.lnk")
$Shortcut.TargetPath = "C:\Program Files\JinGo\JinGo.exe"
$Shortcut.Save()
```

### 系统托盘

应用支持最小化到系统托盘，在 `SystemTrayManager` 中实现。

### UAC 提权

```xml
<!-- app.manifest -->
<requestedExecutionLevel level="requireAdministrator" uiAccess="false"/>
```

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [故障排除](05_TROUBLESHOOTING.md)
- [白标定制](04_WHITE_LABELING.md)
