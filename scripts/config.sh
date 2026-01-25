#!/bin/bash
# ============================================================================
# JinGo VPN - 公共配置文件
# ============================================================================
# 此文件包含所有构建和部署脚本共享的配置
#
# 修改说明：
#   - 修改此文件中的配置会影响所有平台的构建
#   - 平台特定的配置在各平台脚本开头的 "平台配置" 部分
#   - 环境路径配置在 env.sh 文件中
#
# 使用方法：
#   source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# ============================================================================

# 加载环境配置
SCRIPTS_DIR_CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPTS_DIR_CONFIG/env.sh" ]]; then
    source "$SCRIPTS_DIR_CONFIG/env.sh"
fi

# ============================================================================
# 项目基本信息
# ============================================================================
APP_NAME="JinGo"
APP_DISPLAY_NAME="JinGo VPN"
APP_VERSION="1.0.0"                    # 会被 CMakeLists.txt 覆盖

# ============================================================================
# Apple 开发者配置 (macOS / iOS 共用)
# ============================================================================
APPLE_TEAM_ID="${APPLE_DEVELOPMENT_TEAM:-P6H5GHKRFU}"
APPLE_BUNDLE_ID="cfd.jingo.acc"

# 签名身份 (可通过环境变量覆盖)
APPLE_DEV_IDENTITY="${APPLE_CODE_SIGN_IDENTITY:-Apple Development}"
APPLE_DIST_IDENTITY="Developer ID Application"

# iOS Provisioning Profile 名称
IOS_PROFILE_MAIN="JinGo Accelerator iOS"
IOS_PROFILE_PACKET_TUNNEL="JinGo PacketTunnel iOS"

# macOS Provisioning Profile 名称 (如果需要)
MACOS_PROFILE_MAIN=""
MACOS_PROFILE_PACKET_TUNNEL=""

# ============================================================================
# Qt 配置 (自动检测)
# ============================================================================
# 优先使用环境变量，其次使用 env.sh 检测的路径，最后使用默认值
if [[ -n "$JINGO_QT_VERSION" ]]; then
    QT_VERSION="$JINGO_QT_VERSION"
else
    QT_VERSION="6.10.0"
fi

if [[ -n "$JINGO_QT_BASE" ]]; then
    QT_BASE_PATH="${QT_BASE_PATH:-$JINGO_QT_BASE/$QT_VERSION}"
else
    QT_BASE_PATH="${QT_BASE_PATH:-/Volumes/mindata/Applications/Qt/${QT_VERSION}}"
fi

# 各平台 Qt 路径 (支持自动检测)
if [[ -n "$JINGO_QT_BASE" ]]; then
    QT_MACOS_PATH="${QT_MACOS_PATH:-$JINGO_QT_BASE/$QT_VERSION/macos}"
    QT_IOS_PATH="${QT_IOS_PATH:-$JINGO_QT_BASE/$QT_VERSION/ios}"
    QT_ANDROID_ARM64_PATH="${QT_ANDROID_ARM64_PATH:-$JINGO_QT_BASE/$QT_VERSION/android_arm64_v8a}"
    QT_ANDROID_ARMV7_PATH="${QT_ANDROID_ARMV7_PATH:-$JINGO_QT_BASE/$QT_VERSION/android_armv7}"
    QT_ANDROID_X86_PATH="${QT_ANDROID_X86_PATH:-$JINGO_QT_BASE/$QT_VERSION/android_x86}"
    QT_ANDROID_X86_64_PATH="${QT_ANDROID_X86_64_PATH:-$JINGO_QT_BASE/$QT_VERSION/android_x86_64}"
    QT_LINUX_PATH="${Qt6_DIR:-$JINGO_QT_BASE/$QT_VERSION/gcc_64}"
else
    QT_MACOS_PATH="${QT_BASE_PATH}/macos"
    QT_IOS_PATH="${QT_BASE_PATH}/ios"
    QT_ANDROID_ARM64_PATH="${QT_BASE_PATH}/android_arm64_v8a"
    QT_ANDROID_ARMV7_PATH="${QT_BASE_PATH}/android_armv7"
    QT_ANDROID_X86_PATH="${QT_BASE_PATH}/android_x86"
    QT_ANDROID_X86_64_PATH="${QT_BASE_PATH}/android_x86_64"
    # Linux Qt 路径 (自动检测)
    QT_LINUX_PATH="${Qt6_DIR:-}"
fi

# ============================================================================
# Android 配置
# ============================================================================
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/Volumes/mindata/Library/Android/aarch64/sdk}"
ANDROID_NDK_VERSION="27.2.12479018"
ANDROID_NDK="${ANDROID_NDK:-$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION}"
ANDROID_MIN_SDK=28
ANDROID_TARGET_SDK=34
ANDROID_DEFAULT_ABI="arm64-v8a"

