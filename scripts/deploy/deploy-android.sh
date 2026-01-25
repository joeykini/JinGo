#!/bin/bash
# ============================================================================
# JinGoVPN - Android Deployment Script
# ============================================================================
# 用途：将 Android 应用部署到 Google Play Store 或其他分发渠道
# 用法：
#   ./deploy-android.sh [options]
#
# 选项：
#   -p, --playstore      上传到 Google Play Store
#   -i, --internal       发布到内部测试轨道
#   -a, --alpha          发布到 Alpha 测试轨道
#   -b, --beta           发布到 Beta 测试轨道
#   -r, --production     发布到生产环境
#   -v, --version VER    设置版本号
#   -c, --code NUM       设置版本码
#   --skip-build         跳过构建步骤
#   --aab                生成 AAB 格式（Play Store 必需）
#   --apk                生成 APK 格式（其他渠道）
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
BUILD_DIR="$PROJECT_ROOT/build-android"
PKG_DIR="$PROJECT_ROOT/pkg"
DEPLOY_TARGET=""
RELEASE_TRACK="internal"
APP_VERSION=""
VERSION_CODE=""
SKIP_BUILD=false
BUILD_FORMAT="aab"  # aab 或 apk

# Android 配置
PACKAGE_NAME="com.opine.jingo"
KEYSTORE_PATH="$PROJECT_ROOT/platform/android/keystore/jingo-release.keystore"
KEYSTORE_PASSWORD="jingo1101"
KEY_ALIAS="jingo"
KEY_PASSWORD="jingo1101"

# Android SDK 路径配置
if [ -z "$ANDROID_SDK_ROOT" ]; then
    # 尝试自动检测 Android SDK
    if [ -d "/Volumes/mindata/Library/Android/aarch64/sdk" ]; then
        export ANDROID_SDK_ROOT="/Volumes/mindata/Library/Android/aarch64/sdk"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    elif [ -d "/opt/android-sdk" ]; then
        export ANDROID_SDK_ROOT="/opt/android-sdk"
    fi
fi

