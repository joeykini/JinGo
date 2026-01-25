#!/bin/bash
# ============================================================================
# JinGoVPN - iOS Deployment Script
# ============================================================================
# 用途：将 iOS 应用部署到 TestFlight 或 App Store，或创建 IPA 安装包
# 用法：
#   ./deploy-ios.sh [options]
#
# 选项：
#   -t, --testflight     上传到 TestFlight
#   -a, --appstore       提交到 App Store
#   -i, --ipa            仅创建 IPA（不上传）
#   -s, --simulator      构建模拟器版本
#   -v, --version VER    设置版本号
#   -b, --build NUM      设置构建号
#   --skip-build         跳过构建步骤
#   --interactive        交互式选择构建目标
#   -h, --help           显示帮助信息
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-ios"
PKG_DIR="$PROJECT_ROOT/pkg"
DEPLOY_TARGET=""
APP_VERSION=""
BUILD_NUMBER=""
SKIP_BUILD=false
SIMULATOR_BUILD=false
INTERACTIVE=false

# Apple 开发者配置
TEAM_ID="${APPLE_DEVELOPMENT_TEAM:-P6H5GHKRFU}"
BUNDLE_ID="cfd.jingo.acc"
APP_NAME="JinGo"

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

# 显示帮助信息
show_help() {
    cat << EOF
JinGoVPN iOS 部署脚本

用法: $0 [选项]

选项:
    -t, --testflight     上传到 TestFlight
    -a, --appstore       提交到 App Store
    -i, --ipa            仅创建 IPA（不上传）
    -s, --simulator      构建模拟器版本（.app，非 IPA）
    -v, --version VER    设置版本号 (例如: 1.0.0)
    -b, --build NUM      设置构建号 (例如: 42)
    --skip-build         跳过构建步骤（使用现有构建）
    --interactive        交互式选择构建目标
    -h, --help           显示帮助信息

环境变量:
    APPLE_DEVELOPMENT_TEAM    Apple 开发团队 ID
    APPLE_ID                  Apple ID 用户名
    APPLE_ID_PASSWORD         App-specific 密码

示例:
    # 交互式选择
    $0 --interactive

    # 创建真机 IPA（用于手动安装）
    $0 --ipa --version 1.0.0

    # 构建模拟器版本
    $0 --simulator

    # 构建并上传到 TestFlight
    $0 --testflight --version 1.0.0 --build 1

    # 仅上传现有构建到 TestFlight
    $0 --testflight --skip-build

    # 提交到 App Store 审核
    $0 --appstore --version 1.0.1

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--testflight)
                DEPLOY_TARGET="testflight"
                shift
                ;;
            -a|--appstore)
                DEPLOY_TARGET="appstore"
                shift
                ;;
            -i|--ipa)
                DEPLOY_TARGET="ipa"
                shift
                ;;
            -s|--simulator)
                DEPLOY_TARGET="simulator"
                SIMULATOR_BUILD=true
                shift
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            -v|--version)
                APP_VERSION="$2"
                shift 2
                ;;
            -b|--build)
                BUILD_NUMBER="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 交互式选择
    if [ "$INTERACTIVE" = true ]; then
        print_info "选择构建目标:"
        echo "  1) iOS 模拟器（快速测试）"
        echo "  2) iOS 真机 IPA（手动安装）"
        echo "  3) TestFlight 测试"
        echo "  4) App Store 发布"
        echo ""
        read -p "请选择 [1-4] (默认: 1): " choice
        choice=${choice:-1}

        case $choice in
            1)
                DEPLOY_TARGET="simulator"
                SIMULATOR_BUILD=true
                print_info "目标: iOS 模拟器"
                ;;
            2)
                DEPLOY_TARGET="ipa"
                print_info "目标: 创建 IPA"
                ;;
            3)
                DEPLOY_TARGET="testflight"
                print_info "目标: TestFlight"
                ;;
            4)
                DEPLOY_TARGET="appstore"
                print_info "目标: App Store"
                ;;
            *)
                print_error "无效的选择"
                exit 1
                ;;
        esac
    fi

    # 验证必要参数
    if [ -z "$DEPLOY_TARGET" ]; then
        print_error "请指定部署目标: --testflight, --appstore, --ipa, --simulator 或 --interactive"
        show_help
        exit 1
    fi
}

# 检查必要工具
check_requirements() {
    print_info "检查部署环境..."

    if ! command -v xcodebuild &> /dev/null; then
        print_error "未找到 xcodebuild，请先安装 Xcode"
        exit 1
    fi

    if ! command -v xcrun &> /dev/null; then
        print_error "未找到 xcrun 工具"
        exit 1
    fi

    # 检查 altool (上传工具)
    if ! xcrun altool --help &> /dev/null; then
        print_warning "未找到 altool，将使用 xcrun notarytool"
    fi

    print_success "部署环境检查完成"
}

