# JinGo VPN - Linux 平台指南

## 概述

本文档涵盖 Linux 平台的编译、运行和故障排除。

### 系统要求

| 项目 | 要求 |
|------|------|
| 发行版 | Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux |
| 架构 | x86_64 (64位) |
| 内存 | 2GB RAM |
| 磁盘 | 500MB 可用空间 |
| Qt | 6.10.0+ |
| CMake | 3.21+ |

## 依赖安装

### Ubuntu/Debian

```bash
# 更新包列表
sudo apt update

# 安装编译工具
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    git

# 安装系统库
sudo apt install -y \
    libglib2.0-dev \
    libsecret-1-dev \
    libssl-dev \
    libgl1-mesa-dev \
    libxcb1-dev \
    libxcb-*-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libdbus-1-dev
```

### Fedora/RHEL

```bash
# 安装编译工具
sudo dnf install -y \
    @development-tools \
    cmake \
    ninja-build \
    git

# 安装系统库
sudo dnf install -y \
    glib2-devel \
    libsecret-devel \
    openssl-devel \
    mesa-libGL-devel \
    libxcb-devel \
    xcb-util-*-devel \
    libxkbcommon-devel \
    libxkbcommon-x11-devel \
    dbus-devel
```

### Arch Linux

```bash
# 安装编译工具
sudo pacman -S --needed base-devel cmake ninja git

# 安装系统库
sudo pacman -S --needed \
    glib2 \
    libsecret \
    openssl \
    mesa \
    libxcb \
    xcb-util-* \
    libxkbcommon \
    libxkbcommon-x11
```

## Qt 安装

### 使用 Qt 在线安装器

```bash
# 下载安装器
wget https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x qt-unified-linux-x64-online.run
./qt-unified-linux-x64-online.run
```

安装组件：
- Qt 6.10.0 或更高版本
- Desktop gcc 64-bit

### 设置环境变量

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export Qt6_DIR="/opt/Qt/6.10.0/gcc_64"
export PATH="$Qt6_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$Qt6_DIR/lib:$LD_LIBRARY_PATH"

# 使配置生效
source ~/.bashrc
```

## 编译

### 基本编译

```bash
cd ~/OpineWork/JinGo

# Debug 版本
./scripts/build/build-linux.sh

# Release 版本
./scripts/build/build-linux.sh --release

# 清理后编译
./scripts/build/build-linux.sh --clean --release
```

### 编译选项

| 选项 | 说明 |
|------|------|
| `-c, --clean` | 清理构建目录后重新构建 |
| `-d, --debug` | Debug 模式（默认） |
| `-r, --release` | Release 模式 |
| `-p, --package` | 打包 DEB/RPM/TGZ |
| `--deploy` | 部署 Qt 依赖库 |
| `-t, --translate` | 更新翻译 |
| `-b, --brand NAME` | 白标定制 |
| `-v, --verbose` | 详细输出 |

### 带依赖部署的编译

```bash
# 编译并部署 Qt 依赖
./scripts/build/build-linux.sh --release --deploy

# 创建安装包
./scripts/build/build-linux.sh --release --package
```

### 输出目录

```
build-linux/
├── bin/
│   ├── JinGo              # 主程序
│   ├── jingo              # 启动脚本（--deploy 模式）
│   ├── lib/               # 依赖库
│   ├── plugins/           # Qt 插件
│   ├── geoip.dat          # GeoIP 数据
│   ├── geosite.dat        # GeoSite 数据
│   └── bundle_config.json # 配置文件
└── build.log              # 编译日志

release/
├── jingo-*-linux.tar.gz   # 压缩包
├── jingo-*-linux.deb      # DEB 包
└── jingo-*-linux.rpm      # RPM 包
```

## 运行

### 设置 TUN 权限

JinGo VPN 需要 `CAP_NET_ADMIN` 权限来创建 TUN 设备：

```bash
# 设置权限
sudo setcap cap_net_admin+eip ./build-linux/bin/JinGo

# 验证权限
getcap ./build-linux/bin/JinGo
# 应显示: ./build-linux/bin/JinGo cap_net_admin=eip
```

**权限说明：**
- `cap_net_admin` = 网络管理权限（创建 TUN 设备、配置路由）
- `+e` = Effective（进程启动时立即生效）
- `+i` = Inheritable（子进程可继承）
- `+p` = Permitted（允许进程拥有此权限）

**注意：** 每次重新编译后都需要重新设置权限。

### 运行应用

```bash
# 直接运行
./build-linux/bin/JinGo

# 使用启动脚本（如果使用了 --deploy）
./build-linux/bin/jingo

# 指定库路径运行
LD_LIBRARY_PATH="$PWD/build-linux/bin/lib:$LD_LIBRARY_PATH" ./build-linux/bin/JinGo
```

### 调试运行

```bash
# 启用详细日志
QT_LOGGING_RULES="*.debug=true" ./build-linux/bin/JinGo

