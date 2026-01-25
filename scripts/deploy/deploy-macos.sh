#!/bin/bash
# ============================================================================
# JinGoVPN - macOS Deployment Script
# ============================================================================
# 用途：将 macOS 应用部署到 DMG 分发或 Mac App Store
# 用法：
#   ./deploy-macos.sh [options]
#
# 选项：
#   -d, --dmg            创建 DMG 分发包
#   -m, --mas            提交到 Mac App Store
#   -v, --version VER    设置版本号
#   -b, --build NUM      设置构建号
#   --skip-build         跳过构建步骤
#   --notarize           公证 DMG（需要 Apple Developer 账号）
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
BUILD_DIR="$PROJECT_ROOT/build-macos"
PKG_DIR="$PROJECT_ROOT/pkg"
DEPLOY_TARGET=""
APP_VERSION=""
BUILD_NUMBER=""
SKIP_BUILD=false
NOTARIZE=false

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
JinGoVPN macOS 部署脚本

用法: $0 [选项]

选项:
    -d, --dmg            创建 DMG 分发包
    -m, --mas            提交到 Mac App Store
    -v, --version VER    设置版本号 (例如: 1.0.0)
    -b, --build NUM      设置构建号 (例如: 42)
    --skip-build         跳过构建步骤（使用现有构建）
    --notarize           公证 DMG（需要 Apple Developer 账号）
    -h, --help           显示帮助信息

环境变量:
    APPLE_DEVELOPMENT_TEAM    Apple 开发团队 ID
    APPLE_ID                  Apple ID 用户名
    APPLE_ID_PASSWORD         App-specific 密码

示例:
    # 构建并创建 DMG
    $0 --dmg --version 1.0.0

    # 创建并公证 DMG
    $0 --dmg --notarize

    # 提交到 Mac App Store
    $0 --mas --version 1.0.0 --build 1

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dmg)
                DEPLOY_TARGET="dmg"
                shift
                ;;
            -m|--mas)
                DEPLOY_TARGET="mas"
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
            --notarize)
                NOTARIZE=true
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

    # 验证必要参数
    if [ -z "$DEPLOY_TARGET" ]; then
        print_error "请指定部署目标: --dmg 或 --mas"
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

    if [ "$DEPLOY_TARGET" = "dmg" ] && ! command -v hdiutil &> /dev/null; then
        print_error "未找到 hdiutil 工具"
        exit 1
    fi

    # 检查 macdeployqt（用于打包 Qt 依赖）
    MACDEPLOYQT=""
    if command -v macdeployqt &> /dev/null; then
        MACDEPLOYQT="macdeployqt"
        print_success "macdeployqt: $(which macdeployqt)"
    else
        # 尝试在常见 Qt 安装位置查找
        QT_PATHS=(
            "$HOME/Qt/*/macos/bin/macdeployqt"
            "/Applications/Qt/*/macos/bin/macdeployqt"
            "/usr/local/opt/qt@6/bin/macdeployqt"
            "/Volumes/mindata/Applications/Qt/*/macos/bin/macdeployqt"
        )

        for pattern in "${QT_PATHS[@]}"; do
            for path in $pattern; do
                if [[ -x "$path" ]]; then
                    MACDEPLOYQT="$path"
                    print_success "macdeployqt 找到: $path"
                    break 2
                fi
            done
        done

        if [[ -z "$MACDEPLOYQT" ]]; then
            print_warning "macdeployqt 未找到，DMG 可能缺少 Qt 依赖"
        fi
    fi

    print_success "部署环境检查完成"
}

# 更新版本号
update_version() {
    if [ -z "$APP_VERSION" ] && [ -z "$BUILD_NUMBER" ]; then
        return
    fi

    print_info "更新应用版本信息..."

    PLIST_PATH="$PROJECT_ROOT/platform/macos/Info.plist"
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
    BUILD_SCRIPT="$SCRIPT_DIR/../build/build-macos.sh"
    if [ -f "$BUILD_SCRIPT" ]; then
        bash "$BUILD_SCRIPT" --release --clean
    else
        print_error "未找到构建脚本: $BUILD_SCRIPT"
        exit 1
    fi

    print_success "构建完成"
}

