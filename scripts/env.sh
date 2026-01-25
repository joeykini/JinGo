#!/bin/bash
# ============================================================================
# JinGo VPN - 环境配置文件
# ============================================================================
# 此文件定义了开发环境和打包环境的路径配置
# 支持自动检测当前环境类型（开发/打包）和平台（macOS/Linux/Windows）
#
# 环境类型:
#   - development: 本地开发环境
#   - production:  服务器打包环境
#
# 使用方法:
#   source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
# ============================================================================

# ============================================================================
# 环境路径定义
# ============================================================================

# --------------------- 本地开发环境 ---------------------
# macOS 开发环境
DEV_MACOS_GO_PATH="/Volumes/mindata/Library/go"
DEV_MACOS_QT_BASE="/Volumes/mindata/Applications/Qt"
DEV_MACOS_QT_VERSION="6.10.0"
DEV_MACOS_CODE_DIR="/Volumes/mindata/app/OpineWork/JinGo"

# Ubuntu 开发环境
DEV_LINUX_GO_PATH=""  # 使用系统路径
DEV_LINUX_QT_BASE="/mnt/develop/Qt"
DEV_LINUX_QT_VERSION="6.10.0"
DEV_LINUX_CODE_DIR="/mnt/develop/app/OpineWork/JinGo"

# Windows 开发环境
DEV_WINDOWS_GO_PATH=""  # 使用系统路径
DEV_WINDOWS_QT_BASE="D:\\Qt"
DEV_WINDOWS_QT_VERSION="6.10.0"
DEV_WINDOWS_CODE_DIR="D:\\app\\OpineWork\\JinGo"

# --------------------- 服务器打包环境 ---------------------
# macOS 打包环境
PROD_MACOS_GO_PATH=""  # 使用系统路径
PROD_MACOS_QT_BASE="/Volumes/mindata/Qt"
PROD_MACOS_QT_VERSION="6.10.1"
PROD_MACOS_CODE_DIR="/Volumes/mindata/app/OpineWork/JinGo"

# Ubuntu 打包环境
PROD_LINUX_GO_PATH=""  # 使用系统路径
PROD_LINUX_QT_BASE="/mnt/dev/Qt"
PROD_LINUX_QT_VERSION="6.10.1"
PROD_LINUX_CODE_DIR="/mnt/dev/app/OpineWork/JinGo"

# Windows 打包环境
PROD_WINDOWS_GO_PATH=""  # 使用系统路径
PROD_WINDOWS_QT_BASE="D:\\Qt"
PROD_WINDOWS_QT_VERSION="6.10.1"
PROD_WINDOWS_CODE_DIR="D:\\app\\OpineWork\\JinGo"

# ============================================================================
# 平台检测函数
# ============================================================================

# 检测当前操作系统
detect_platform() {
    case "$OSTYPE" in
        darwin*)
            echo "macos"
            ;;
        linux-gnu*)
            echo "linux"
            ;;
        msys*|cygwin*|mingw*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 检测是否为开发环境还是打包环境
# 通过检测特定路径特征来判断
detect_environment() {
    local platform=$(detect_platform)

    case "$platform" in
        macos)
            # 检测 macOS 环境
            # 开发环境: /Volumes/mindata/Applications/Qt
            # 打包环境: /Volumes/mindata/Qt
            if [[ -d "/Volumes/mindata/Applications/Qt" ]]; then
                echo "development"
            elif [[ -d "/Volumes/mindata/Qt" ]]; then
                echo "production"
            else
                # 尝试通过 Qt 版本判断
                if [[ -d "/Volumes/mindata/Applications/Qt/6.10.0" ]]; then
                    echo "development"
                elif [[ -d "/Volumes/mindata/Qt/6.10.1" ]]; then
                    echo "production"
                else
                    echo "unknown"
                fi
            fi
            ;;
        linux)
            # 检测 Linux 环境
            # 开发环境: /mnt/develop/Qt
            # 打包环境: /mnt/dev/Qt
            if [[ -d "/mnt/develop/Qt" ]]; then
                echo "development"
            elif [[ -d "/mnt/dev/Qt" ]]; then
                echo "production"
            else
                echo "unknown"
            fi
            ;;
        windows)
            # Windows 环境通过 Qt 版本判断
            # 开发环境: Qt 6.10.0
            # 打包环境: Qt 6.10.1
            if [[ -d "D:/Qt/6.10.0" ]] || [[ -d "/d/Qt/6.10.0" ]]; then
                echo "development"
            elif [[ -d "D:/Qt/6.10.1" ]] || [[ -d "/d/Qt/6.10.1" ]]; then
                echo "production"
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ============================================================================
# 路径配置函数
# ============================================================================

