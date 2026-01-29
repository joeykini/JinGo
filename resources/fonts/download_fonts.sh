#!/bin/bash
# 下载思源黑体字体文件

set -e

FONT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$FONT_DIR"

echo "======================================"
echo "  思源黑体字体下载脚本"
echo "======================================"
echo ""

# 检查是否已存在字体文件
check_font_exists() {
    local file=$1
    if [ -f "$file" ] && [ -s "$file" ]; then
        local size=$(du -h "$file" | cut -f1)
        echo "✓ $file 已存在 (大小: $size)"
        return 0
    fi
    return 1
}

# 下载 Noto Sans CJK SC
download_noto_sans() {
    echo "正在下载 Noto Sans CJK SC Regular..."
    echo "来源: GitHub notofonts/noto-cjk"
    echo ""

    # Noto Sans CJK SC Regular 的直接链接
    local url="https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"

    if command -v curl &> /dev/null; then
        curl -L -o NotoSansCJKSC-Regular.otf.tmp "$url"
    elif command -v wget &> /dev/null; then
        wget -O NotoSansCJKSC-Regular.otf.tmp "$url"
    else
        echo "错误: 需要 curl 或 wget 命令"
        return 1
    fi

    # 验证下载
    if [ -f "NotoSansCJKSC-Regular.otf.tmp" ] && [ -s "NotoSansCJKSC-Regular.otf.tmp" ]; then
        mv NotoSansCJKSC-Regular.otf.tmp NotoSansCJKSC-Regular.otf
        echo "✓ Noto Sans CJK SC 下载成功"
        du -h NotoSansCJKSC-Regular.otf
        return 0
    else
        echo "✗ 下载失败"
        rm -f NotoSansCJKSC-Regular.otf.tmp
        return 1
    fi
}

# 下载 Source Han Sans
download_source_han_sans() {
    echo "正在下载 Source Han Sans SC Regular..."
    echo "来源: GitHub adobe-fonts/source-han-sans"
    echo ""

    # Source Han Sans 的直接链接
    local url="https://github.com/adobe-fonts/source-han-sans/raw/release/OTF/SimplifiedChinese/SourceHanSansSC-Regular.otf"

    if command -v curl &> /dev/null; then
        curl -L -o SourceHanSansSC-Regular.otf.tmp "$url"
    elif command -v wget &> /dev/null; then
        wget -O SourceHanSansSC-Regular.otf.tmp "$url"
    else
        echo "错误: 需要 curl 或 wget 命令"
        return 1
    fi

    # 验证下载
    if [ -f "SourceHanSansSC-Regular.otf.tmp" ] && [ -s "SourceHanSansSC-Regular.otf.tmp" ]; then
        mv SourceHanSansSC-Regular.otf.tmp SourceHanSansSC-Regular.otf
        echo "✓ Source Han Sans SC 下载成功"
        du -h SourceHanSansSC-Regular.otf
        return 0
    else
        echo "✗ 下载失败"
        rm -f SourceHanSansSC-Regular.otf.tmp
        return 1
    fi
}

# 主流程
main() {
    echo "检查现有字体文件..."
    echo ""

    local noto_exists=false
    local source_exists=false

    if check_font_exists "NotoSansCJKSC-Regular.otf"; then
        noto_exists=true
    fi

    if check_font_exists "SourceHanSansSC-Regular.otf"; then
        source_exists=true
    fi

    echo ""

    # 如果两个都存在，询问是否重新下载
    if $noto_exists && $source_exists; then
        echo "所有字体文件已存在。"
        read -p "是否重新下载？(y/N): " answer
        if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
            echo "跳过下载。"
            exit 0
        fi
    fi

    # 选择下载哪个字体
    echo "请选择要下载的字体："
    echo "  1) Noto Sans CJK SC (Google 版本, 推荐)"
    echo "  2) Source Han Sans SC (Adobe 版本)"
    echo "  3) 两个都下载"
    echo ""
    read -p "请输入选项 (1-3) [默认: 1]: " choice
    choice=${choice:-1}

    echo ""

    case $choice in
        1)
            if ! $noto_exists; then
                download_noto_sans || echo "下载失败，请手动下载"
            fi
            ;;
        2)
            if ! $source_exists; then
                download_source_han_sans || echo "下载失败，请手动下载"
            fi
            ;;
        3)
            if ! $noto_exists; then
                download_noto_sans || echo "Noto Sans 下载失败"
            fi
            echo ""
            if ! $source_exists; then
                download_source_han_sans || echo "Source Han Sans 下载失败"
            fi
            ;;
        *)
            echo "无效的选项"
            exit 1
            ;;
    esac

    echo ""
    echo "======================================"
    echo "  下载完成"
    echo "======================================"
    echo ""
    echo "现在可以重新编译项目了："
    echo "  cd build/Qt_6_10_0_Clang_arm64_v8a-Debug"
    echo "  cmake --build ."
    echo ""
}

main