# 更新版本号
update_version() {
    # 如果没有指定版本号，尝试从 CMakeLists.txt 提取
    if [ -z "$APP_VERSION" ]; then
        VERSION=$(grep "project.*VERSION" "$PROJECT_ROOT/CMakeLists.txt" | sed -E 's/.*VERSION ([0-9.]+).*/\1/' | head -n1)
        if [ -n "$VERSION" ] && [ "$VERSION" != "" ]; then
            APP_VERSION="$VERSION"
            print_info "从 CMakeLists.txt 提取版本号: $APP_VERSION"
        fi
    fi

    if [ -z "$APP_VERSION" ] && [ -z "$BUILD_NUMBER" ]; then
        return
    fi

    print_info "更新应用版本信息..."

    PLIST_PATH="$PROJECT_ROOT/platform/ios/Info.plist"
    if [ ! -f "$PLIST_PATH" ]; then
        print_warning "未找到 Info.plist: $PLIST_PATH"
        return
    fi

    # 更新版本号
    if [ -n "$APP_VERSION" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$PLIST_PATH" || true
        print_info "版本号设置为: $APP_VERSION"
    fi

    # 更新构建号
    if [ -n "$BUILD_NUMBER" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST_PATH" || true
        print_info "构建号设置为: $BUILD_NUMBER"
    fi

    print_success "版本信息更新完成"
}

# 构建 Release 版本
build_release() {
    if [ "$SKIP_BUILD" = true ]; then
        print_info "跳过构建步骤"
        return
    fi

    print_info "开始构建 Release 版本..."

    # 调用构建脚本
    BUILD_SCRIPT="$SCRIPT_DIR/../build/build-ios.sh"
    if [ -f "$BUILD_SCRIPT" ]; then
        if [ "$SIMULATOR_BUILD" = true ]; then
            bash "$BUILD_SCRIPT" --release --clean --simulator
        else
            bash "$BUILD_SCRIPT" --release --clean
        fi
    else
        print_error "未找到构建脚本: $BUILD_SCRIPT"
        exit 1
    fi

    print_success "构建完成"
}

# 验证应用程序包
verify_app() {
    print_info "验证应用程序包..."

    APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -n 1)

    if [ -z "$APP_PATH" ]; then
        print_error "未找到 ${APP_NAME}.app"
        exit 1
    fi

    # 检查 Frameworks
    if [ ! -d "$APP_PATH/Frameworks" ]; then
        print_warning "Frameworks 目录不存在"
    else
        FRAMEWORK_COUNT=$(ls -1 "$APP_PATH/Frameworks" 2>/dev/null | wc -l)
        print_success "包含 $FRAMEWORK_COUNT 个框架"
    fi

    # 检查 Info.plist
    if [ -f "$APP_PATH/Info.plist" ]; then
        BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$APP_PATH/Info.plist" 2>/dev/null || echo "Unknown")
        BUNDLE_VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Info.plist" 2>/dev/null || echo "Unknown")
        print_success "Bundle ID: $BUNDLE_ID"
        print_success "Version: $BUNDLE_VERSION"
    else
        print_warning "Info.plist 未找到"
    fi

    print_success "应用验证完成"
}

# 创建简单 IPA（非 Archive 方式）
create_simple_ipa() {
    print_info "创建 IPA 安装包..."

    APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -n 1)

    if [ -z "$APP_PATH" ]; then
        print_error "未找到 ${APP_NAME}.app"
        exit 1
    fi

    # 获取版本号
    if [ -z "$APP_VERSION" ]; then
        APP_VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Info.plist" 2>/dev/null || echo "1.0.0")
    fi

    IPA_NAME="JinGoVPN-${APP_VERSION}-iOS.ipa"
    PAYLOAD_DIR="$BUILD_DIR/Payload"
    mkdir -p "$PKG_DIR"

    # 创建 Payload 目录结构
    rm -rf "$PAYLOAD_DIR"
    mkdir -p "$PAYLOAD_DIR"

    # 复制 .app 到 Payload 目录
    cp -R "$APP_PATH" "$PAYLOAD_DIR/"

    # 打包为 IPA（IPA 就是一个 ZIP 文件，包含 Payload 目录）
    cd "$BUILD_DIR"
    zip -qr "$PKG_DIR/$IPA_NAME" Payload

    if [ $? -eq 0 ]; then
        IPA_SIZE=$(du -h "$PKG_DIR/$IPA_NAME" | cut -f1)
        print_success "IPA 创建成功: $IPA_NAME ($IPA_SIZE)"
        print_info "IPA 文件路径: $PKG_DIR/$IPA_NAME"
    else
        print_error "IPA 创建失败"
        exit 1
    fi

    # 清理 Payload 目录
    rm -rf "$PAYLOAD_DIR"
}

