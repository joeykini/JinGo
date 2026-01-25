#!/bin/bash
# ==============================================================================
# JinGo VPN - 依赖安装脚本
# ==============================================================================
# 支持平台: macOS, Linux (Ubuntu/Debian)
# 用法: ./scripts/setup/install-deps.sh
# ==============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/debian_version ]] || [[ -f /etc/ubuntu-release ]]; then
        OS="ubuntu"
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    print_info "检测到操作系统: $OS"
}

# macOS 依赖安装
install_macos_deps() {
    print_info "安装 macOS 依赖..."

    # 检查 Homebrew
    if ! command -v brew &> /dev/null; then
        print_info "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    print_success "Homebrew 已安装"

    # 安装依赖
    MACOS_DEPS=(
        cmake
        ninja
        go
        jq
        create-dmg
    )

    for dep in "${MACOS_DEPS[@]}"; do
        if ! brew list "$dep" &> /dev/null; then
            print_info "安装 $dep..."
            brew install "$dep"
        else
            print_success "$dep 已安装"
        fi
    done

    # 检查 Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        print_info "安装 Xcode Command Line Tools..."
        xcode-select --install
    fi
    print_success "Xcode Command Line Tools 已安装"

    # 检查 Qt
    if [ -z "$QT_DIR" ] && [ ! -d "/Volumes/mindata/Applications/Qt" ]; then
        print_warning "Qt 未检测到。请从 https://www.qt.io/download 安装 Qt 6.5+"
        print_warning "安装后设置环境变量: export QT_DIR=/path/to/Qt/6.x.x/macos"
    else
        print_success "Qt 已配置"
    fi
}

# Ubuntu/Debian 依赖安装
install_ubuntu_deps() {
    print_info "安装 Ubuntu/Debian 依赖..."

    # 更新包列表
    sudo apt-get update

    # 基础构建工具
    UBUNTU_DEPS=(
        build-essential
        cmake
        ninja-build
        git
        curl
        wget
        jq
        pkg-config
        # Qt 依赖
        qt6-base-dev
        qt6-declarative-dev
        qt6-tools-dev
        qt6-l10n-tools
        libqt6svg6-dev
        qml6-module-qtquick
        qml6-module-qtquick-controls
        qml6-module-qtquick-layouts
        qml6-module-qtquick-window
        qml6-module-qt-labs-platform
        qml6-module-qtqml-workerscript
        # 网络相关
        libssl-dev
        # Go
        golang-go
        # Android SDK/NDK (可选)
        # openjdk-17-jdk
    )

    for dep in "${UBUNTU_DEPS[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            print_info "安装 $dep..."
            sudo apt-get install -y "$dep" || print_warning "$dep 安装失败，可能不可用"
        else
            print_success "$dep 已安装"
        fi
    done

    # 检查 Qt 版本
    if command -v qmake6 &> /dev/null; then
        QT_VER=$(qmake6 --version 2>/dev/null | grep -oP 'Qt version \K[0-9.]+' || echo "unknown")
        print_success "Qt 版本: $QT_VER"
    else
        print_warning "Qt 6 未检测到。请安装 Qt 6.5+"
    fi
}

# 检查 Go 版本
check_go() {
    if command -v go &> /dev/null; then
        GO_VER=$(go version | grep -oP 'go\K[0-9.]+')
        print_success "Go 版本: $GO_VER"

        # 检查最低版本要求 (1.21+)
        MIN_GO_VER="1.21"
        if [ "$(printf '%s\n' "$MIN_GO_VER" "$GO_VER" | sort -V | head -n1)" != "$MIN_GO_VER" ]; then
            print_warning "Go 版本太低，需要 $MIN_GO_VER 或更高"
        fi
    else
        print_error "Go 未安装"
        return 1
    fi
}

# 检查 CMake 版本
check_cmake() {
    if command -v cmake &> /dev/null; then
        CMAKE_VER=$(cmake --version | head -1 | grep -oP '[0-9.]+')
        print_success "CMake 版本: $CMAKE_VER"

        # 检查最低版本要求 (3.21+)
        MIN_CMAKE_VER="3.21"
        if [ "$(printf '%s\n' "$MIN_CMAKE_VER" "$CMAKE_VER" | sort -V | head -n1)" != "$MIN_CMAKE_VER" ]; then
            print_warning "CMake 版本太低，需要 $MIN_CMAKE_VER 或更高"
        fi
    else
        print_error "CMake 未安装"
        return 1
    fi
}

# 检查依赖状态
check_deps() {
    print_info ""
    print_info "=========================================="
    print_info "         依赖状态检查"
    print_info "=========================================="

    check_cmake || true
    check_go || true

    if command -v ninja &> /dev/null; then
        print_success "Ninja 已安装"
    else
        print_warning "Ninja 未安装"
    fi

    if command -v git &> /dev/null; then
        print_success "Git 已安装"
    else
        print_warning "Git 未安装"
    fi

    if [ "$OS" == "macos" ]; then
        if command -v create-dmg &> /dev/null; then
            print_success "create-dmg 已安装"
        else
            print_warning "create-dmg 未安装 (用于创建 DMG)"
        fi
    fi

    print_info "=========================================="
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "   JinGo VPN 依赖安装脚本"
    echo "=========================================="
    echo ""

    detect_os

    case "$OS" in
        macos)
            install_macos_deps
            ;;
        ubuntu)
            install_ubuntu_deps
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    check_deps

    echo ""
    print_success "=========================================="
    print_success "         依赖安装完成!"
    print_success "=========================================="
    echo ""
    print_info "下一步: 运行构建脚本"
    print_info "  macOS: ./scripts/build/build-macos.sh"
    print_info "  Linux: ./scripts/build/build-linux.sh"
    print_info "  Android: ./scripts/build/build-android.sh"
    echo ""
}

main "$@"
