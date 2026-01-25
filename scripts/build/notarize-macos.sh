#!/bin/bash
# ==============================================================================
# macOS 应用公证脚本
# ==============================================================================
# 用法: ./notarize-macos.sh [app_path]
#
# 环境变量 (必需):
#   APPLE_ID              - Apple Developer 账号邮箱
#   APPLE_APP_PASSWORD    - App-specific password (在 appleid.apple.com 生成)
#   APPLE_TEAM_ID         - 开发团队 ID
#
# 或使用 App Store Connect API Key:
#   APPLE_API_KEY_ID      - API Key ID
#   APPLE_API_KEY_ISSUER  - API Key Issuer ID
#   APPLE_API_KEY_PATH    - .p8 私钥文件路径
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

# 默认应用路径
DEFAULT_APP_PATH="$PROJECT_ROOT/build-macos/bin/Release/JinGo.app"
APP_PATH="${1:-$DEFAULT_APP_PATH}"

# 检查应用是否存在
if [[ ! -d "$APP_PATH" ]]; then
    # 尝试 Debug 路径
    APP_PATH="$PROJECT_ROOT/build-macos/bin/Debug/JinGo.app"
    if [[ ! -d "$APP_PATH" ]]; then
        print_error "应用不存在: $APP_PATH"
        print_info "请先运行 build-macos.sh 构建应用"
        exit 1
    fi
fi

print_info "应用路径: $APP_PATH"

# ==============================================================================
# 默认凭据 (可通过环境变量覆盖)
# ==============================================================================
APPLE_ID="${APPLE_ID:-jingo@6us.me}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-apzd-uyzu-hjgh-isug}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-P6H5GHKRFU}"

# ==============================================================================
# 检查凭据
# ==============================================================================
check_credentials() {
    if [[ -n "$APPLE_API_KEY_ID" && -n "$APPLE_API_KEY_ISSUER" && -n "$APPLE_API_KEY_PATH" ]]; then
        print_info "使用 App Store Connect API Key 认证"
        AUTH_METHOD="apikey"
        return 0
    elif [[ -n "$APPLE_ID" && -n "$APPLE_APP_PASSWORD" && -n "$APPLE_TEAM_ID" ]]; then
        print_info "使用 Apple ID 认证"
        AUTH_METHOD="appleid"
        return 0
    else
        print_error "缺少公证凭据"
        exit 1
    fi
}

# ==============================================================================
# 创建 ZIP 用于公证
# ==============================================================================
create_zip() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    local zip_path="/tmp/${app_name}_notarize.zip"

    print_info "创建 ZIP: $zip_path" >&2

    # 删除旧的 ZIP
    rm -f "$zip_path"

    # 创建 ZIP (使用 ditto 保留签名)
    ditto -c -k --keepParent "$app_path" "$zip_path"

    if [[ ! -f "$zip_path" ]]; then
        print_error "创建 ZIP 失败" >&2
        exit 1
    fi

    print_success "ZIP 创建成功: $(du -h "$zip_path" | cut -f1)" >&2
    echo "$zip_path"
}

# ==============================================================================
# 提交公证
# ==============================================================================
submit_notarization() {
    local zip_path="$1"

    print_info "提交公证请求..."

    local submit_output
    local submit_exit_code

    if [[ "$AUTH_METHOD" == "apikey" ]]; then
        submit_output=$(xcrun notarytool submit "$zip_path" \
            --key "$APPLE_API_KEY_PATH" \
            --key-id "$APPLE_API_KEY_ID" \
            --issuer "$APPLE_API_KEY_ISSUER" \
            --wait \
            --timeout 30m \
            2>&1) || submit_exit_code=$?
    else
        submit_output=$(xcrun notarytool submit "$zip_path" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_APP_PASSWORD" \
            --team-id "$APPLE_TEAM_ID" \
            --wait \
            --timeout 30m \
            2>&1) || submit_exit_code=$?
    fi

    echo "$submit_output"

    # 检查结果
    if echo "$submit_output" | grep -q "status: Accepted"; then
        print_success "公证成功!"
        return 0
    elif echo "$submit_output" | grep -q "status: Invalid"; then
        print_error "公证被拒绝"

        # 获取详细日志
        local submission_id=$(echo "$submit_output" | grep -o 'id: [a-f0-9-]*' | head -1 | cut -d' ' -f2)
        if [[ -n "$submission_id" ]]; then
            print_info "获取详细日志..."
            if [[ "$AUTH_METHOD" == "apikey" ]]; then
                xcrun notarytool log "$submission_id" \
                    --key "$APPLE_API_KEY_PATH" \
                    --key-id "$APPLE_API_KEY_ID" \
                    --issuer "$APPLE_API_KEY_ISSUER"
            else
                xcrun notarytool log "$submission_id" \
                    --apple-id "$APPLE_ID" \
                    --password "$APPLE_APP_PASSWORD" \
                    --team-id "$APPLE_TEAM_ID"
            fi
        fi
        return 1
    else
        print_error "公证状态未知"
        return 1
    fi
}

# ==============================================================================
# Staple 票据
# ==============================================================================
staple_app() {
    local app_path="$1"

    print_info "Staple 公证票据到应用..."

    if xcrun stapler staple "$app_path"; then
        print_success "Staple 成功!"
        return 0
    else
        print_error "Staple 失败"
        return 1
    fi
}

# ==============================================================================
# 验证公证
# ==============================================================================
verify_notarization() {
    local app_path="$1"

    print_info "验证公证状态..."

    if spctl -a -vvv -t exec "$app_path" 2>&1 | grep -q "accepted"; then
        print_success "应用已通过 Gatekeeper 验证"
        spctl -a -vvv -t exec "$app_path" 2>&1
        return 0
    else
        print_warning "Gatekeeper 验证结果:"
        spctl -a -vvv -t exec "$app_path" 2>&1
        return 1
    fi
}

# ==============================================================================
# 主流程
# ==============================================================================
main() {
    echo "=============================================="
    echo "       macOS 应用公证脚本"
    echo "=============================================="
    echo ""

    # 检查凭据
    check_credentials

    # 验证代码签名
    print_info "验证代码签名..."
    if ! codesign -vvv --deep --strict "$APP_PATH" 2>&1; then
        print_error "代码签名无效，请先正确签名应用"
        exit 1
    fi
    print_success "代码签名有效"

    # 创建 ZIP
    ZIP_PATH=$(create_zip "$APP_PATH")

    # 提交公证
    if ! submit_notarization "$ZIP_PATH"; then
        print_error "公证失败"
        rm -f "$ZIP_PATH"
        exit 1
    fi

    # 清理 ZIP
    rm -f "$ZIP_PATH"

    # Staple 票据
    if ! staple_app "$APP_PATH"; then
        print_warning "Staple 失败，但公证已通过"
        print_info "用户下载后系统会自动验证公证状态"
    fi

    # 验证
    verify_notarization "$APP_PATH"

    echo ""
    echo "=============================================="
    print_success "公证流程完成!"
    echo "=============================================="
    echo ""
    echo "应用路径: $APP_PATH"
    echo ""
}

main "$@"
