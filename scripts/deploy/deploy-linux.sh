#!/bin/bash
# ============================================================================
# JinGoVPN - Linux Deployment Script
# ============================================================================
# 用途：将 Linux 应用部署为 DEB/RPM/TGZ/AppImage 安装包
# 用法：
#   ./deploy-linux.sh [options]
#
# 选项：
#   -d, --deb            创建 DEB 包（Debian/Ubuntu）
#   -r, --rpm            创建 RPM 包（Fedora/RHEL）
#   -t, --tgz            创建 TGZ 压缩包
#   -a, --appimage       创建 AppImage 包
#   --all                创建所有格式
#   -v, --version VER    设置版本号
#   --skip-build         跳过构建步骤
#   --deploy-deps        部署 Qt 依赖
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
BUILD_DIR="$PROJECT_ROOT/build-linux"
PKG_DIR="$PROJECT_ROOT/pkg"
APP_VERSION=""
SKIP_BUILD=false
DEPLOY_DEPS=true
CREATE_DEB=false
CREATE_RPM=false
CREATE_TGZ=false
CREATE_APPIMAGE=false
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
JinGoVPN Linux 部署脚本

用法: $0 [选项]

选项:
    -d, --deb            创建 DEB 包（Debian/Ubuntu）
    -r, --rpm            创建 RPM 包（Fedora/RHEL）
    -t, --tgz            创建 TGZ 压缩包
    -a, --appimage       创建 AppImage 包
    --all                创建所有支持的格式
    -v, --version VER    设置版本号 (例如: 1.0.0)
    --skip-build         跳过构建步骤（使用现有构建）
    --deploy-deps        部署 Qt 依赖到 bin 目录
    -h, --help           显示帮助信息

环境变量:
    Qt6_DIR              Qt 6 安装路径（例如: /opt/Qt/6.8.0/gcc_64）

示例:
    # 创建 DEB 包
    $0 --deb --version 1.0.0

    # 创建所有格式的安装包
    $0 --all --version 1.0.0

    # 仅部署依赖（不打包）
    $0 --deploy-deps --skip-build

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--deb)
                CREATE_DEB=true
                shift
                ;;
            -r|--rpm)
                CREATE_RPM=true
                shift
                ;;
            -t|--tgz)
                CREATE_TGZ=true
                shift
                ;;
            -a|--appimage)
                CREATE_APPIMAGE=true
                shift
                ;;
            --all)
                CREATE_DEB=true
                CREATE_RPM=true
                CREATE_TGZ=true
                CREATE_APPIMAGE=true
                shift
                ;;
            -v|--version)
                APP_VERSION="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --deploy-deps)
                DEPLOY_DEPS=true
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

    # 检查是否至少选择了一种打包格式
    if [ "$CREATE_DEB" = false ] && [ "$CREATE_RPM" = false ] && \
       [ "$CREATE_TGZ" = false ] && [ "$CREATE_APPIMAGE" = false ] && \
       [ "$DEPLOY_DEPS" = false ]; then
        print_error "请指定至少一种部署目标"
        show_help
        exit 1
    fi
}

# 检查必要工具
check_requirements() {
    print_info "检查部署环境..."

    # 检查 Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "此脚本只能在 Linux 上运行"
        exit 1
    fi

    # 检查 CMake
    if ! command -v cmake &> /dev/null; then
        print_error "CMake 未安装"
        exit 1
    fi
    print_success "CMake: $(cmake --version | head -n1)"

    # 检查打包工具
    if [ "$CREATE_DEB" = true ]; then
        if ! command -v dpkg-deb &> /dev/null; then
            print_warning "dpkg-deb 未安装，无法创建 DEB 包"
            CREATE_DEB=false
        else
            print_success "dpkg-deb 可用"
        fi
    fi

    if [ "$CREATE_RPM" = true ]; then
        if ! command -v rpmbuild &> /dev/null; then
            print_warning "rpmbuild 未安装，无法创建 RPM 包"
            CREATE_RPM=false
        else
            print_success "rpmbuild 可用"
        fi
    fi

    if [ "$CREATE_APPIMAGE" = true ]; then
        if ! command -v appimagetool &> /dev/null && ! command -v linuxdeploy &> /dev/null; then
            print_warning "appimagetool/linuxdeploy 未安装，无法创建 AppImage"
            CREATE_APPIMAGE=false
        else
            print_success "AppImage 工具可用"
        fi
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
        else
            APP_VERSION="1.0.0"
            print_warning "未找到版本号，使用默认: $APP_VERSION"
        fi
    fi
}

