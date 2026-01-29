# 思源黑体字体下载链接

## 快速下载（推荐）

### 方案一：Google Fonts（文件最小，推荐）
**Noto Sans SC** - Google Fonts 版本（约 5-8 MB）

🔗 **下载地址**：https://fonts.google.com/noto/specimen/Noto+Sans+SC

操作步骤：
1. 点击页面右上角 **"Download family"** 按钮
2. 解压下载的 zip 文件
3. 找到 `static/NotoSansSC/NotoSansSC-Regular.ttf` 文件
4. 复制到 `JinGo/resources/fonts/` 目录
5. 重命名为 `NotoSansCJKSC-Regular.otf`

---

### 方案二：GitHub 直链下载

#### Noto Sans CJK SC Regular（约 15.8 MB）

🔗 **直接下载**：
```
https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf
```

**命令行下载**：
```bash
cd resources/fonts/
curl -L -o NotoSansCJKSC-Regular.otf \
  "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
```

---

#### Source Han Sans SC Regular（约 16.5 MB）

🔗 **直接下载**：
```
https://github.com/adobe-fonts/source-han-sans/raw/release/OTF/SimplifiedChinese/SourceHanSansSC-Regular.otf
```

**命令行下载**：
```bash
cd resources/fonts/
curl -L -o SourceHanSansSC-Regular.otf \
  "https://github.com/adobe-fonts/source-han-sans/raw/release/OTF/SimplifiedChinese/SourceHanSansSC-Regular.otf"
```

---

### 方案三：完整发行版下载

如果需要多个字重（Light、Bold 等），可以下载完整版：

#### Noto Sans CJK 完整版
🔗 **GitHub Releases**：https://github.com/notofonts/noto-cjk/releases

找到最新版本，下载 `Sans/OTF/SimplifiedChinese.zip`

---

#### Source Han Sans 完整版
🔗 **GitHub Releases**：https://github.com/adobe-fonts/source-han-sans/releases

找到最新版本，下载 `SourceHanSansSC.zip`

---

## 使用一键下载脚本

在项目根目录执行：

```bash
cd resources/fonts/
chmod +x download_fonts.sh
./download_fonts.sh
```

脚本会自动下载字体文件到正确位置。

---

## 百度网盘 / 阿里云盘（国内用户）

如果 GitHub 下载速度慢，可以使用以下镜像：

### 百度网盘
思源黑体合集（包含多个字重）
- 链接：（需要自行搜索"思源黑体 百度网盘"）

### 阿里云盘
Noto Sans CJK SC
- 链接：（需要自行搜索"Noto Sans CJK 阿里云盘"）

---

## 其他中文字体（开源免费）

如果不想用思源黑体，还可以选择：

### 1. 阿里巴巴普惠体
🔗 下载：https://www.alibabafonts.com/#/font
- 文件：AlibabaPuHuiTi-2-55-Regular.ttf
- 特点：现代感强，适合商业场景

### 2. 鸿蒙字体（HarmonyOS Sans）
🔗 下载：https://developer.harmonyos.com/cn/design/resource
- 文件：HarmonyOS_Sans_SC_Regular.ttf
- 特点：华为开源，显示清晰

### 3. OPPO Sans
🔗 下载：https://www.oppo.com/cn/font/
- 文件：OPPOSans-R.ttf
- 特点：圆润舒适，适合阅读

---

## 字体许可证

所有推荐的字体都是**开源免费**的：

| 字体 | 许可证 | 商用 |
|-----|--------|------|
| 思源黑体 / Noto Sans CJK | SIL OFL 1.1 | ✅ 允许 |
| 阿里巴巴普惠体 | 个人商用免费 | ✅ 允许 |
| 鸿蒙字体 | 免费 | ✅ 允许 |
| OPPO Sans | 免费 | ✅ 允许 |

---

## 验证字体安装

下载字体文件后，放到 `resources/fonts/` 目录，然后重新编译：

```bash
cd build/Qt_6_10_0_Clang_arm64_v8a-Debug
cmake --build .
```

运行 Android 应用后，查看日志应该看到：

```
FontLoader: Source Han Sans SC loaded successfully - Source Han Sans SC
```

---

## 需要帮助？

查看详细文档：
- `resources/fonts/README.md` - 快速指南
- `docs/FONTS_SETUP.md` - 完整文档

或者运行下载脚本：
```bash
./download_fonts.sh
```