# 显示安装说明
show_installation_guide() {
    local target=$1

    echo ""
    print_info "安装方法:"

    if [ "$target" = "simulator" ]; then
        echo "  1. 使用命令行安装到模拟器:"
        echo "     # 列出可用的模拟器"
        echo "     xcrun simctl list devices"
        echo ""
        echo "     # 启动模拟器（如果未运行）"
        echo "     xcrun simctl boot <simulator-id>"
        echo ""
        echo "     # 安装应用"
        echo "     xcrun simctl install <simulator-id> '$APP_PATH'"
        echo ""
        echo "     # 启动应用"
        echo "     xcrun simctl launch <simulator-id> $BUNDLE_ID"
        echo ""
        echo "  2. 在 Xcode 中打开项目并运行"
        echo "     open $BUILD_DIR/${APP_NAME}.xcodeproj"
    else
        echo "  1. 使用 Xcode Devices 窗口安装:"
        echo "     Xcode -> Window -> Devices and Simulators"
        echo "     将 IPA 拖拽到设备的 Installed Apps 列表"
        echo ""
        echo "  2. 使用命令行安装:"
        echo "     xcrun devicectl device install app --device <UDID> $BUILD_DIR/$IPA_NAME"
        echo ""
        echo "  3. 使用 iTunes/Finder 安装"
        echo ""
        echo "  注意: 真机安装后需要信任开发者证书:"
        echo "  设置 -> 通用 -> VPN与设备管理 -> 开发者App"
    fi

    echo ""
}

# 归档应用
archive_app() {
    print_info "归档应用..."

    ARCHIVE_PATH="$BUILD_DIR/${APP_NAME}.xcarchive"
    EXPORT_PATH="$BUILD_DIR/export"

    # 清理之前的归档
    rm -rf "$ARCHIVE_PATH"
    rm -rf "$EXPORT_PATH"

    cd "$BUILD_DIR"

    # 使用 xcodebuild 归档
    xcodebuild archive \
        -project "${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="Apple Distribution" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        -allowProvisioningUpdates

    if [ ! -d "$ARCHIVE_PATH" ]; then
        print_error "归档失败"
        exit 1
    fi

    print_success "归档成功: $ARCHIVE_PATH"
}

# 导出 IPA
export_ipa() {
    print_info "导出 IPA 文件..."

    ARCHIVE_PATH="$BUILD_DIR/${APP_NAME}.xcarchive"
    EXPORT_PATH="$BUILD_DIR/export"

    # 创建 ExportOptions.plist
    EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"

    if [ "$DEPLOY_TARGET" = "testflight" ]; then
        METHOD="app-store"
    else
        METHOD="app-store"
    fi

    cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$METHOD</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

    # 导出 IPA
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -allowProvisioningUpdates

    IPA_PATH="$EXPORT_PATH/${APP_NAME}.ipa"
    if [ ! -f "$IPA_PATH" ]; then
        print_error "IPA 导出失败"
        exit 1
    fi

    print_success "IPA 导出成功: $IPA_PATH"
}

# 上传到 TestFlight
upload_testflight() {
    print_info "上传到 TestFlight..."

    IPA_PATH="$BUILD_DIR/export/${APP_NAME}.ipa"

    if [ -z "$APPLE_ID" ]; then
        print_error "请设置 APPLE_ID 环境变量"
        exit 1
    fi

    if [ -z "$APPLE_ID_PASSWORD" ]; then
        print_error "请设置 APPLE_ID_PASSWORD 环境变量（App-specific password）"
        exit 1
    fi

    # 使用 altool 上传
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_PATH" \
        --username "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --verbose

    print_success "上传到 TestFlight 成功！"
    print_info "请在 App Store Connect 中查看构建状态"
}

# 提交到 App Store
submit_appstore() {
    print_info "准备提交到 App Store..."

    # 首先上传到 TestFlight
    upload_testflight

    print_success "应用已上传"
    print_info "请在 App Store Connect 中手动提交审核："
    print_info "  1. 登录 https://appstoreconnect.apple.com"
    print_info "  2. 选择您的应用"
    print_info "  3. 选择刚上传的构建版本"
    print_info "  4. 填写审核信息并提交"
}

# 主函数
main() {
    echo ""
    echo "=================================================="
    echo "      JinGoVPN iOS 部署脚本"
    echo "=================================================="
    echo ""

    parse_args "$@"
    check_requirements
    update_version

    # 根据部署目标执行不同的流程
    if [ "$DEPLOY_TARGET" = "simulator" ]; then
        # 模拟器构建
        build_release
        verify_app
        show_installation_guide "simulator"

    elif [ "$DEPLOY_TARGET" = "ipa" ]; then
        # 简单 IPA 创建（手动安装）
        build_release
        verify_app
        create_simple_ipa
        show_installation_guide "device"

    elif [ "$DEPLOY_TARGET" = "testflight" ] || [ "$DEPLOY_TARGET" = "appstore" ]; then
        # Archive 流程（TestFlight/App Store）
        build_release
        archive_app
        export_ipa

        if [ "$DEPLOY_TARGET" = "testflight" ]; then
            upload_testflight
        else
            submit_appstore
        fi
    fi

    echo ""
    print_success "=================================================="
    print_success "                部署完成！"
    print_success "=================================================="
    echo ""
}

# 执行主函数
main "$@"