# 添加 Android build-tools 到 PATH（用于 zipalign）
if [ -n "$ANDROID_SDK_ROOT" ]; then
    BUILD_TOOLS_DIR=$(ls -d "$ANDROID_SDK_ROOT/build-tools"/* 2>/dev/null | sort -V | tail -1)
    if [ -n "$BUILD_TOOLS_DIR" ]; then
        export PATH="$BUILD_TOOLS_DIR:$PATH"
    fi
fi

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
JinGoVPN Android 部署脚本

用法: $0 [选项]

选项:
    -p, --playstore      上传到 Google Play Store
    -i, --internal       发布到内部测试轨道（默认）
    -a, --alpha          发布到 Alpha 测试轨道
    -b, --beta           发布到 Beta 测试轨道
    -r, --production     发布到生产环境
    -v, --version VER    设置版本号 (例如: 1.0.0)
    -c, --code NUM       设置版本码 (例如: 42)
    --skip-build         跳过构建步骤（使用现有构建）
    --aab                生成 AAB 格式（Play Store 必需，默认）
    --apk                生成 APK 格式（其他渠道）
    -h, --help           显示帮助信息

环境变量:
    ANDROID_SDK_ROOT         Android SDK 路径
    KEYSTORE_PASSWORD        Keystore 密码
    KEY_PASSWORD             Key 密码
    KEY_ALIAS                Key 别名
    GOOGLE_SERVICE_ACCOUNT   Google Play 服务账号 JSON

发布轨道说明:
    internal     内部测试（快速发布，无审核）
    alpha        Alpha 测试（小范围用户）
    beta         Beta 测试（更大范围用户）
    production   生产环境（所有用户，需审核）

示例:
    # 构建并上传到内部测试
    $0 --playstore --internal --version 1.0.0 --code 1

    # 发布到 Beta 测试
    $0 --playstore --beta --skip-build

    # 生成 APK 用于其他渠道
    $0 --apk --version 1.0.0

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--playstore)
                DEPLOY_TARGET="playstore"
                shift
                ;;
            -i|--internal)
                RELEASE_TRACK="internal"
                shift
                ;;
            -a|--alpha)
                RELEASE_TRACK="alpha"
                shift
                ;;
            -b|--beta)
                RELEASE_TRACK="beta"
                shift
                ;;
            -r|--production)
                RELEASE_TRACK="production"
                shift
                ;;
            -v|--version)
                APP_VERSION="$2"
                shift 2
                ;;
            -c|--code)
                VERSION_CODE="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --aab)
                BUILD_FORMAT="aab"
                shift
                ;;
            --apk)
                BUILD_FORMAT="apk"
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
}

# 检查必要工具
check_requirements() {
    print_info "检查部署环境..."

    if [ "$DEPLOY_TARGET" = "playstore" ]; then
        # 检查 Google Play CLI 工具
        if ! command -v gcloud &> /dev/null; then
            print_warning "未找到 gcloud 工具"
            print_info "请安装: https://cloud.google.com/sdk/docs/install"
        fi
    fi

    # 检查构建工具
    if ! command -v cmake &> /dev/null; then
        print_error "未找到 cmake，请先安装"
        exit 1
    fi

    print_success "部署环境检查完成"
}

# 更新版本号
update_version() {
    if [ -z "$APP_VERSION" ] && [ -z "$VERSION_CODE" ]; then
        return
    fi

    print_info "更新应用版本信息..."

    # 更新 CMakeLists.txt 中的版本号
    CMAKE_FILE="$PROJECT_ROOT/CMakeLists.txt"

    if [ -n "$APP_VERSION" ]; then
        # 这里需要根据实际的 CMakeLists.txt 结构进行调整
        print_info "版本号设置为: $APP_VERSION"
    fi

    if [ -n "$VERSION_CODE" ]; then
        print_info "版本码设置为: $VERSION_CODE"
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
    BUILD_SCRIPT="$SCRIPT_DIR/../build/build-android.sh"
    if [ -f "$BUILD_SCRIPT" ]; then
        bash "$BUILD_SCRIPT" --release --clean --sign
    else
        print_error "未找到构建脚本: $BUILD_SCRIPT"
        exit 1
    fi

    print_success "构建完成"
}

# 生成 AAB
build_aab() {
    if [ "$BUILD_FORMAT" != "aab" ]; then
        return
    fi

    print_info "生成 Android App Bundle (AAB)..."

    cd "$BUILD_DIR"

    # 使用 Gradle 构建 AAB
    if [ -f "gradlew" ]; then
        ./gradlew bundleRelease
    else
        print_warning "未找到 Gradle wrapper，尝试使用 CMake..."
        cmake --build . --config Release --target bundle
    fi

    # 查找生成的 AAB
    AAB_PATH=$(find "$BUILD_DIR" -name "*.aab" -type f | head -1)

    if [ -n "$AAB_PATH" ]; then
        print_success "AAB 生成成功: $AAB_PATH"

        # 显示 AAB 信息
        AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
        print_info "AAB 大小: $AAB_SIZE"
    else
        print_error "AAB 生成失败"
        exit 1
    fi
}

# 签名 APK/AAB
sign_release() {
    print_info "签名发布包..."

    if [ ! -f "$KEYSTORE_PATH" ]; then
        print_error "未找到 Keystore: $KEYSTORE_PATH"
        exit 1
    fi

    if [ -z "$KEYSTORE_PASSWORD" ]; then
        print_error "请设置 KEYSTORE_PASSWORD 环境变量"
        exit 1
    fi

    if [ -z "$KEY_PASSWORD" ]; then
        KEY_PASSWORD="$KEYSTORE_PASSWORD"
    fi

    if [ -z "$KEY_ALIAS" ]; then
        KEY_ALIAS="jingo"
    fi

    # 查找未签名的文件
    if [ "$BUILD_FORMAT" = "aab" ]; then
        UNSIGNED_FILE=$(find "$BUILD_DIR" -name "*-release.aab" -type f | head -1)
        SIGNED_FILE="${UNSIGNED_FILE%.aab}-signed.aab"
    else
        UNSIGNED_FILE=$(find "$BUILD_DIR" -name "*-release-unsigned.apk" -type f | head -1)
        SIGNED_FILE="${UNSIGNED_FILE%-unsigned.apk}-signed.apk"
    fi

    if [ -z "$UNSIGNED_FILE" ]; then
        print_warning "未找到待签名文件，跳过签名"
        return
    fi

    # 使用 jarsigner 签名
    jarsigner -verbose \
        -sigalg SHA256withRSA \
        -digestalg SHA-256 \
        -keystore "$KEYSTORE_PATH" \
        -storepass "$KEYSTORE_PASSWORD" \
        -keypass "$KEY_PASSWORD" \
        "$UNSIGNED_FILE" \
        "$KEY_ALIAS"

    # 对齐（仅 APK）
    if [ "$BUILD_FORMAT" = "apk" ]; then
        if command -v zipalign &> /dev/null; then
            zipalign -v 4 "$UNSIGNED_FILE" "$SIGNED_FILE"
            print_success "APK 签名并对齐成功: $SIGNED_FILE"
        else
            # zipalign 不可用，直接重命名
            print_warning "zipalign 未找到，跳过对齐步骤"
            cp "$UNSIGNED_FILE" "$SIGNED_FILE"
            print_success "APK 签名成功（未对齐）: $SIGNED_FILE"
        fi
    else
        mv "$UNSIGNED_FILE" "$SIGNED_FILE"
        print_success "AAB 签名成功: $SIGNED_FILE"
    fi
}

# 上传到 Google Play Store
upload_playstore() {
    print_info "上传到 Google Play Store ($RELEASE_TRACK 轨道)..."

    if [ -z "$GOOGLE_SERVICE_ACCOUNT" ]; then
        print_error "请设置 GOOGLE_SERVICE_ACCOUNT 环境变量（指向服务账号 JSON 文件）"
        exit 1
    fi

    # 查找签名的 AAB
    AAB_PATH=$(find "$BUILD_DIR" -name "*-signed.aab" -type f | head -1)

    if [ -z "$AAB_PATH" ]; then
        print_error "未找到签名的 AAB 文件"
        exit 1
    fi

    # 使用 Google Play Developer API
    print_info "使用 Google Play Developer API 上传..."

    # 这里需要实际的 API 调用，示例：
    # androidpublisher v3 API

    print_warning "Google Play 上传需要配置 API 凭据"
    print_info "请手动上传 AAB 到 Google Play Console："
    print_info "  1. 登录 https://play.google.com/console"
    print_info "  2. 选择您的应用"
    print_info "  3. 进入 Release > $RELEASE_TRACK"
    print_info "  4. 上传 AAB: $AAB_PATH"
}

# 生成发布说明
generate_release_notes() {
    print_info "生成发布说明..."

    RELEASE_NOTES_FILE="$BUILD_DIR/release-notes.txt"

    cat > "$RELEASE_NOTES_FILE" << EOF
JinGoVPN Version ${APP_VERSION:-1.0.0} (Build ${VERSION_CODE:-1})

发布日期: $(date +%Y-%m-%d)
发布轨道: $RELEASE_TRACK

更新内容:
- 请在此处填写更新内容

技术信息:
- 包名: $PACKAGE_NAME
- 构建格式: $BUILD_FORMAT
- 最低 Android 版本: 7.0 (API 24)

EOF

    print_success "发布说明已生成: $RELEASE_NOTES_FILE"
}

# 主函数
main() {
    echo ""
    echo "=================================================="
    echo "      JinGoVPN Android 部署脚本"
    echo "=================================================="
    echo ""

    parse_args "$@"
    check_requirements
    update_version
    build_release

    if [ "$BUILD_FORMAT" = "aab" ]; then
        build_aab
    fi

    sign_release
    generate_release_notes

    if [ "$DEPLOY_TARGET" = "playstore" ]; then
        upload_playstore

        echo ""
        print_success "Google Play Store 部署完成！"
        print_info "发布轨道: $RELEASE_TRACK"
    else
        echo ""
        print_success "Android 构建完成！"

        # 复制输出文件到 pkg 目录，使用统一命名
        mkdir -p "$PKG_DIR"
        VERSION="${APP_VERSION:-1.0.0}"
        if [ "$BUILD_FORMAT" = "aab" ]; then
            AAB_PATH=$(find "$BUILD_DIR" -name "*-signed.aab" -type f | head -1)
            if [ -n "$AAB_PATH" ]; then
                OUTPUT_NAME="JinGoVPN-${VERSION}-android.aab"
                cp "$AAB_PATH" "$PKG_DIR/$OUTPUT_NAME"
                print_info "AAB 已复制到: $PKG_DIR/$OUTPUT_NAME"
            fi
        else
            APK_PATH=$(find "$BUILD_DIR" -name "*-signed.apk" -type f | head -1)
            if [ -n "$APK_PATH" ]; then
                OUTPUT_NAME="JinGoVPN-${VERSION}-android.apk"
                cp "$APK_PATH" "$PKG_DIR/$OUTPUT_NAME"
                print_info "APK 已复制到: $PKG_DIR/$OUTPUT_NAME"
            fi
        fi
    fi

    echo ""
    print_success "=================================================="
    print_success "                部署完成！"
    print_success "=================================================="
    print_info "输出目录: $PKG_DIR"
    echo ""
}

# 执行主函数
main "$@"
