# Windows 应用程序图标配置

## 自动图标生成功能

JinGo 项目已配置自动从 PNG 文件生成 Windows ICO 图标文件。

### 工作原理

1. **源文件**: `resources/icons/app.png`
2. **目标文件**: `resources/icons/app.ico`
3. **生成脚本**: `platform/windows/generate_icon.py`

在 CMake 配置阶段，如果 `app.ico` 不存在，系统会自动运行脚本从 `app.png` 生成多尺寸的 ICO 文件。

### 图标尺寸

生成的 ICO 文件包含以下尺寸，以确保在不同场景下的最佳显示效果：
- 256x256 (Windows 7+ 大图标)
- 128x128
- 64x64
- 48x48 (Windows 经典视图)
- 32x32 (Windows 列表视图)
- 16x16 (Windows 小图标)

### 先决条件

要使用自动生成功能，需要安装以下任一工具：

#### 方法 1: Pillow (推荐)

```bash
pip install Pillow
# 或
python -m pip install Pillow
```

#### 方法 2: ImageMagick

从 https://imagemagick.org/ 下载并安装 ImageMagick，确保 `convert` 命令在系统 PATH 中。

### 手动生成图标

如果需要手动重新生成图标（例如更新了 app.png）：

```bash
# 删除旧的 ICO 文件
rm resources/icons/app.ico

# 运行生成脚本
python3 platform/windows/generate_icon.py resources/icons/app.png resources/icons/app.ico
```

或者，在下次 CMake 配置时会自动重新生成：

```bash
# 删除旧的 ICO 文件
rm resources/icons/app.ico

# 重新配置 CMake
cmake -B build -DCMAKE_BUILD_TYPE=Release
```

### 自定义图标

要使用自定义图标：

1. **替换 PNG 文件**（推荐）
   ```bash
   # 替换源文件
   cp your_icon.png resources/icons/app.png

   # 删除旧的 ICO
   rm resources/icons/app.ico

   # 重新配置以生成新图标
   cmake -B build
   ```

2. **直接提供 ICO 文件**
   ```bash
   # 如果已有 ICO 文件，直接复制
   cp your_icon.ico resources/icons/app.ico
   ```

### 资源文件配置

#### 1. Windows 资源文件 (.rc)

图标通过 Windows 资源文件 (`platform/windows/app.rc`) 嵌入到可执行文件中：

```rc
// Application icon
IDI_ICON1 ICON "../../resources/icons/app.ico"

1 VERSIONINFO
FILEVERSION 1,0,0,0
...
```

这使得 Windows 资源管理器能够显示 .exe 文件的图标。

#### 2. Qt 资源系统 (qrc)

`app.ico` 也被添加到 Qt 资源系统中 (`resources/resources.qrc`)：

```xml
<file>icons/app.ico</file>
```

这样可以在应用程序代码中通过 Qt 资源路径访问图标：

**C++ 代码示例：**
```cpp
// 设置窗口图标
QIcon icon(":/icons/app.ico");
setWindowIcon(icon);

// 或设置应用程序图标
QApplication::setWindowIcon(QIcon(":/icons/app.ico"));

// 在系统托盘中使用
QSystemTrayIcon *trayIcon = new QSystemTrayIcon(this);
trayIcon->setIcon(QIcon(":/icons/app.ico"));
```

**QML 代码示例：**
```qml
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    // 设置窗口图标
    icon.source: "qrc:/icons/app.ico"

    // 在 Image 组件中使用
    Image {
        source: "qrc:/icons/app.ico"
        width: 48
        height: 48
    }
}
```

**资源路径说明：**
- C++ 中使用：`":/icons/app.ico"`
- QML 中使用：`"qrc:/icons/app.ico"`

两种配置的作用：
- **Windows .rc 文件**：为可执行文件本身提供图标（资源管理器、任务栏显示）
- **Qt qrc 文件**：在应用程序运行时可以访问图标（窗口图标、系统托盘图标等）

### 故障排查

#### 问题: CMake 配置时警告 "Python3 not found"

**解决方案**: 安装 Python 3.x
- Windows: 从 https://www.python.org/ 下载安装
- 确保勾选 "Add Python to PATH"

#### 问题: 图标生成失败，提示缺少 Pillow

**解决方案**:
```bash
pip install Pillow
```

#### 问题: 可执行文件仍然没有图标

检查以下几点：
1. 确认 `resources/icons/app.ico` 文件存在
2. 确认 `platform/windows/app.rc` 文件存在且内容正确
3. 重新构建项目：
   ```bash
   cmake --build build --config Release --clean-first
   ```

#### 问题: 图标显示模糊或不清晰

ICO 文件需要包含多个尺寸。使用提供的脚本会自动生成所有必要的尺寸。如果手动创建 ICO，确保包含至少 16x16、32x32、48x48 和 256x256 四种尺寸。

### PNG 要求

为获得最佳效果，源 PNG 文件应满足：
- **最小尺寸**: 256x256 像素（推荐 512x512 或更大）
- **格式**: 支持透明通道的 PNG (RGBA)
- **内容**: 简洁清晰的图标设计，在小尺寸下仍可识别

### 相关文件

**图标文件：**
- `resources/icons/app.png` - 源图标（PNG 格式）
- `resources/icons/app.ico` - Windows 图标（自动生成）

**资源配置：**
- `platform/windows/app.rc` - Windows 资源文件
- `resources/resources.qrc` - Qt 资源文件（包含 app.ico）

**构建工具：**
- `platform/windows/generate_icon.py` - 图标生成脚本
- `CMakeLists.txt` (第 104-133 行) - 自动生成配置

**示例代码：**
- `platform/windows/icon_usage_example.cpp` - C++ 使用示例
- `platform/windows/icon_usage_example.qml` - QML 使用示例

## 在安装包中的图标

除了可执行文件图标外，MSI 安装包也使用同一个 ICO 文件：

```cmake
# CMakeLists.txt 中的配置
set(CPACK_WIX_PRODUCT_ICON "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.ico")
```

这确保了应用程序在整个生命周期中都有一致的图标显示。