# 获取 Qt 基础路径
get_qt_base_path() {
    local platform=$(detect_platform)
    local env=$(detect_environment)

    case "$platform" in
        macos)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_MACOS_QT_BASE"
            else
                echo "$PROD_MACOS_QT_BASE"
            fi
            ;;
        linux)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_LINUX_QT_BASE"
            else
                echo "$PROD_LINUX_QT_BASE"
            fi
            ;;
        windows)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_WINDOWS_QT_BASE"
            else
                echo "$PROD_WINDOWS_QT_BASE"
            fi
            ;;
    esac
}

# 获取 Qt 版本
get_qt_version() {
    local platform=$(detect_platform)
    local env=$(detect_environment)

    case "$platform" in
        macos)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_MACOS_QT_VERSION"
            else
                echo "$PROD_MACOS_QT_VERSION"
            fi
            ;;
        linux)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_LINUX_QT_VERSION"
            else
                echo "$PROD_LINUX_QT_VERSION"
            fi
            ;;
        windows)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_WINDOWS_QT_VERSION"
            else
                echo "$PROD_WINDOWS_QT_VERSION"
            fi
            ;;
    esac
}

# 获取 Go 路径
get_go_path() {
    local platform=$(detect_platform)
    local env=$(detect_environment)

    case "$platform" in
        macos)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_MACOS_GO_PATH"
            else
                echo "$PROD_MACOS_GO_PATH"
            fi
            ;;
        linux)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_LINUX_GO_PATH"
            else
                echo "$PROD_LINUX_GO_PATH"
            fi
            ;;
        windows)
            if [[ "$env" == "development" ]]; then
                echo "$DEV_WINDOWS_GO_PATH"
            else
                echo "$PROD_WINDOWS_GO_PATH"
            fi
            ;;
    esac
}

# ============================================================================
# Qt 路径自动检测函数
# ============================================================================

# 自动检测 Qt 安装路径
# 优先级: 环境变量 > 配置的路径 > 自动搜索
auto_detect_qt_path() {
    local platform=$(detect_platform)
    local qt_base=$(get_qt_base_path)
    local qt_version=$(get_qt_version)

    # 根据平台构建 Qt 路径
    local qt_path=""
    case "$platform" in
        macos)
            qt_path="$qt_base/$qt_version/macos"
            ;;
        linux)
            qt_path="$qt_base/$qt_version/gcc_64"
            ;;
        windows)
            qt_path="$qt_base/$qt_version/mingw_64"
            ;;
    esac

    # 检查配置的路径是否存在
    if [[ -d "$qt_path" ]]; then
        echo "$qt_path"
        return 0
    fi

    # 自动搜索其他可能的路径
    local search_paths=()

    case "$platform" in
        macos)
            search_paths=(
                "$qt_base/*/macos"
                "/opt/Qt/*/macos"
                "$HOME/Qt/*/macos"
                "/usr/local/Qt/*/macos"
            )
            ;;
        linux)
            search_paths=(
                "$qt_base/*/gcc_64"
                "/opt/Qt/*/gcc_64"
                "$HOME/Qt/*/gcc_64"
                "/usr/lib/x86_64-linux-gnu/qt6"
                "/usr/lib/qt6"
            )
            ;;
        windows)
            search_paths=(
                "$qt_base/*/mingw_64"
                "C:/Qt/*/mingw_64"
                "/c/Qt/*/mingw_64"
            )
            ;;
    esac

    # 搜索可用的 Qt 安装
    for pattern in "${search_paths[@]}"; do
        for path in $pattern; do
            if [[ -d "$path" ]]; then
                echo "$path"
                return 0
            fi
        done
    done

    # 未找到
    return 1
}