# 验证应用程序包
verify_app_bundle() {
    print_info "验证应用程序包..."

    APP_PATH="$BUILD_DIR/bin/Release/${APP_NAME}.app"

    if [ ! -d "$APP_PATH" ]; then
        print_error "未找到应用: $APP_PATH"
        exit 1
    fi

    # 检查基本结构
    if [ ! -d "$APP_PATH/Contents/MacOS" ]; then
        print_error "应用程序包结构不正确"
        exit 1
    fi
    print_success "应用程序包结构正确"

    # 检查可执行文件
    EXECUTABLE="$APP_PATH/Contents/MacOS/JinGo"
    if [ ! -f "$EXECUTABLE" ]; then
        print_error "可执行文件不存在: $EXECUTABLE"
        exit 1
    fi
    print_success "可执行文件存在"

    # 检查 Frameworks
    if [ ! -d "$APP_PATH/Contents/Frameworks" ]; then
        print_warning "Frameworks 目录不存在，macdeployqt 将创建它"
    else
        FRAMEWORK_COUNT=$(ls -1 "$APP_PATH/Contents/Frameworks" 2>/dev/null | wc -l)
        print_success "Frameworks: $FRAMEWORK_COUNT 个"
    fi

    # 显示依赖库
    print_info "主要依赖库:"
    otool -L "$EXECUTABLE" | grep -E "(Qt|LibXray|@rpath)" | sed 's/^/  /' || true

    # 验证 RPATH 设置
    print_info "RPATH 设置:"
    otool -l "$EXECUTABLE" | grep -A 2 "LC_RPATH" | grep "path" | sed 's/^/  /' || true

    print_success "应用验证完成"
}

# 运行 macdeployqt
run_macdeployqt() {
    if [ -z "$MACDEPLOYQT" ]; then
        print_warning "跳过 macdeployqt（未找到工具）"
        return
    fi

    print_info "运行 macdeployqt 打包 Qt 依赖..."

    APP_PATH="$BUILD_DIR/bin/Release/${APP_NAME}.app"

    "$MACDEPLOYQT" "$APP_PATH" \
        -verbose=1 \
        -qmldir="$PROJECT_ROOT/resources/qml"

    if [ $? -eq 0 ]; then
        print_success "macdeployqt 完成"
    else
        print_warning "macdeployqt 执行出现问题，但继续进行..."
    fi
}

# 签名应用
sign_app() {
    print_info "签名应用..."

    APP_PATH="$BUILD_DIR/bin/Release/${APP_NAME}.app"

    if [ ! -d "$APP_PATH" ]; then
        print_error "未找到应用: $APP_PATH"
        exit 1
    fi

    # 签名应用
    codesign --force --deep --sign "Developer ID Application" \
        --options runtime \
        --entitlements "$PROJECT_ROOT/platform/macos/JinGo.entitlements" \
        "$APP_PATH"

    # 验证签名
    codesign --verify --verbose "$APP_PATH"

    print_success "应用签名成功"
}

# 创建 DMG
create_dmg() {
    print_info "创建 DMG 安装包..."

    APP_PATH="$BUILD_DIR/bin/Release/${APP_NAME}.app"

    # 获取版本号
    if [ -z "$APP_VERSION" ]; then
        APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
    fi

    DMG_NAME="JinGoVPN-${APP_VERSION}-macOS.dmg"
    mkdir -p "$PKG_DIR"
    DMG_PATH="$PKG_DIR/$DMG_NAME"

    # 尝试使用 CPack 创建 DMG
    print_info "尝试使用 CPack 创建 DMG..."
    cd "$BUILD_DIR"

    if cpack -G DragNDrop 2>/dev/null; then
        # CPack 成功，查找生成的 DMG
        CPACK_DMG=$(find "$BUILD_DIR" -name "*.dmg" -type f | head -n 1)
        if [ -n "$CPACK_DMG" ] && [ "$CPACK_DMG" != "$DMG_PATH" ]; then
            mv "$CPACK_DMG" "$DMG_PATH" 2>/dev/null || cp "$CPACK_DMG" "$DMG_PATH"
        fi
        print_success "CPack 创建 DMG 成功"
    else
        # CPack 失败，手动创建 DMG
        print_warning "CPack 失败，尝试手动创建 DMG..."

        DMG_DIR="$BUILD_DIR/dmg"
        rm -rf "$DMG_DIR"
        mkdir -p "$DMG_DIR"

        # 复制应用
        cp -R "$APP_PATH" "$DMG_DIR/"

        # 创建 Applications 链接
        ln -s /Applications "$DMG_DIR/Applications"

        # 创建 DMG
        print_info "生成 DMG 文件..."
        rm -f "$DMG_PATH"
        hdiutil create -volname "JinGoVPN" \
            -srcfolder "$DMG_DIR" \
            -ov -format UDZO \
            "$DMG_PATH"

        if [ $? -eq 0 ]; then
            print_success "手动创建 DMG 成功"
        else
            print_error "DMG 创建失败"
            exit 1
        fi

        # 清理临时目录
        rm -rf "$DMG_DIR"
    fi

    if [ -f "$DMG_PATH" ]; then
        # 显示 DMG 信息
        DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
        print_success "DMG 创建成功: $DMG_NAME ($DMG_SIZE)"
        print_info "DMG 路径: $DMG_PATH"

        # 在 Finder 中显示 DMG
        print_info "在 Finder 中显示 DMG 文件..."
        open -R "$DMG_PATH"
    else
        print_error "DMG 文件未生成"
        exit 1
    fi
}

