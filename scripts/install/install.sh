#!/bin/bash
# JinGoVPN Linux 安装脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查是否有 root 权限
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误：此脚本需要 root 权限运行${NC}"
   echo "请使用: sudo ./install.sh"
   exit 1
fi

echo "========================================"
echo "     JinGoVPN Linux 安装程序"
echo "========================================"
echo ""

# 检查构建目录
BUILD_DIR="build-linux"
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}错误：找不到构建目录 $BUILD_DIR${NC}"
    echo "请先运行: ./scripts/build/build-linux.sh"
    exit 1
fi

# 设置安装前缀
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
echo -e "${YELLOW}安装位置: $INSTALL_PREFIX${NC}"
echo ""

# 执行安装
cd "$BUILD_DIR"
echo -e "${GREEN}[1/4] 安装文件...${NC}"
cmake --install . --prefix "$INSTALL_PREFIX"

echo ""
echo -e "${GREEN}[2/4] 更新桌面数据库...${NC}"
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$INSTALL_PREFIX/share/applications" 2>/dev/null || true
    echo "✓ 桌面数据库已更新"
else
    echo "⚠ update-desktop-database 未找到，跳过"
fi

echo ""
echo -e "${GREEN}[3/4] 更新图标缓存...${NC}"
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache "$INSTALL_PREFIX/share/icons/hicolor" -f 2>/dev/null || true
    echo "✓ 图标缓存已更新"
else
    echo "⚠ gtk-update-icon-cache 未找到，跳过"
fi

echo ""
echo -e "${GREEN}[4/4] 设置 VPN 权限...${NC}"
JINGO_BIN="$INSTALL_PREFIX/bin/JinGo"
if [ -f "$JINGO_BIN" ]; then
    setcap cap_net_admin+eip "$JINGO_BIN" 2>/dev/null && \
        echo "✓ CAP_NET_ADMIN 权限已设置" || \
        echo "⚠ 权限设置失败，VPN 功能可能需要 sudo 运行"
fi

echo ""
echo -e "${GREEN}========================================"
echo "           安装完成！"
echo "========================================${NC}"
echo ""
echo "启动应用："
echo "  1. 从应用菜单搜索 'JinGoVPN'"
echo "  2. 或运行命令: $JINGO_BIN"
echo ""
echo "卸载："
echo "  sudo xargs rm -v < install_manifest.txt"
echo ""
