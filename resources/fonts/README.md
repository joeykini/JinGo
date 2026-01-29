# 字体文件目录

## 需要的字体文件

请将以下字体文件放置到此目录：

1. **SourceHanSansSC-Regular.otf** （推荐）
   - 下载地址：https://github.com/adobe-fonts/source-han-sans/releases
   - 或使用：**NotoSansCJKSC-Regular.otf**

2. **NotoSansCJKSC-Regular.otf** （备选）
   - 下载地址：https://github.com/notofonts/noto-cjk/releases
   - 或使用 Google Fonts：https://fonts.google.com/noto/specimen/Noto+Sans+SC

## 快速下载（推荐）

### 方案一：Google Fonts（最简单）
1. 访问：https://fonts.google.com/noto/specimen/Noto+Sans+SC
2. 点击 "Download family"
3. 解压后找到 `NotoSansSC-Regular.ttf` 或 `static/NotoSansSC/NotoSansSC-Regular.ttf`
4. 重命名为 `NotoSansCJKSC-Regular.otf` 并放到此目录

### 方案二：直接下载（命令行）

```bash
# 下载 Noto Sans CJK SC Regular
cd resources/fonts/

# 从 GitHub Releases 下载（约 15MB）
curl -L -o NotoSansCJKSC-Regular.otf \
  "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
```

### 方案三：下载 Source Han Sans

```bash
cd resources/fonts/

# 下载 Source Han Sans SC Regular（约 16MB）
# 需要从 GitHub Releases 页面手动下载：
# https://github.com/adobe-fonts/source-han-sans/releases
```

## 文件大小参考

- `SourceHanSansSC-Regular.otf`：约 16.5 MB
- `NotoSansCJKSC-Regular.otf`：约 15.8 MB
- `NotoSansSC-Regular.ttf` (Google Fonts)：约 5-8 MB（推荐，文件较小）

## 注意事项

1. **至少需要一个字体文件**才能在 Android 上显示中文
2. 字体文件较大，会增加 APK 体积
3. 如果两个都提供，优先使用 SourceHanSansSC
4. iOS/macOS 使用系统自带的 PingFang SC，不需要打包字体

## 验证

放置字体文件后，重新编译项目：

```bash
cd build/Qt_6_10_0_Clang_arm64_v8a-Debug
cmake --build .
```

运行时会在日志中看到：
```
FontLoader: Source Han Sans SC loaded successfully - Source Han Sans SC
```

## 许可证

这两个字体都是开源免费的：
- 许可证：SIL Open Font License 1.1
- 可以商业使用、修改和分发

详细说明请参考：`docs/FONTS_SETUP.md`