# 构建 Release 版本
build_release() {
    if [ "$SKIP_BUILD" = true ]; then
        print_info "跳过构建步骤"
        return
    fi

    print_info "开始构建 Release 版本..."

    # 调用构建脚本
    BUILD_SCRIPT="$SCRIPT_DIR/../build/build-linux.sh"
    if [ -f "$BUILD_SCRIPT" ]; then
        bash "$BUILD_SCRIPT" --release --clean
    else
        print_error "未找到构建脚本: $BUILD_SCRIPT"
        exit 1
    fi

    print_success "构建完成"
}

# 部署 Qt 依赖
deploy_dependencies() {
    if [ "$DEPLOY_DEPS" = false ]; then
        return
    fi

    print_info "部署 Qt 依赖库和插件..."

    BIN_DIR="$BUILD_DIR/bin"
    LIB_DIR="$BIN_DIR/lib"
    PLUGINS_DIR="$BIN_DIR/plugins"

    if [ ! -f "$BIN_DIR/$APP_NAME" ]; then
        print_error "未找到可执行文件: $BIN_DIR/$APP_NAME"
        exit 1
    fi

    # 创建 lib 目录
    mkdir -p "$LIB_DIR"

    # 拷贝 Qt 库
    print_info "拷贝 Qt 依赖库..."
    ldd "$BIN_DIR/$APP_NAME" | grep "Qt6" | awk '{print $3}' | while read -r lib; do
        if [ -f "$lib" ]; then
            cp -v "$lib" "$LIB_DIR/"
            # 也拷贝符号链接
            lib_name=$(basename "$lib")
            lib_base=$(echo "$lib_name" | sed 's/\.so\..*/\.so/')
            if [ "$lib_base" != "$lib_name" ]; then
                ln -sf "$lib_name" "$LIB_DIR/$lib_base"
            fi
        fi
    done

    # 拷贝 Qt 插件
    if [ -n "$Qt6_DIR" ] && [ -d "$Qt6_DIR/plugins" ]; then
        print_info "拷贝 Qt 插件..."
        mkdir -p "$PLUGINS_DIR/platforms"
        mkdir -p "$PLUGINS_DIR/imageformats"
        mkdir -p "$PLUGINS_DIR/iconengines"
        mkdir -p "$PLUGINS_DIR/platformthemes"

        cp -v "$Qt6_DIR/plugins/platforms/libqxcb.so" "$PLUGINS_DIR/platforms/" 2>/dev/null || true
        cp -v "$Qt6_DIR/plugins/platforms/libqwayland"*.so "$PLUGINS_DIR/platforms/" 2>/dev/null || true
        cp -v "$Qt6_DIR/plugins/imageformats"/*.so "$PLUGINS_DIR/imageformats/" 2>/dev/null || true
        cp -v "$Qt6_DIR/plugins/iconengines"/*.so "$PLUGINS_DIR/iconengines/" 2>/dev/null || true
        cp -v "$Qt6_DIR/plugins/platformthemes"/*.so "$PLUGINS_DIR/platformthemes/" 2>/dev/null || true
    fi

    # 创建启动脚本
    print_info "创建启动脚本..."
    cat > "$BIN_DIR/jingo" << 'EOF'
#!/bin/bash
# JinGo VPN 启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${SCRIPT_DIR}/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="${SCRIPT_DIR}/plugins/platforms"

exec "${SCRIPT_DIR}/JinGo" "$@"
EOF

    chmod +x "$BIN_DIR/jingo"
    print_success "启动脚本已创建: $BIN_DIR/jingo"

    print_success "依赖部署完成"
}

# 验证应用程序
verify_app() {
    print_info "验证应用程序..."

    BIN_DIR="$BUILD_DIR/bin"
    APP_PATH="$BIN_DIR/$APP_NAME"

    if [ ! -f "$APP_PATH" ]; then
        print_error "未找到可执行文件"
        exit 1
    fi

    # 显示文件大小
    APP_SIZE=$(du -h "$APP_PATH" | cut -f1)
    print_success "可执行文件大小: $APP_SIZE"

    # 显示依赖
    print_info "Qt 依赖库:"
    ldd "$APP_PATH" | grep "Qt6" | awk '{print "  " $1 " => " $3}' || print_warning "未找到 Qt6 依赖"

    # 检查是否部署了依赖
    if [ -d "$BIN_DIR/lib" ]; then
        LIB_COUNT=$(ls -1 "$BIN_DIR/lib" 2>/dev/null | wc -l)
        print_success "已部署 $LIB_COUNT 个依赖库"
    fi

    if [ -d "$BIN_DIR/plugins" ]; then
        PLUGIN_COUNT=$(find "$BIN_DIR/plugins" -name "*.so" 2>/dev/null | wc -l)
        print_success "已部署 $PLUGIN_COUNT 个 Qt 插件"
    fi

    print_success "应用验证完成"
}

# 创建 DEB 包
create_deb_package() {
    if [ "$CREATE_DEB" = false ]; then
        return
    fi

    print_info "创建 DEB 包..."

    cd "$BUILD_DIR"

    # 确保 CMake 配置了打包
    if [ "$SKIP_BUILD" = false ]; then
        cmake -S "$PROJECT_ROOT" -B "$BUILD_DIR" -DENABLE_PACKAGING=ON
    fi

    cpack -G DEB

    DEB_FILE=$(find "$BUILD_DIR" -name "*.deb" -type f | head -n 1)
    if [ -n "$DEB_FILE" ]; then
        DEB_SIZE=$(du -h "$DEB_FILE" | cut -f1)
        print_success "DEB 包创建成功: $(basename $DEB_FILE) ($DEB_SIZE)"
        print_info "DEB 路径: $DEB_FILE"
    else
        print_error "DEB 包创建失败"
    fi
}

# 创建 RPM 包
create_rpm_package() {
    if [ "$CREATE_RPM" = false ]; then
        return
    fi

    print_info "创建 RPM 包..."

    cd "$BUILD_DIR"
    cpack -G RPM

    RPM_FILE=$(find "$BUILD_DIR" -name "*.rpm" -type f | head -n 1)
    if [ -n "$RPM_FILE" ]; then
        RPM_SIZE=$(du -h "$RPM_FILE" | cut -f1)
        print_success "RPM 包创建成功: $(basename $RPM_FILE) ($RPM_SIZE)"
        print_info "RPM 路径: $RPM_FILE"
    else
        print_error "RPM 包创建失败"
    fi
}

# 创建 TGZ 包
create_tgz_package() {
    if [ "$CREATE_TGZ" = false ]; then
        return
    fi

    print_info "创建 TGZ 压缩包..."

    cd "$BUILD_DIR"
    cpack -G TGZ

    TGZ_FILE=$(find "$BUILD_DIR" -name "*.tar.gz" -type f | head -n 1)
    if [ -n "$TGZ_FILE" ]; then
        TGZ_SIZE=$(du -h "$TGZ_FILE" | cut -f1)
        print_success "TGZ 包创建成功: $(basename $TGZ_FILE) ($TGZ_SIZE)"
        print_info "TGZ 路径: $TGZ_FILE"
    else
        print_error "TGZ 包创建失败"
    fi
}

# 创建 AppImage
create_appimage() {
    if [ "$CREATE_APPIMAGE" = false ]; then
        return
    fi

    print_info "创建 AppImage..."

    APPDIR="$BUILD_DIR/AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/lib"
    mkdir -p "$APPDIR/usr/share/applications"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

    # 复制应用程序
    cp -r "$BUILD_DIR/bin"/* "$APPDIR/usr/bin/"

    # 创建 .desktop 文件
    cat > "$APPDIR/usr/share/applications/jingo.desktop" << EOF
[Desktop Entry]
Type=Application
Name=JinGo VPN
Comment=VPN Client
Exec=jingo
Icon=jingo
Categories=Network;
Terminal=false
EOF

    # 复制图标（如果存在）
    if [ -f "$PROJECT_ROOT/resources/app.png" ]; then
        cp "$PROJECT_ROOT/resources/app.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/jingo.png"
        cp "$PROJECT_ROOT/resources/app.png" "$APPDIR/jingo.png"
    fi

    # 创建 AppRun
    cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
APPDIR="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${APPDIR}/usr/bin/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${APPDIR}/usr/bin/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="${APPDIR}/usr/bin/plugins/platforms"
exec "${APPDIR}/usr/bin/jingo" "$@"
EOF
    chmod +x "$APPDIR/AppRun"

    # 使用 appimagetool 或 linuxdeploy 创建 AppImage
    APPIMAGE_NAME="JinGoVPN-${APP_VERSION}-x86_64.AppImage"

    if command -v appimagetool &> /dev/null; then
        appimagetool "$APPDIR" "$BUILD_DIR/$APPIMAGE_NAME"
    elif command -v linuxdeploy &> /dev/null; then
        linuxdeploy --appdir "$APPDIR" --output appimage
        mv *.AppImage "$BUILD_DIR/$APPIMAGE_NAME" 2>/dev/null || true
    else
        print_warning "AppImage 工具未找到，跳过 AppImage 创建"
        return
    fi

    if [ -f "$BUILD_DIR/$APPIMAGE_NAME" ]; then
        APPIMAGE_SIZE=$(du -h "$BUILD_DIR/$APPIMAGE_NAME" | cut -f1)
        print_success "AppImage 创建成功: $APPIMAGE_NAME ($APPIMAGE_SIZE)"
        print_info "AppImage 路径: $BUILD_DIR/$APPIMAGE_NAME"
    else
        print_error "AppImage 创建失败"
    fi
}

# 主函数
main() {
    echo ""
    echo "=================================================="
    echo "      JinGoVPN Linux 部署脚本"
    echo "=================================================="
    echo ""

    parse_args "$@"
    check_requirements
    update_version
    build_release
    deploy_dependencies
    verify_app
    create_deb_package
    create_rpm_package
    create_tgz_package
    create_appimage

    echo ""
    print_success "=================================================="
    print_success "                部署完成！"
    print_success "=================================================="
    echo ""

    # 复制生成的安装包到 pkg 目录
    mkdir -p "$PKG_DIR"
    print_info "复制安装包到 $PKG_DIR ..."
    find "$BUILD_DIR" -maxdepth 1 \( -name "*.deb" -o -name "*.rpm" -o -name "*.tar.gz" -o -name "*.AppImage" \) -type f -exec cp {} "$PKG_DIR/" \;

    # 显示生成的安装包
    print_info "生成的安装包:"
    find "$PKG_DIR" -maxdepth 1 \( -name "*.deb" -o -name "*.rpm" -o -name "*.tar.gz" -o -name "*.AppImage" \) -type f | sed 's/^/  /'

    echo ""
    print_info "下一步:"
    echo "  1. 测试安装包:"
    if [ "$CREATE_DEB" = true ]; then
        echo "     sudo dpkg -i $PKG_DIR/*.deb"
    fi
    if [ "$CREATE_RPM" = true ]; then
        echo "     sudo rpm -i $PKG_DIR/*.rpm"
    fi
    echo ""
    echo "  2. 或直接运行应用:"
    echo "     $BUILD_DIR/bin/jingo"
    echo ""
    print_info "输出目录: $PKG_DIR"
}

# 执行主函数
main "$@"