# 指定显示后端
QT_QPA_PLATFORM=xcb ./build-linux/bin/JinGo     # X11
QT_QPA_PLATFORM=wayland ./build-linux/bin/JinGo  # Wayland
```

## 安装

### 从 DEB 包安装

```bash
# 编译安装包
./scripts/build/build-linux.sh --release --package

# 安装
sudo dpkg -i build-linux/*.deb

# 修复依赖问题
sudo apt install -f
```

### 从 RPM 包安装

```bash
# 编译安装包
./scripts/build/build-linux.sh --release --package

# 安装
sudo dnf install build-linux/*.rpm
```

### 手动安装

```bash
# 编译
./scripts/build/build-linux.sh --release --deploy

# 安装到 /opt
sudo mkdir -p /opt/jingo
sudo cp -r build-linux/bin/* /opt/jingo/

# 设置权限
sudo setcap cap_net_admin+eip /opt/jingo/JinGo

# 创建符号链接
sudo ln -s /opt/jingo/JinGo /usr/local/bin/jingo
```

### 桌面集成

```bash
# 复制桌面文件
mkdir -p ~/.local/share/applications
cp platform/linux/jingo.desktop ~/.local/share/applications/

# 复制图标
sudo cp resources/icons/app.png /usr/share/icons/hicolor/256x256/apps/jingo.png

# 更新数据库
update-desktop-database ~/.local/share/applications/
```

## 故障排除

### CMake 找不到 Qt

**错误：**
```
Could not find Qt6 (missing: Qt6_DIR)
```

**解决：**
```bash
export Qt6_DIR="/opt/Qt/6.10.0/gcc_64"
./scripts/build/build-linux.sh --clean --release
```

### 缺少系统库

**错误：**
```
fatal error: glib.h: No such file or directory
```

**解决：**
```bash
# Ubuntu/Debian
sudo apt install libglib2.0-dev libsecret-1-dev

# Fedora
sudo dnf install glib2-devel libsecret-devel
```

### 运行时找不到 Qt 库

**错误：**
```
error while loading shared libraries: libQt6Core.so.6
```

**解决：**
```bash
# 方法 1: 使用部署模式
./scripts/build/build-linux.sh --release --deploy

# 方法 2: 设置库路径
export LD_LIBRARY_PATH="/opt/Qt/6.10.0/gcc_64/lib:$LD_LIBRARY_PATH"
```

### TUN 设备创建失败

**错误：**
```
Failed to create TUN device: Operation not permitted
```

**解决：**
```bash
sudo setcap cap_net_admin+eip ./build-linux/bin/JinGo
```

### OpenSSL 库找不到

**错误：**
```
libssl.so.3: cannot open shared object file
```

**解决：**

OpenSSL 已部署到 `build-linux/bin/lib/`，运行时添加库路径：
```bash
export LD_LIBRARY_PATH="$PWD/build-linux/bin/lib:$LD_LIBRARY_PATH"
./build-linux/bin/JinGo
```

### Wayland 显示问题

**解决：**
```bash
# 强制使用 X11
QT_QPA_PLATFORM=xcb ./build-linux/bin/JinGo

# 或使用 Wayland
QT_QPA_PLATFORM=wayland ./build-linux/bin/JinGo
```

### 高 DPI 显示问题

```bash
# 设置缩放因子
export QT_SCALE_FACTOR=1.5
./build-linux/bin/JinGo

# 或自动检测
export QT_AUTO_SCREEN_SCALE_FACTOR=1
./build-linux/bin/JinGo
```

## 日志和诊断

### 日志位置

```
~/.local/share/JinGo/logs/
```

### 收集诊断信息

```bash
# 系统信息
uname -a
cat /etc/os-release

# Qt 版本
qmake --version

# 依赖检查
ldd ./build-linux/bin/JinGo | grep -E "Qt|ssl|crypto"

# 权限检查
getcap ./build-linux/bin/JinGo
```

## 性能优化

### Release 版本优化

Release 版本已启用：
- CMake Release 模式 (`-O3`)
- 禁用调试输出
- 编译器优化

### 减小应用体积

```bash
# 移除调试符号
strip build-linux/bin/JinGo
```

### 启用 LTO

编辑 `CMakeLists.txt`：
```cmake
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
```

## 高级配置

### 自定义 Qt 路径

```bash
export Qt6_DIR="/opt/Qt/6.10.1/gcc_64"
./scripts/build/build-linux.sh --clean --release
```

### 交叉编译 (ARM64)

```bash
# 安装工具链
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 使用工具链文件编译
cmake -S . -B build-arm64 -DCMAKE_TOOLCHAIN_FILE=toolchain-arm64.cmake
cmake --build build-arm64 --config Release
```

## 多语言支持

支持的语言：
- English (en_US)
- 简体中文 (zh_CN)
- 繁體中文 (zh_TW)
- Tiếng Việt (vi_VN)
- ភាសាខ្មែរ (km_KH)
- မြန်မာဘာသာ (my_MM)
- Русский (ru_RU)
- فارسی (fa_IR)

更新翻译：
```bash
./scripts/build/build-linux.sh --translate --release
```

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [开发指南](03_DEVELOPMENT.md)
- [故障排除](05_TROUBLESHOOTING.md)