# Android OpenSSL
ANDROID_OPENSSL="${ANDROID_OPENSSL:-}"

# Android 签名配置
ANDROID_KEYSTORE="${ANDROID_KEYSTORE:-}"
ANDROID_KEYSTORE_PASSWORD="${ANDROID_KEYSTORE_PASSWORD:-}"
ANDROID_KEY_ALIAS="${ANDROID_KEY_ALIAS:-}"
ANDROID_KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-}"

# ============================================================================
# iOS 配置
# ============================================================================
IOS_MIN_VERSION="14.0"
IOS_DEFAULT_DEVICE_UDID="00008030-001238903A90802E"  # 默认测试设备

# ============================================================================
# macOS 配置
# ============================================================================
MACOS_MIN_VERSION="12.0"

# ============================================================================
# Linux 配置
# ============================================================================
LINUX_USE_NINJA=true

# ============================================================================
# 路径配置
# ============================================================================
# 自动检测脚本位置
if [ -z "$SCRIPTS_DIR" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
fi

# 构建输出目录
BUILD_BASE_DIR="$PROJECT_ROOT/build"
BUILD_MACOS_DIR="$BUILD_BASE_DIR/macos"
BUILD_IOS_DIR="$BUILD_BASE_DIR/ios"
BUILD_ANDROID_DIR="$BUILD_BASE_DIR/android"
BUILD_LINUX_DIR="$BUILD_BASE_DIR/linux"
BUILD_WINDOWS_DIR="$BUILD_BASE_DIR/windows"

# 平台特定文件目录
PLATFORM_DIR="$PROJECT_ROOT/platform"
PLATFORM_MACOS_DIR="$PLATFORM_DIR/macos"
PLATFORM_IOS_DIR="$PLATFORM_DIR/ios"
PLATFORM_ANDROID_DIR="$PLATFORM_DIR/android"
PLATFORM_LINUX_DIR="$PLATFORM_DIR/linux"

# 证书目录
CERT_DIR_IOS="$PLATFORM_IOS_DIR/cert"
CERT_DIR_MACOS="$PLATFORM_MACOS_DIR/cert"

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

# ============================================================================
# 公共函数
# ============================================================================

# 打印带颜色的消息
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BOLD}============================================${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}============================================${NC}"
}

# 检查命令是否存在
check_command() {
    local cmd="$1"
    local install_hint="$2"

    if ! command -v "$cmd" &> /dev/null; then
        print_error "$cmd 未安装"
        if [ -n "$install_hint" ]; then
            print_info "安装方法: $install_hint"
        fi
        return 1
    fi
    return 0
}

# 获取 CPU 核心数
get_cpu_cores() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sysctl -n hw.ncpu 2>/dev/null || echo 4
    else
        nproc 2>/dev/null || echo 4
    fi
}

# 从 CMakeLists.txt 提取版本号
get_project_version() {
    local cmake_file="$PROJECT_ROOT/CMakeLists.txt"
    if [ -f "$cmake_file" ]; then
        grep "project.*VERSION" "$cmake_file" | sed -E 's/.*VERSION ([0-9.]+).*/\1/' | head -n1
    else
        echo "$APP_VERSION"
    fi
}

# 检查是否在 macOS 上运行
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# 检查是否在 Linux 上运行
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# 显示配置摘要
show_config_summary() {
    local platform="$1"

    print_header "配置摘要"
    echo "  项目: $APP_NAME"
    echo "  版本: $(get_project_version)"
    echo "  平台: $platform"
    echo "  项目根目录: $PROJECT_ROOT"

    case "$platform" in
        macos)
            echo "  Qt 路径: $QT_MACOS_PATH"
            echo "  Team ID: $APPLE_TEAM_ID"
            echo "  构建目录: $BUILD_MACOS_DIR"
            ;;
        ios)
            echo "  Qt 路径: $QT_IOS_PATH"
            echo "  Team ID: $APPLE_TEAM_ID"
            echo "  最低版本: iOS $IOS_MIN_VERSION"
            echo "  构建目录: $BUILD_IOS_DIR"
            ;;
        android)
            echo "  Qt 路径: $QT_ANDROID_ARM64_PATH"
            echo "  Android SDK: $ANDROID_SDK_ROOT"
            echo "  Android NDK: $ANDROID_NDK"
            echo "  构建目录: $BUILD_ANDROID_DIR"
            ;;
        linux)
            echo "  Qt 路径: ${QT_LINUX_PATH:-自动检测}"
            echo "  构建目录: $BUILD_LINUX_DIR"
            ;;
    esac
    echo ""
}

# ============================================================================
# 导出变量
# ============================================================================
export APP_NAME APP_DISPLAY_NAME APP_VERSION
export APPLE_TEAM_ID APPLE_BUNDLE_ID
export QT_VERSION QT_BASE_PATH
export PROJECT_ROOT SCRIPTS_DIR

print_info "已加载公共配置: config.sh"
