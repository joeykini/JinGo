# JinGo VPN 翻译文件

本目录包含 JinGo VPN 的多语言翻译文件。

## 支持的语言

| 语言代码 | 语言名称 | 翻译覆盖率 | 状态 |
|---------|---------|-----------|------|
| `en_US` | English | 100% (678/678) | ✅ 完成 |
| `zh_CN` | 简体中文 | 100% (678/678) | ✅ 完成 |
| `zh_TW` | 繁體中文 | 100% (678/678) | ✅ 完成 |
| `fa_IR` | فارسی (波斯语) | 100% (678/678) | ✅ 完成 |
| `ru_RU` | Русский (俄语) | 100% (678/678) | ✅ 完成 |

## 系统语言自动匹配

应用会根据系统语言自动选择界面语言：

- **简体中文系统** (zh_CN) → 自动使用简体中文
- **繁体中文系统** (zh_TW, zh_HK) → 自动使用繁体中文
- **波斯语系统** (fa, fa_IR) → 自动使用波斯语（RTL 布局）
- **俄语系统** (ru, ru_RU) → 自动使用俄语
- **其他系统** → 默认使用英文

支持的 RTL（从右到左）语言：
- 波斯语 (fa, fa_IR)
- 阿拉伯语 (ar, ar_SA, ar_EG)
- 希伯来语 (he, he_IL)
- 乌尔都语 (ur, ur_PK)
- 意第绪语 (yi)

## 翻译工作流程

### 快速开始（推荐）

使用统一的翻译脚本一键完成所有翻译工作：

```bash
# 从项目根目录运行
python3 scripts/translate_ts.py
```

该脚本会自动：
1. 扫描所有 .ts 文件
2. 使用内置词典翻译英文到各语言
3. 保持已翻译内容不变
4. 输出翻译统计信息

### 手动工作流程

#### 1. 提取可翻译字符串

```bash
# 从 QML 和 C++ 源文件提取字符串
/Volumes/mindata/Applications/Qt/6.10.0/macos/bin/lupdate \
    resources/qml \
    src \
    -ts resources/translations/jingo_zh_CN.ts \
       resources/translations/jingo_zh_TW.ts \
       resources/translations/jingo_en_US.ts \
       resources/translations/jingo_fa_IR.ts \
       resources/translations/jingo_ru_RU.ts \
    -no-obsolete
```

#### 2. 应用自动翻译

```bash
python3 scripts/translate_ts.py
```

#### 3. 手动翻译（使用 Qt Linguist）

```bash
# 打开翻译编辑器
/Volumes/mindata/Applications/Qt/6.10.0/macos/bin/linguist resources/translations/jingo_zh_CN.ts
```

#### 4. 编译翻译文件

```bash
# 编译所有 .ts 文件为 .qm 二进制格式
/Volumes/mindata/Applications/Qt/6.10.0/macos/bin/lrelease resources/translations/*.ts
```

## 构建集成

构建脚本 `scripts/build/build-macos.sh` 已集成翻译处理：

- **增量编译**：只有当 .ts 文件比 .qm 文件更新时才重新生成
- **自动部署**：.qm 文件自动复制到 App Bundle
- **强制重新生成**：使用 `--translate` 参数强制重新生成翻译

```bash
# 正常构建（增量翻译）
./scripts/build/build-macos.sh

# 强制重新生成翻译
./scripts/build/build-macos.sh --translate
```

## 添加新语言

1. 创建新的 .ts 文件：
```bash
cp resources/translations/jingo_en_US.ts resources/translations/jingo_XX_YY.ts
```

2. 在 `scripts/translate_ts.py` 中添加语言词典

3. 在 `src/utils/LanguageManager.cpp` 中添加语言支持

4. 运行翻译脚本并重新编译

## 文件说明

| 文件 | 说明 |
|-----|------|
| `jingo_*.ts` | Qt 翻译源文件（XML 格式，可编辑） |
| `jingo_*.qm` | Qt 翻译二进制文件（编译后，运行时使用） |

## 注意事项

- 所有需要翻译的字符串必须使用 `qsTr()` (QML) 或 `tr()` (C++) 包装
- 动态字符串使用 `.arg()` 进行参数替换
- RTL 语言会自动调整界面布局方向