# 公证 DMG
notarize_dmg() {
    if [ "$NOTARIZE" = false ]; then
        return
    fi

    print_info "开始公证 DMG..."

    if [ -z "$APPLE_ID" ]; then
        print_error "请设置 APPLE_ID 环境变量"
        exit 1
    fi

    if [ -z "$APPLE_ID_PASSWORD" ]; then
        print_error "请设置 APPLE_ID_PASSWORD 环境变量（App-specific password）"
        exit 1
    fi

    DMG_PATH="$PKG_DIR/JinGoVPN-${APP_VERSION}-macOS.dmg"

    # 上传公证
    print_info "上传 DMG 进行公证..."
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait

    # 装订公证票据
    print_info "装订公证票据..."
    xcrun stapler staple "$DMG_PATH"

    # 验证
    xcrun stapler validate "$DMG_PATH"

    print_success "DMG 公证成功！"
}

# 归档应用（Mac App Store）
archive_for_mas() {
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
        CODE_SIGN_IDENTITY="3rd Party Mac Developer Application" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        -allowProvisioningUpdates

    if [ ! -d "$ARCHIVE_PATH" ]; then
        print_error "归档失败"
        exit 1
    fi

    print_success "归档成功: $ARCHIVE_PATH"
}

# 导出 PKG（Mac App Store）
export_pkg() {
    print_info "导出 PKG 文件..."

    ARCHIVE_PATH="$BUILD_DIR/${APP_NAME}.xcarchive"
    EXPORT_PATH="$BUILD_DIR/export"

    # 创建 ExportOptions.plist
    EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"

    cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

    # 导出 PKG
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -allowProvisioningUpdates

    PKG_PATH="$EXPORT_PATH/${APP_NAME}.pkg"
    if [ ! -f "$PKG_PATH" ]; then
        print_error "PKG 导出失败"
        exit 1
    fi

    print_success "PKG 导出成功: $PKG_PATH"
}

# 上传到 Mac App Store
upload_mas() {
    print_info "上传到 Mac App Store..."

    PKG_PATH="$BUILD_DIR/export/${APP_NAME}.pkg"

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
        --type macos \
        --file "$PKG_PATH" \
        --username "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --verbose

    print_success "上传到 Mac App Store 成功！"
    print_info "请在 App Store Connect 中查看构建状态"
}

# 主函数
main() {
    echo ""
    echo "=================================================="
    echo "      JinGoVPN macOS 部署脚本"
    echo "=================================================="
    echo ""

    parse_args "$@"
    check_requirements
    update_version
    build_release

    if [ "$DEPLOY_TARGET" = "dmg" ]; then
        # DMG 分发流程
        verify_app_bundle
        run_macdeployqt
        sign_app
        create_dmg
        notarize_dmg

        echo ""
        print_success "=================================================="
        print_success "            DMG 分发包已创建！"
        print_success "=================================================="
        echo ""
        print_info "下一步:"
        echo "  1. 测试应用程序:"
        echo "     open '$BUILD_DIR/bin/Release/${APP_NAME}.app'"
        echo ""
        echo "  2. 公证 DMG（如果尚未公证）:"
        echo "     $0 --dmg --notarize --skip-build"
        echo ""

    elif [ "$DEPLOY_TARGET" = "mas" ]; then
        # Mac App Store 流程
        verify_app_bundle
        archive_for_mas
        export_pkg
        upload_mas

        echo ""
        print_success "=================================================="
        print_success "          已上传到 Mac App Store"
        print_success "=================================================="
        echo ""
    fi

    print_success "部署完成！"
    echo ""
}

# 执行主函数
main "$@"
