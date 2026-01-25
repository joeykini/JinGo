#!/bin/bash
# ==============================================================================
# macOS DMG 创建脚本
# ==============================================================================
# 用法: ./create-dmg.sh [app_path] [output_dir]
#
# 此脚本用于在公证完成后创建 DMG，确保 DMG 包含已 staple 的应用
# ==============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 参数
APP_PATH="${1:-}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/release}"

# 自动查找应用
if [[ -z "$APP_PATH" ]]; then
    # 尝试 Release 路径
    APP_PATH="$PROJECT_ROOT/build-macos/bin/Release/JinGo.app"
    if [[ ! -d "$APP_PATH" ]]; then
        # 尝试 Debug 路径
        APP_PATH="$PROJECT_ROOT/build-macos/bin/Debug/JinGo.app"
    fi
fi

# 检查应用是否存在
if [[ ! -d "$APP_PATH" ]]; then
    print_error "应用不存在: $APP_PATH"
    print_info "用法: $0 [app_path] [output_dir]"
    exit 1
fi

# 获取应用名称
APP_NAME=$(basename "$APP_PATH" .app)

print_info "应用路径: $APP_PATH"
print_info "输出目录: $OUTPUT_DIR"

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

# ==============================================================================
# 生成输出文件名
# ==============================================================================
generate_output_name() {
    local version="$1"
    local brand="${BRAND_NAME:-jingo}"
    local date=$(date +%Y%m%d)
    echo "${brand}-${version}-${date}-macos"
}

# ==============================================================================
# 创建 DMG
# ==============================================================================
create_dmg() {
    local app_path="$1"
    local output_dir="$2"

    print_info "创建 DMG 安装镜像"

    # 获取版本号
    local version=$(plutil -extract CFBundleShortVersionString raw "$app_path/Contents/Info.plist" 2>/dev/null || echo "1.0.0")

    # 使用新命名格式: {brand}-{version}-{date}-{platform}.dmg
    local dmg_name=$(generate_output_name "$version")
    local dmg_path="$output_dir/${dmg_name}.dmg"
    local dmg_temp="/tmp/${dmg_name}-temp.dmg"
    local mount_point="/Volumes/${APP_NAME}"

    print_info "版本: $version"
    print_info "DMG 名称: ${dmg_name}.dmg"

    # 清理旧文件
    rm -f "$dmg_path" "$dmg_temp"

    # 确保挂载点未被占用
    if [[ -d "$mount_point" ]]; then
        hdiutil detach "$mount_point" > /dev/null 2>&1 || true
    fi

    # 创建临时 DMG
    print_info "创建 DMG 镜像..."

    local app_size=$(du -sm "$app_path" | awk '{print $1}')
    local dmg_size=$((app_size * 150 / 100))  # 预留 50% 额外空间
    print_info "应用大小: ${app_size}MB, DMG 预留: ${dmg_size}MB"

    hdiutil create -size ${dmg_size}m -fs HFS+ -volname "$APP_NAME" "$dmg_temp" > /dev/null 2>&1

    # 挂载
    hdiutil attach "$dmg_temp" -mountpoint "$mount_point" > /dev/null 2>&1

    # 复制应用 (使用 ditto 保留所有属性和资源分支)
    print_info "复制应用到 DMG..."
    if ! ditto "$app_path" "$mount_point/${APP_NAME}.app"; then
        print_error "复制应用到 DMG 失败"
        hdiutil detach "$mount_point" > /dev/null 2>&1 || true
        rm -f "$dmg_temp"
        return 1
    fi

    # 验证复制结果
    if [[ ! -f "$mount_point/${APP_NAME}.app/Contents/MacOS/${APP_NAME}" ]]; then
        print_error "复制验证失败: 主可执行文件不存在"
        ls -la "$mount_point/${APP_NAME}.app/Contents/MacOS/" 2>/dev/null || true
        hdiutil detach "$mount_point" > /dev/null 2>&1 || true
        rm -f "$dmg_temp"
        return 1
    fi
    print_success "应用复制完成，主可执行文件已验证"

    # 创建 Applications 软链接
    ln -s /Applications "$mount_point/Applications"

    # 设置窗口布局（简单方式）
    osascript << EOF > /dev/null 2>&1 || true
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 600, 400}
        set viewOptions to icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        close
    end tell
end tell
EOF

    sync

    # 卸载
    hdiutil detach "$mount_point" > /dev/null 2>&1 || true

    # 压缩
    print_info "压缩 DMG..."
    hdiutil convert "$dmg_temp" -format UDZO -o "$dmg_path" > /dev/null 2>&1

    # 清理临时文件
    rm -f "$dmg_temp"

    if [[ -f "$dmg_path" ]]; then
        local dmg_size_mb=$(ls -lh "$dmg_path" | awk '{print $5}')
        print_success "DMG 创建成功: $dmg_path"
        print_info "文件大小: $dmg_size_mb"
        echo "$dmg_path"
        return 0
    else
        print_error "DMG 创建失败"
        return 1
    fi
}

# ==============================================================================
# 主流程
# ==============================================================================
main() {
    echo "=============================================="
    echo "       macOS DMG 创建脚本"
    echo "=============================================="
    echo ""

    # 验证应用签名
    print_info "验证代码签名..."
    if ! codesign -vvv --deep --strict "$APP_PATH" 2>&1; then
        print_warning "代码签名验证失败，但仍然创建 DMG"
    else
        print_success "代码签名有效"
    fi

    # 检查是否已 staple
    print_info "检查公证票据..."
    if stapler validate "$APP_PATH" 2>&1 | grep -q "valid"; then
        print_success "应用已包含有效的公证票据"
    else
        print_warning "应用可能未公证或未 staple，但仍然创建 DMG"
    fi

    # 创建 DMG
    create_dmg "$APP_PATH" "$OUTPUT_DIR"

    echo ""
    echo "=============================================="
    print_success "DMG 创建完成!"
    echo "=============================================="
}

main "$@"