# 自动检测 Qt iOS 路径
auto_detect_qt_ios_path() {
    local qt_base=$(get_qt_base_path)
    local qt_version=$(get_qt_version)

    local qt_ios_path="$qt_base/$qt_version/ios"

    if [[ -d "$qt_ios_path" ]]; then
        echo "$qt_ios_path"
        return 0
    fi

    # 搜索其他路径
    local search_paths=(
        "$qt_base/*/ios"
        "/opt/Qt/*/ios"
        "$HOME/Qt/*/ios"
    )

    for pattern in "${search_paths[@]}"; do
        for path in $pattern; do
            if [[ -d "$path" ]]; then
                echo "$path"
                return 0
            fi
        done
    done

    return 1
}

# 自动检测 Qt Android 路径
auto_detect_qt_android_path() {
    local abi="${1:-arm64_v8a}"
    local qt_base=$(get_qt_base_path)
    local qt_version=$(get_qt_version)

    local qt_android_path="$qt_base/$qt_version/android_$abi"

    if [[ -d "$qt_android_path" ]]; then
        echo "$qt_android_path"
        return 0
    fi

    # 搜索其他路径
    local search_paths=(
        "$qt_base/*/android_$abi"
        "/opt/Qt/*/android_$abi"
        "$HOME/Qt/*/android_$abi"
    )

    for pattern in "${search_paths[@]}"; do
        for path in $pattern; do
            if [[ -d "$path" ]]; then
                echo "$path"
                return 0
            fi
        done
    done

    return 1
}

# ============================================================================
# Go 路径配置
# ============================================================================

# 配置 Go 环境
setup_go_path() {
    local go_path=$(get_go_path)

    if [[ -n "$go_path" ]] && [[ -d "$go_path" ]]; then
        export GOROOT="$go_path"
        export PATH="$GOROOT/bin:$PATH"
        return 0
    fi

    # 使用系统 Go
    if command -v go &> /dev/null; then
        return 0
    fi

    return 1
}

# ============================================================================
# 环境信息显示
# ============================================================================

# 显示当前环境信息
show_environment_info() {
    local platform=$(detect_platform)
    local env=$(detect_environment)
    local qt_base=$(get_qt_base_path)
    local qt_version=$(get_qt_version)
    local go_path=$(get_go_path)

    echo "============================================"
    echo "环境信息"
    echo "============================================"
    echo "平台:       $platform"
    echo "环境类型:   $env"
    echo "Qt 基础路径: $qt_base"
    echo "Qt 版本:    $qt_version"
    if [[ -n "$go_path" ]]; then
        echo "Go 路径:    $go_path"
    else
        echo "Go 路径:    系统路径"
    fi
    echo "============================================"
}

# ============================================================================
# 导出变量
# ============================================================================

# 检测并设置环境变量
JINGO_PLATFORM=$(detect_platform)
JINGO_ENV=$(detect_environment)
JINGO_QT_BASE=$(get_qt_base_path)
JINGO_QT_VERSION=$(get_qt_version)
JINGO_GO_PATH=$(get_go_path)

export JINGO_PLATFORM
export JINGO_ENV
export JINGO_QT_BASE
export JINGO_QT_VERSION
export JINGO_GO_PATH

# 设置 Go 环境（如果有自定义路径）
if [[ -n "$JINGO_GO_PATH" ]] && [[ -d "$JINGO_GO_PATH" ]]; then
    setup_go_path
fi
