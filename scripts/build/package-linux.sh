#!/bin/bash
# JinGoVPN Linux 打包脚本 - 生成 DEB/RPM 包

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   JinGoVPN Linux 打包脚本${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 检查构建目录
BUILD_DIR="build-linux"
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}错误：找不到构建目录 $BUILD_DIR${NC}"
    echo "请先运行: ./scripts/build/build-linux.sh"
    exit 1
fi

# 切换到构建目录
cd "$BUILD_DIR"

# 检查可执行文件
if [ ! -f "bin/JinGo" ]; then
    echo -e "${RED}错误：找不到可执行文件 bin/JinGo${NC}"
    echo "请先编译项目"
    exit 1
fi

# 重新配置 CMake 启用打包
echo -e "${YELLOW}[1/3] 配置 CMake（启用打包）...${NC}"
cmake .. -DENABLE_PACKAGING=ON

# 生成 DEB 包
echo ""
echo -e "${YELLOW}[2/3] 生成 DEB 包...${NC}"
cpack -G DEB

# 生成 RPM 包（可选）
echo ""
echo -e "${YELLOW}[3/3] 生成 RPM 包（可选）...${NC}"
cpack -G RPM || echo -e "${YELLOW}⚠ RPM 包生成失败（可能缺少 rpmbuild 工具）${NC}"

# 显示生成的包
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}        打包完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}生成的软件包：${NC}"
ls -lh *.deb *.rpm 2>/dev/null || echo "（未找到包文件）"

# 安装说明
DEB_FILE=$(ls *.deb 2>/dev/null | head -1)
if [ -n "$DEB_FILE" ]; then
    echo ""
    echo -e "${CYAN}DEB 包安装方法：${NC}"
    echo ""
    echo -e "  ${GREEN}方法 1:${NC} 双击 DEB 文件，使用软件中心安装"
    echo -e "  ${GREEN}方法 2:${NC} 命令行安装"
    echo "    sudo dpkg -i $DEB_FILE"
    echo "    sudo apt-get install -f  # 解决依赖问题"
    echo ""
    echo -e "  ${GREEN}方法 3:${NC} 使用 apt 安装（自动解决依赖）"
    echo "    sudo apt install ./$DEB_FILE"
    echo ""
    echo -e "${CYAN}安装后：${NC}"
    echo "  - 在应用菜单搜索 'JinGoVPN'"
    echo "  - 图标会自动显示"
    echo "  - VPN 权限已自动设置"
    echo ""
    echo -e "${CYAN}卸载：${NC}"
    echo "  sudo apt remove jingo-vpn"
    echo ""
fi

echo -e "${GREEN}========================================${NC}"
