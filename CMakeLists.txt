# ============================================================================
# CMakeLists.txt - JinGo项目主配置文件
# ============================================================================

cmake_minimum_required(VERSION 3.21)

# ============================================================================
# 第一部分: 策略和全局设置
# ============================================================================
include(cmake/Policies.cmake)
include(cmake/Settings.cmake)

# ============================================================================
# 第二部分: 平台检测和工具链配置 (必须在project()之前)
# ============================================================================
if(ANDROID)
    include(cmake/Platform-Android.cmake)
endif()

# ============================================================================
# 第三部分: 项目定义
# ============================================================================
project(JinGo
        VERSION 1.0.0
        DESCRIPTION "Cross-platform Xray VPN Client - JinGo"
        LANGUAGES C CXX
)

# Enable Objective-C++ only for Apple platforms (but not for Android cross-compile)
if(APPLE AND NOT ANDROID)
    enable_language(OBJCXX)
endif()

# ============================================================================
# 第四部分: 目标平台检测(用于简化后续条件判断)
# ============================================================================
# 定义明确的目标平台变量,避免混淆主机平台和目标平台
set(TARGET_MACOS OFF)
set(TARGET_IOS OFF)
set(TARGET_ANDROID OFF)
set(TARGET_WINDOWS OFF)
set(TARGET_LINUX OFF)

if(ANDROID)
    set(TARGET_ANDROID ON)
    message(STATUS "✓ Target platform: Android (${ANDROID_ABI})")
elseif(IOS)
    set(TARGET_IOS ON)
    message(STATUS "✓ Target platform: iOS")
elseif(APPLE)
    set(TARGET_MACOS ON)
    message(STATUS "✓ Target platform: macOS")
elseif(WIN32)
    set(TARGET_WINDOWS ON)
    message(STATUS "✓ Target platform: Windows")
elseif(UNIX)
    set(TARGET_LINUX ON)
    message(STATUS "✓ Target platform: Linux")
endif()

# ============================================================================
# 第四.五部分: 应用标识配置 (Bundle ID)
# ============================================================================
# APP_BUNDLE_ID 可以通过 cmake -DAPP_BUNDLE_ID=xxx 传入
# 默认值为 work.opine.jingo
# 白标构建时会设置为对应品牌的 Bundle ID
if(NOT APP_BUNDLE_ID)
    set(APP_BUNDLE_ID "work.opine.jingo" CACHE STRING "Application Bundle Identifier")
endif()
message(STATUS "✓ App Bundle ID: ${APP_BUNDLE_ID}")

# Extension Bundle IDs (derived from main app Bundle ID)
set(PACKET_TUNNEL_BUNDLE_ID "${APP_BUNDLE_ID}.PacketTunnelProvider")
message(STATUS "  PacketTunnel Bundle ID: ${PACKET_TUNNEL_BUNDLE_ID}")

# ============================================================================
# 第四.六部分: Provisioning Profile 配置 (iOS 手动签名)
# ============================================================================
# 签名身份配置
# 本地开发用 "Apple Development"，CI 发布用 "Apple Distribution"
# ============================================================================
if(NOT APPLE_CODE_SIGN_IDENTITY)
    set(APPLE_CODE_SIGN_IDENTITY "Apple Development" CACHE STRING "Code signing identity")
endif()
message(STATUS "✓ Code Sign Identity: ${APPLE_CODE_SIGN_IDENTITY}")

# 开发团队 ID (从证书中提取)
if(NOT APPLE_DEVELOPMENT_TEAM)
    set(APPLE_DEVELOPMENT_TEAM "****" CACHE STRING "Apple Development Team ID")
endif()
message(STATUS "✓ Development Team: ${APPLE_DEVELOPMENT_TEAM}")

# CI 环境 Keychain 路径 (用于 Xcode 签名)
# 可通过 cmake -DBUILD_KEYCHAIN_PATH=/path/to/keychain.keychain-db 传入
if(BUILD_KEYCHAIN_PATH)
    message(STATUS "✓ Build Keychain: ${BUILD_KEYCHAIN_PATH}")
endif()

# ============================================================================
# 可以通过 cmake -DIOS_PROFILE_MAIN=xxx 等参数传入
# 默认值为开发环境使用的 Profile 名称
if(NOT IOS_PROFILE_MAIN)
    set(IOS_PROFILE_MAIN "JinGo Accelerator iOS" CACHE STRING "iOS Main App Provisioning Profile")
endif()
if(NOT IOS_PROFILE_PACKET_TUNNEL)
    set(IOS_PROFILE_PACKET_TUNNEL "JinGo PacketTunnel iOS" CACHE STRING "iOS PacketTunnel Provisioning Profile")
endif()
message(STATUS "✓ iOS Provisioning Profiles:")
message(STATUS "  Main App: ${IOS_PROFILE_MAIN}")
message(STATUS "  PacketTunnel: ${IOS_PROFILE_PACKET_TUNNEL}")

# ============================================================================
# 第四.七部分: Provisioning Profile 配置 (macOS 手动签名)
# ============================================================================
# 可以通过 cmake -DMACOS_PROFILE_MAIN=xxx 等参数传入
if(NOT MACOS_PROFILE_MAIN)
    set(MACOS_PROFILE_MAIN "JinGo_Accelerator_macOS" CACHE STRING "macOS Main App Provisioning Profile")
endif()
if(NOT MACOS_PROFILE_PACKET_TUNNEL)
    set(MACOS_PROFILE_PACKET_TUNNEL "JinGo_PacketTunnel_macOS" CACHE STRING "macOS PacketTunnel Provisioning Profile")
endif()
message(STATUS "✓ macOS Provisioning Profiles:")
message(STATUS "  Main App: ${MACOS_PROFILE_MAIN}")
message(STATUS "  PacketTunnel: ${MACOS_PROFILE_PACKET_TUNNEL}")

# ============================================================================
# 第五部分: 依赖项配置
# ============================================================================

# Workaround for Qt 6.8+ adding -no_warn_duplicate_libraries which Xcode clang doesn't understand
# Qt checks QT_NO_DISABLE_WARN_DUPLICATE_LIBRARIES target property
set(QT_NO_DISABLE_WARN_DUPLICATE_LIBRARIES ON)

include(cmake/Dependencies-Qt.cmake)
include(cmake/Dependencies-Xray.cmake)

# ============================================================================
# 第五.四部分: JinDoCore 静态库配置
# ============================================================================
# 使用 JinDoCore 静态库代替编译源码，提供代码保护
option(USE_JINDO_LIB "Use JinDoCore static library instead of source code" ON)

if(USE_JINDO_LIB)
    # JinDoCore 库路径配置
    set(JINDO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../JinDo" CACHE PATH "Path to JinDo project")

    # 根据平台选择库路径
    if(TARGET_ANDROID)
        set(JINDO_LIB_DIR "${JINDO_ROOT}/lib/android/${CMAKE_ANDROID_ARCH_ABI}")
        set(JINDO_INCLUDE_DIR "${JINDO_ROOT}/lib/android/include")
        set(JINDO_LIB_FILE "${JINDO_LIB_DIR}/libJinDoCore.a")
    elseif(TARGET_IOS OR TARGET_MACOS)
        set(JINDO_XCFRAMEWORK "${JINDO_ROOT}/lib/apple/JinDoCore.xcframework")
        if(TARGET_IOS)
            if(CMAKE_OSX_SYSROOT MATCHES "iphonesimulator")
                set(JINDO_LIB_DIR "${JINDO_XCFRAMEWORK}/ios-arm64_x86_64-simulator")
            else()
                set(JINDO_LIB_DIR "${JINDO_XCFRAMEWORK}/ios-arm64")
            endif()
        else()
            set(JINDO_LIB_DIR "${JINDO_XCFRAMEWORK}/macos-arm64_x86_64")
        endif()
        set(JINDO_INCLUDE_DIR "${JINDO_LIB_DIR}/Headers")
        set(JINDO_LIB_FILE "${JINDO_LIB_DIR}/libJinDoCore.a")
    elseif(TARGET_WINDOWS)
        # Windows MinGW uses libJinDoCore.a from third_party/jindo/windows/mingw64
        set(JINDO_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/jindo/windows/mingw64")
        set(JINDO_INCLUDE_DIR "${JINDO_LIB_DIR}/include")
        set(JINDO_LIB_FILE "${JINDO_LIB_DIR}/libJinDoCore.a")
    elseif(TARGET_LINUX)
        # Linux uses libJinDoCore.a from third_party/jindo/linux/x64
        set(JINDO_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/jindo/linux/x64")
        set(JINDO_INCLUDE_DIR "${JINDO_LIB_DIR}/include")
        set(JINDO_LIB_FILE "${JINDO_LIB_DIR}/libJinDoCore.a")
    endif()

    # 检查库文件是否存在
    if(EXISTS "${JINDO_LIB_FILE}")
        message(STATUS "✓ JinDoCore library: ${JINDO_LIB_FILE}")
        message(STATUS "✓ JinDoCore headers: ${JINDO_INCLUDE_DIR}")

        # 创建导入的静态库目标
        add_library(JinDoCore STATIC IMPORTED)
        set_target_properties(JinDoCore PROPERTIES
            IMPORTED_LOCATION "${JINDO_LIB_FILE}"
        )
    else()
        message(WARNING "JinDoCore library not found: ${JINDO_LIB_FILE}")
        message(WARNING "Falling back to source code compilation")
        set(USE_JINDO_LIB OFF)
    endif()
endif()

# ============================================================================
# 第五.五部分: 平台特定配置 (在源文件配置之前)
# ============================================================================
# 这些配置定义PLATFORM_SOURCES变量,必须在PROJECT_SOURCES之前include

if(TARGET_ANDROID)
    include(cmake/Platform-Android.cmake)
elseif(TARGET_IOS)
    include(cmake/Platform-iOS.cmake)
elseif(TARGET_MACOS)
    include(cmake/Platform-macOS.cmake)
elseif(TARGET_WINDOWS)
    include(cmake/Platform-Windows.cmake)
elseif(TARGET_LINUX)
    include(cmake/Platform-Linux.cmake)
endif()

# ============================================================================
# 第六部分: 源文件配置
# ============================================================================

# 当使用 JinDoCore 静态库时，跳过源码编译
if(USE_JINDO_LIB)
    message(STATUS "Using JinDoCore static library - skipping source compilation")

    # 只需要空的源文件列表（所有代码都在 JinDoCore 库中）
    set(CORE_SOURCES "")
    set(NETWORK_SOURCES "")
    set(STORAGE_SOURCES "")
    set(MODEL_SOURCES "")
    set(VIEWMODEL_SOURCES "")
    set(UTIL_SOURCES "")
    set(UI_SOURCES "")
    set(PLATFORM_SOURCES "")

    # Windows 平台需要额外的桥接文件
    if(TARGET_WINDOWS)
        set(PLATFORM_SOURCES
            src/platform/windows/WinTunDriverInstaller.cpp
            src/utils/RsaCrypto_windows.cpp
        )
        message(STATUS "✓ Added Windows bridge files for JinDoCore")
    endif()

    # Linux 平台需要额外的桥接文件
    # 注意：这些文件需要从 JinDo 项目中提供
    if(TARGET_LINUX)
        set(LINUX_BRIDGE_FILES
            src/platform/PlatformInterface.cpp
            src/platform/LinuxPlatform.cpp
            src/platform/linux/LinuxTunManager.cpp
        )

        # 检查文件是否存在
        set(PLATFORM_SOURCES "")
        set(MISSING_FILES "")
        foreach(src_file ${LINUX_BRIDGE_FILES})
            if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${src_file}")
                list(APPEND PLATFORM_SOURCES ${src_file})
            else()
                list(APPEND MISSING_FILES ${src_file})
            endif()
        endforeach()

        if(MISSING_FILES)
            message(WARNING "Linux bridge files missing:")
            foreach(missing_file ${MISSING_FILES})
                message(WARNING "  - ${missing_file}")
            endforeach()
            message(WARNING "These files need to be copied from the JinDo project")
            message(WARNING "Without these files, the build will fail at linking stage")
        else()
            message(STATUS "✓ Added Linux bridge files for JinDoCore")
        endif()
    endif()

    # 平台资源（图标等）仍然需要
    if(TARGET_MACOS)
        set(MACOS_ICON_FILE "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.icns")
        set(PLATFORM_RESOURCES ${MACOS_ICON_FILE})
        set_source_files_properties(${MACOS_ICON_FILE} PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources"
        )
    elseif(TARGET_IOS)
        set(PLATFORM_RESOURCES "")
    endif()

# 否则使用源码编译
else()

# Core sources - Platform-specific bridge implementations
if(TARGET_ANDROID)
    # Android: Direct C bridge to SuperRay shared library
    set(CORE_SOURCES
            src/core/XrayCBridge_Android.cpp
            src/core/VPNCore.cpp
            src/core/VPNManager.cpp
            src/core/VPNManager_Android.cpp
            src/core/ConfigManager.cpp
            src/core/Logger.cpp
            src/core/BackgroundDataUpdater.cpp
    )
    add_compile_definitions(ANDROID_XRAY_BRIDGE)
    message(STATUS "Using XrayCBridge_Android.cpp (SuperRay C API)")

elseif(TARGET_MACOS OR TARGET_IOS)
    # Apple: Objective-C++ bridge to SuperRay framework
    set(CORE_SOURCES
            src/core/XrayCBridge_Apple.mm
            src/core/VPNCore.cpp
            src/core/VPNManager.cpp
            src/core/VPNManager_Apple.cpp
            src/platform/apple/VPNManagerHelper.mm
            src/platform/apple/NetworkExtensionManager.mm
            src/platform/apple/XrayManager.mm
            src/platform/apple/SystemProxyManager.mm
            src/platform/apple/SystemExtensionManager.mm
            src/core/ConfigManager.cpp
            src/core/Logger.cpp
            src/core/BackgroundDataUpdater.cpp
    )
    # macOS 管理员模式 TUN（不使用 Network Extension）
    if(TARGET_MACOS)
        list(APPEND CORE_SOURCES src/platform/apple/MacOSTunManager.mm)
        message(STATUS "✓ macOS: Using admin mode TUN (MacOSTunManager)")
    endif()
    add_compile_definitions(APPLE_XRAY_BRIDGE)
    message(STATUS "Using XrayCBridge_Apple.mm (Objective-C++ bridge)")

    # 平台资源
    if(TARGET_IOS)
        set(PLATFORM_RESOURCES "")
    else()
        # macOS: 设置应用图标
        set(MACOS_ICON_FILE "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.icns")
        set(PLATFORM_RESOURCES ${MACOS_ICON_FILE})
        set_source_files_properties(${MACOS_ICON_FILE} PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources"
        )
    endif()

elseif(TARGET_WINDOWS)
    # Windows: C bridge to SuperRay DLL
    # Architecture: WinTun → SuperRay TUN → Xray → Server

    # Check if XrayCBridge_CGo.c exists for Windows
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/core/XrayCBridge_CGo.c")
        set(CORE_SOURCES
                src/core/XrayCBridge_CGo.c
                src/core/VPNCore.cpp
                src/core/VPNManager.cpp
                src/core/VPNManager_Win.cpp
                src/core/ConfigManager.cpp
                src/core/Logger.cpp
                src/core/BackgroundDataUpdater.cpp
        )
        message(STATUS "Using XrayCBridge_CGo.c (CGo bridge for Windows)")
    else()
        # Fallback: compile without bridge
        set(CORE_SOURCES
                src/core/VPNCore.cpp
                src/core/VPNManager.cpp
                src/core/VPNManager_Win.cpp
                src/core/ConfigManager.cpp
                src/core/Logger.cpp
                src/core/BackgroundDataUpdater.cpp
        )
        add_compile_definitions(NO_SUPERRAY)
        message(STATUS "Compiling without XrayCBridge (stub mode)")
    endif()

elseif(UNIX)
    # Linux: C bridge to SuperRay library
    # Note: Linux uses SuperRay TUN for TUN management

    # Check if XrayCBridge_CGo.c exists for Linux
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/core/XrayCBridge_CGo.c")
        set(CORE_SOURCES
                src/core/XrayCBridge_CGo.c
                src/core/VPNCore.cpp
                src/core/VPNManager.cpp
                src/core/VPNManager_Linux.cpp
                src/core/ConfigManager.cpp
                src/core/Logger.cpp
                src/core/BackgroundDataUpdater.cpp
        )
        add_compile_definitions(HAVE_SUPERRAY)
        message(STATUS "Using XrayCBridge_CGo.c (CGo bridge for Linux)")
    else()
        # Fallback: compile without bridge
        set(CORE_SOURCES
                src/core/VPNCore.cpp
                src/core/VPNManager.cpp
                src/core/VPNManager_Linux.cpp
                src/core/ConfigManager.cpp
                src/core/Logger.cpp
                src/core/BackgroundDataUpdater.cpp
        )
        add_compile_definitions(NO_SUPERRAY)
        message(STATUS "Compiling without XrayCBridge (stub mode)")
    endif()

else()
    # Unknown platform
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

set(NETWORK_SOURCES
        src/network/ApiClient.cpp
        src/network/SubscriptionManager.cpp
        src/network/AuthManager.cpp
        src/network/OrderManager.cpp
        src/network/PaymentManager.cpp
        src/network/TicketManager.cpp
        src/network/SystemConfigManager.cpp
)

set(STORAGE_SOURCES
        src/storage/DatabaseManager.cpp
        src/storage/SecureStorage.cpp
        src/storage/CacheManager.cpp
)

set(MODEL_SOURCES
        src/models/User.cpp
        src/models/Server.cpp
        src/models/Subscription.cpp
        src/models/SubscriptionListModel.cpp
        src/models/ConnectionStatus.cpp
        src/models/Plan.cpp
)

set(VIEWMODEL_SOURCES
        src/viewmodels/LoginViewModel.cpp
        src/viewmodels/RegisterViewModel.cpp
        src/viewmodels/ServerListViewModel.cpp
        src/viewmodels/ConnectionViewModel.cpp
        src/viewmodels/SettingsViewModel.cpp
)

set(UTIL_SOURCES
        src/utils/FormatUtils.cpp
        src/utils/Crypto.cpp
        src/utils/NetworkUtils.cpp
        src/utils/FileUtils.cpp
        src/utils/ClipboardHelper.cpp
        src/utils/CountryUtils.cpp
        src/utils/XrayDebugger.cpp
        src/utils/LanguageManager.cpp
        src/utils/TcpPing.cpp
        src/utils/IcmpPing.cpp
        src/utils/ProxyDetector.cpp
        src/utils/LogManager.cpp
        src/utils/RsaCrypto.cpp
        src/utils/AesCrypto.cpp
        src/utils/DeviceIdentifier.cpp
        src/core/BundleConfig.cpp
        src/core/LicenseManager.cpp
)

# 平台特定实现文件 (.cpp/.mm) - 必须在 AVAILABLE_SOURCES 中被排除以避免重复编译
# Windows, Linux, Android, IOSPlatform.cpp, AndroidVpnHelper.cpp, MacOSPlatform.mm, IOSPlatformHelper.mm
# 它们会通过 PLATFORM_SOURCES 变量添加到 PROJECT_SOURCES 中。
if(NOT ANDROID AND NOT IOS)
    set(UI_SOURCES src/ui/SystemTrayManager.cpp)
else()
    set(UI_SOURCES "")
    message(STATUS "Excluding SystemTrayManager for mobile platform")
endif()

endif() # 结束 USE_JINDO_LIB else 块

# 包含所有 C++ 实现文件的合并列表 (不含平台特定实现文件,因为它们在 PLATFORM_SOURCES 中)
set(ALL_SOURCES
        ${CORE_SOURCES}
        ${NETWORK_SOURCES}
        ${STORAGE_SOURCES}
        ${MODEL_SOURCES}
        ${VIEWMODEL_SOURCES}
        ${UTIL_SOURCES}
        ${UI_SOURCES}
)

set(AVAILABLE_SOURCES)
message(STATUS "Verifying source files:")
foreach(source ${ALL_SOURCES})
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${source})
        list(APPEND AVAILABLE_SOURCES ${source})
        message(STATUS "  ✓ ${source}")
    else()
        message(WARNING "源文件不存在,将跳过: ${source}")
    endif()
endforeach()

# 最终可执行文件的源文件列表 (Main + 通用实现 + 平台特定实现)
set(PROJECT_SOURCES
        src/main.cpp
        ${AVAILABLE_SOURCES}
        ${PLATFORM_SOURCES}
)

# ============================================================================
# 第七部分: GeoIP数据文件配置
# ============================================================================

set(GEOIP_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources/geoip")
set(GEOIP_DAT_FILE "${GEOIP_SOURCE_DIR}/geoip.dat")
set(GEOSITE_DAT_FILE "${GEOIP_SOURCE_DIR}/geosite.dat")

# 检查文件是否存在
if(EXISTS ${GEOIP_DAT_FILE})
    message(STATUS "✓ Found geoip.dat: ${GEOIP_DAT_FILE}")
else()
    message(WARNING "geoip.dat not found at: ${GEOIP_DAT_FILE}")
endif()

if(EXISTS ${GEOSITE_DAT_FILE})
    message(STATUS "✓ Found geosite.dat: ${GEOSITE_DAT_FILE}")
else()
    message(WARNING "geosite.dat not found at: ${GEOSITE_DAT_FILE}")
endif()

# ============================================================================
# 第八部分: 翻译文件配置
# ============================================================================

set(TS_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_zh_CN.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_zh_TW.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_en_US.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_fa_IR.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_ru_RU.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_vi_VN.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_km_KH.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/jingo_my_MM.ts
)

# ============================================================================
# 第九部分: QML和资源文件
# ============================================================================

file(GLOB_RECURSE QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/*.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/themes/*.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/pages/*.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/components/*.qml
)

set(AVAILABLE_QML_FILES)
set(QML_FILES_WITH_ALIAS)
foreach(qml_file ${QML_FILES})
    if(EXISTS ${qml_file})
        # 计算相对于resources目录的路径作为别名，这样QML路径将是 qml/main.qml 而不是 resources/qml/main.qml
        file(RELATIVE_PATH file_alias ${CMAKE_CURRENT_SOURCE_DIR}/resources ${qml_file})

        # 关键修复：components目录的QML文件需要映射到JinGo模块路径
        # 因为qmldir声明了 "module JinGo"，Qt期望所有组件在 qml/JinGo/ 下
        string(REPLACE "qml/components/" "qml/JinGo/" file_alias "${file_alias}")

        # 保存文件的绝对路径
        list(APPEND AVAILABLE_QML_FILES ${qml_file})
        # 设置别名属性（在qt_add_qml_module中使用）
        set_source_files_properties(${qml_file} PROPERTIES
            QT_RESOURCE_ALIAS ${file_alias}
        )
    else()
        message(WARNING "QML 文件不存在,将跳过: ${qml_file}")
    endif()
endforeach()

set(RESOURCE_FILES resources/resources.qrc)
foreach(res_file ${RESOURCE_FILES})
    if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${res_file})
        message(WARNING "资源文件不存在,将跳过: ${res_file}")
        list(REMOVE_ITEM RESOURCE_FILES ${res_file})
    endif()
endforeach()

# ============================================================================
# 第十部分: 创建可执行文件
# ============================================================================

if(TARGET_ANDROID)
    qt_add_executable(JinGo MANUAL_FINALIZATION ${PROJECT_SOURCES})
elseif(TARGET_MACOS OR TARGET_IOS)
    qt_add_executable(JinGo MACOSX_BUNDLE ${PROJECT_SOURCES} ${PLATFORM_RESOURCES})

    # 根据平台选择Info.plist
    if(TARGET_IOS)
        set(INFO_PLIST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/platform/ios/Info.plist)
        # iOS Asset Catalog 路径
        set(IOS_ASSET_CATALOG "${CMAKE_CURRENT_SOURCE_DIR}/platform/ios/Assets.xcassets")
    else()
        set(INFO_PLIST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/platform/macos/Info.plist)
    endif()

    # 基本Bundle属性
    set_target_properties(JinGo PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST ${INFO_PLIST_PATH}
            MACOSX_BUNDLE_BUNDLE_NAME "JinGoVPN"
            MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
            MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
            MACOSX_BUNDLE_GUI_IDENTIFIER "${APP_BUNDLE_ID}"
            # Workaround for Qt 6.8+ adding -no_warn_duplicate_libraries which Xcode clang doesn't understand
            QT_NO_DISABLE_WARN_DUPLICATE_LIBRARIES ON
    )

    # 平台特定资源
    if(TARGET_IOS)
        set_target_properties(JinGo PROPERTIES
            RESOURCE "${IOS_ASSET_CATALOG}"
        )
    else()
        # macOS: 设置资源和图标
        set_target_properties(JinGo PROPERTIES
            RESOURCE "${PLATFORM_RESOURCES}"
            MACOSX_BUNDLE_ICON_FILE "app.icns"
        )
    endif()

    # 代码签名配置
    if(TARGET_IOS)
        # iOS: 设置 Bundle ID 和 Asset Catalog
        set_target_properties(JinGo PROPERTIES
            XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${APP_BUNDLE_ID}"
            XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        )

        # 如果有开发团队 ID，配置签名
        if(APPLE_DEVELOPMENT_TEAM)
            # CI 环境：禁用 Xcode 内置签名，由构建脚本手动签名
            if(BUILD_KEYCHAIN_PATH)
                set_target_properties(JinGo PROPERTIES
                    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
                    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
                    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
                    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${APPLE_DEVELOPMENT_TEAM}"
                )
                message(STATUS "✓ iOS CI mode: Xcode signing disabled, will sign manually")
            else()
                # 本地开发环境：使用 Xcode 内置签名
                set_target_properties(JinGo PROPERTIES
                    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${APPLE_CODE_SIGN_IDENTITY}"
                    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_SOURCE_DIR}/platform/ios/JinGo.entitlements"
                    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${APPLE_DEVELOPMENT_TEAM}"
                    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Manual"
                    XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER "${IOS_PROFILE_MAIN}"
                )
                message(STATUS "✓ iOS code signing configured with team: ${APPLE_DEVELOPMENT_TEAM}")
            endif()
        else()
            set_target_properties(JinGo PROPERTIES
                XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
                XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
            )
            message(STATUS "✓ iOS code signing configured (automatic team selection)")
        endif()

        message(STATUS "✓ iOS entitlements file: ${CMAKE_SOURCE_DIR}/platform/ios/JinGo.entitlements")
    else()
        # macOS 也需要明确设置 PRODUCT_BUNDLE_IDENTIFIER，避免使用 $(PRODUCT_NAME)
        set_target_properties(JinGo PROPERTIES
            XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${APP_BUNDLE_ID}"
        )

        # 检查是否跳过签名（用于开发模式，特别是管理员模式 TUN 不需要 Network Extension）
        if(SKIP_CODE_SIGNING)
            # 跳过签名：使用 ad-hoc 签名，不需要证书
            set_target_properties(JinGo PROPERTIES
                XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
                XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
                XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
            )
            message(STATUS "✓ macOS code signing DISABLED (--skip-sign mode)")
            message(STATUS "  Admin mode TUN does not require signed Network Extension")
        elseif(APPLE_DEVELOPMENT_TEAM)
            # CI 环境：禁用 Xcode 内置签名，由构建脚本手动签名
            if(BUILD_KEYCHAIN_PATH)
                set_target_properties(JinGo PROPERTIES
                    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
                    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
                    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
                    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${APPLE_DEVELOPMENT_TEAM}"
                    XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
                )
                message(STATUS "✓ macOS CI mode: Xcode signing disabled, will sign manually")
                message(STATUS "✓ Keychain: ${BUILD_KEYCHAIN_PATH}")
            else()
                # 本地开发环境：使用 Xcode 内置签名
                set_target_properties(JinGo PROPERTIES
                    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${APPLE_CODE_SIGN_IDENTITY}"
                    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${APPLE_DEVELOPMENT_TEAM}"
                    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Manual"
                    XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER "${MACOS_PROFILE_MAIN}"
                    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_SOURCE_DIR}/platform/macos/JinGo.entitlements"
                    # 公证要求：启用强化运行时，禁用调试权限注入
                    XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
                    XCODE_ATTRIBUTE_CODE_SIGN_INJECT_BASE_ENTITLEMENTS NO
                )
                message(STATUS "✓ macOS code signing configured with team: ${APPLE_DEVELOPMENT_TEAM}")
                message(STATUS "✓ macOS entitlements: ${CMAKE_SOURCE_DIR}/platform/macos/JinGo.entitlements")
            endif()
            message(STATUS "✓ Hardened Runtime enabled for notarization")
        endif()
    endif()

    # iOS post-build: Compile Assets.xcassets using actool
    if(TARGET_IOS)
        set(IOS_ASSETS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/platform/ios/Assets.xcassets")

        # Find actool
        find_program(ACTOOL actool HINTS /usr/bin)
        if(ACTOOL)
            add_custom_command(TARGET JinGo POST_BUILD
                COMMAND ${ACTOOL}
                    --output-format human-readable-text
                    --notices --warnings
                    --export-dependency-info "$<TARGET_BUNDLE_DIR:JinGo>/assetcatalog_dependencies"
                    --output-partial-info-plist "$<TARGET_BUNDLE_DIR:JinGo>/assetcatalog_generated_info.plist"
                    --app-icon AppIcon
                    --compress-pngs
                    --enable-on-demand-resources NO
                    --platform iphoneos
                    --minimum-deployment-target ${CMAKE_OSX_DEPLOYMENT_TARGET}
                    --target-device iphone
                    --compile "$<TARGET_BUNDLE_DIR:JinGo>"
                    "${IOS_ASSETS_DIR}"
                COMMENT "Compiling iOS Assets.xcassets with actool"
                VERBATIM
            )
            message(STATUS "✓ iOS Assets.xcassets will be compiled with actool")
        else()
            message(WARNING "actool not found, iOS app icons may not display correctly")
        endif()
    endif()
elseif(TARGET_WINDOWS)
    if(PLATFORM_RC)
        # Compile RC file manually to avoid issues with complex defines in windres
        set(RC_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/JinGo.rc.obj")
        add_custom_command(
            OUTPUT ${RC_OUTPUT}
            COMMAND windres -O coff -I "${CMAKE_CURRENT_SOURCE_DIR}/platform/windows"
                    "${PLATFORM_RC}" "${RC_OUTPUT}"
            DEPENDS ${PLATFORM_RC} "${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/JinGo.manifest"
            COMMENT "Compiling RC file with admin manifest"
            VERBATIM
        )
        qt_add_executable(JinGo WIN32 ${PROJECT_SOURCES} ${RC_OUTPUT})
    else()
        qt_add_executable(JinGo WIN32 ${PROJECT_SOURCES})
    endif()
else()
    qt_add_executable(JinGo ${PROJECT_SOURCES})
endif()

# ============================================================================
# 第十点六部分: macOS JinGoHelper (setuid 特权助手)
# ============================================================================
if(TARGET_MACOS)
    # JinGoHelper - 用于执行需要 root 权限的操作（路由、DNS）
    # 通过 setuid 机制获得 root 权限，避免每次弹窗
    # 当使用 JinDoCore 库时，从 JinDo 项目获取源码
    if(USE_JINDO_LIB)
        set(JINGO_HELPER_SOURCE "${JINDO_ROOT}/src/platform/apple/JinGoHelper.cpp")
    else()
        set(JINGO_HELPER_SOURCE "src/platform/apple/JinGoHelper.cpp")
    endif()

    add_executable(JinGoHelper
        ${JINGO_HELPER_SOURCE}
    )

    # 设置 C++17 标准
    set_target_properties(JinGoHelper PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED ON
        # 禁用签名（helper 通过 setuid 获得权限，不需要签名）
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
    )

    # 构建后复制 helper 到 bundle 内
    add_custom_command(TARGET JinGoHelper POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:JinGoHelper>"
            "${CMAKE_BINARY_DIR}/bin/$<CONFIG>/JinGo.app/Contents/MacOS/JinGoHelper"
        COMMENT "Copying JinGoHelper to app bundle"
    )

    # 确保 Helper 在主程序之前构建
    add_dependencies(JinGo JinGoHelper)

    message(STATUS "✓ JinGoHelper (setuid helper) configured for macOS")

    # ========================================================================
    # JinGoCore - 核心服务程序 (setuid root)
    # 包含 Xray + TUN + 路由/DNS 管理，类似 FlClash 的 FlClashCore
    # ========================================================================
    # 当使用 JinDoCore 库时，从 JinDo 项目获取源码
    if(USE_JINDO_LIB)
        set(JINGO_CORE_SOURCE "${JINDO_ROOT}/src/platform/apple/JinGoCore.mm")
    else()
        set(JINGO_CORE_SOURCE "src/platform/apple/JinGoCore.mm")
    endif()

    add_executable(JinGoCore
        ${JINGO_CORE_SOURCE}
    )

    # 设置 C++17 和 Objective-C++ 标准
    set_target_properties(JinGoCore PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED ON
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
    )

    # 链接 SuperRay 静态库
    set(SUPERRAY_MACOS_LIB "${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/apple/SuperRay.xcframework/macos-arm64_x86_64/libsuperray.a")
    if(EXISTS "${SUPERRAY_MACOS_LIB}")
        target_link_libraries(JinGoCore PRIVATE
            "${SUPERRAY_MACOS_LIB}"
            "-framework Foundation"
            "-framework CoreFoundation"
            "-framework Security"
            "-framework SystemConfiguration"
            "-framework Network"
            resolv
        )
        target_include_directories(JinGoCore PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/apple/SuperRay.xcframework/macos-arm64_x86_64/Headers"
        )
        message(STATUS "✓ JinGoCore: Linking libsuperray.a from xcframework")
    else()
        message(WARNING "JinGoCore: SuperRay library not found at ${SUPERRAY_MACOS_LIB}")
    endif()

    # 构建后复制到 bundle 内
    add_custom_command(TARGET JinGoCore POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:JinGoCore>"
            "${CMAKE_BINARY_DIR}/bin/$<CONFIG>/JinGo.app/Contents/MacOS/JinGoCore"
        COMMENT "Copying JinGoCore to app bundle"
    )

    # 确保 Core 在主程序之前构建
    add_dependencies(JinGo JinGoCore)

    message(STATUS "✓ JinGoCore (setuid core service) configured for macOS")
endif()

# ============================================================================
# 第十点五部分: iOS/macOS 排除 FFmpeg 多媒体插件
# ============================================================================
# Qt 6.10 默认链接 Multimedia 模块的 FFmpeg 后端
# 我们的应用不需要多媒体功能，排除这些插件以避免链接 FFmpeg 库

if(TARGET_IOS OR TARGET_MACOS)
    # 使用 qt_import_plugins 排除多媒体相关插件
    qt_import_plugins(JinGo
        EXCLUDE_BY_TYPE multimedia
    )
    message(STATUS "✓ Excluded multimedia plugins (FFmpeg) for Apple platform")
endif()

# ============================================================================
# 第十一部分: 添加QML模块
# ============================================================================

if(POLICY CMP0071)
    cmake_policy(SET CMP0071 NEW)
endif()
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

if(AVAILABLE_QML_FILES OR RESOURCE_FILES)
    # 添加qmldir文件到资源
    # 关键：qmldir 必须以模块名作为路径，而不是 components
    # 当 QML 执行 "import JinGo 1.0" 时，Qt 会在导入路径中查找 "JinGo/qmldir"
    set(QMLDIR_FILE ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/components/qmldir)
    if(EXISTS ${QMLDIR_FILE})
        set_source_files_properties(${QMLDIR_FILE} PROPERTIES
            QT_RESOURCE_ALIAS qml/JinGo/qmldir
        )
        list(APPEND RESOURCE_FILES ${QMLDIR_FILE})
    endif()

    qt_add_qml_module(JinGo
            URI JinGo
            VERSION 1.0
            QML_FILES ${AVAILABLE_QML_FILES}
            RESOURCES ${RESOURCE_FILES}
            NO_RESOURCE_TARGET_PATH
            NO_CACHEGEN  # 禁用QML预编译以减少内存使用
            NO_GENERATE_QMLDIR  # 使用我们自己的 qmldir 文件，包含 singleton 声明
            OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml
            RESOURCE_PREFIX "/"
    )
    list(LENGTH AVAILABLE_QML_FILES QML_FILE_COUNT)
    message(STATUS "QML module added with ${QML_FILE_COUNT} files (QML caching disabled to reduce memory usage)")
else()
    message(WARNING "No QML files or resources found")
endif()

# ============================================================================
# 第十二部分: 添加翻译支持
# ============================================================================

qt_add_translations(JinGo
    TS_FILES ${TS_FILES}
    SOURCES ${PROJECT_SOURCES} ${AVAILABLE_QML_FILES}
    RESOURCE_PREFIX "/translations"
)

# 翻译统计信息
list(LENGTH TS_FILES TS_FILE_COUNT)
message(STATUS "✓ Translation support added with ${TS_FILE_COUNT} languages, embedded as Qt resources at :/translations/")

# Android 特殊配置
if(TARGET_ANDROID)
    set_property(TARGET JinGo APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/platform/android")

    # 多ABI支持：如果指定了QT_ANDROID_ABIS，启用多ABI构建
    if(DEFINED QT_ANDROID_ABIS)
        set_property(TARGET JinGo PROPERTY QT_ANDROID_ABIS "${QT_ANDROID_ABIS}")
        message(STATUS "✓ Multi-ABI build enabled: ${QT_ANDROID_ABIS}")
    endif()
endif()

# ============================================================================
# 第十三部分: 安装GeoIP数据文件
# ============================================================================

set(GEOIP_FILES)
if(EXISTS ${GEOIP_DAT_FILE})
    list(APPEND GEOIP_FILES ${GEOIP_DAT_FILE})
endif()
if(EXISTS ${GEOSITE_DAT_FILE})
    list(APPEND GEOIP_FILES ${GEOSITE_DAT_FILE})
endif()

if(GEOIP_FILES)
    if(TARGET_MACOS)
        # macOS: 复制到 App Bundle 的 Resources/dat 目录
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "$<TARGET_BUNDLE_DIR:JinGo>/Contents/Resources/dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOIP_DAT_FILE}
                "$<TARGET_BUNDLE_DIR:JinGo>/Contents/Resources/dat/geoip.dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOSITE_DAT_FILE}
                "$<TARGET_BUNDLE_DIR:JinGo>/Contents/Resources/dat/geosite.dat"
            COMMENT "Copying GeoIP data files to App Bundle"
        )
        install(FILES ${GEOIP_FILES}
                DESTINATION JinGo.app/Contents/Resources/dat)
        message(STATUS "✓ GeoIP data files will be installed to App Bundle Resources/dat")

    elseif(TARGET_IOS)
        # iOS: 复制到 App Bundle 的根目录资源
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOIP_DAT_FILE}
                "$<TARGET_BUNDLE_DIR:JinGo>/geoip.dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOSITE_DAT_FILE}
                "$<TARGET_BUNDLE_DIR:JinGo>/geosite.dat"
            COMMENT "Copying GeoIP data files to iOS App Bundle"
        )
        install(FILES ${GEOIP_FILES} DESTINATION JinGo.app)
        message(STATUS "✓ GeoIP data files will be installed to iOS App Bundle")

    elseif(TARGET_ANDROID)
        # Android: POST_BUILD 命令需要在 qt_finalize_target 之后执行
        # 这里只设置路径和创建目录,实际复制在 qt_finalize_target 之后
        set(ANDROID_GEOIP_ASSETS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/platform/android/assets/dat")
        file(MAKE_DIRECTORY "${ANDROID_GEOIP_ASSETS_DIR}")

        message(STATUS "✓ GeoIP data files will be copied to Android assets/dat on each build")

    elseif(TARGET_WINDOWS)
        # Windows: 复制到可执行文件目录的 dat 子目录
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "$<TARGET_FILE_DIR:JinGo>/dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOIP_DAT_FILE}
                "$<TARGET_FILE_DIR:JinGo>/dat/geoip.dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOSITE_DAT_FILE}
                "$<TARGET_FILE_DIR:JinGo>/dat/geosite.dat"
            COMMENT "Copying GeoIP data files to build directory"
        )
        install(FILES ${GEOIP_FILES} DESTINATION dat)
        message(STATUS "✓ GeoIP data files will be installed to dat/")

    else()
        # Linux: 复制到 build 根目录和 bin 目录（可执行文件目录）
        add_custom_command(TARGET JinGo POST_BUILD
            # 复制到 build 根目录（用于从 build 目录运行）
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOIP_DAT_FILE}
                "${CMAKE_BINARY_DIR}/geoip.dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOSITE_DAT_FILE}
                "${CMAKE_BINARY_DIR}/geosite.dat"
            # 复制到 bin 目录（用于从 bin 目录运行，这是推荐的方式）
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOIP_DAT_FILE}
                "${CMAKE_BINARY_DIR}/bin/geoip.dat"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${GEOSITE_DAT_FILE}
                "${CMAKE_BINARY_DIR}/bin/geosite.dat"
            COMMENT "Copying GeoIP data files to build directory"
        )
        install(FILES ${GEOIP_FILES} DESTINATION share/jingo/dat)
        message(STATUS "✓ GeoIP data files will be copied to build/ and bin/")
    endif()

    list(LENGTH GEOIP_FILES GEOIP_COUNT)
    message(STATUS "GeoIP data files added: ${GEOIP_COUNT} files")
else()
    message(WARNING "No GeoIP data files found - routing rules may not work correctly")
endif()

# ============================================================================
# 第八部分: Bundle配置文件部署
# ============================================================================
# bundle_config.json 用于配置面板地址等信息，打包后可以修改
set(BUNDLE_CONFIG_FILE "${CMAKE_CURRENT_SOURCE_DIR}/resources/bundle_config.json")

if(EXISTS ${BUNDLE_CONFIG_FILE})
    message(STATUS "Found bundle_config.json for deployment")

    if(TARGET_MACOS)
        # macOS: 复制到 App Bundle 的 Resources 目录
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${BUNDLE_CONFIG_FILE}
                "$<TARGET_BUNDLE_DIR:JinGo>/Contents/Resources/bundle_config.json"
            COMMENT "Copying bundle_config.json to macOS App Bundle"
        )
        message(STATUS "✓ bundle_config.json will be installed to Contents/Resources/")

    elseif(TARGET_IOS)
        # iOS: 复制到 App Bundle 根目录
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${BUNDLE_CONFIG_FILE}
                "$<TARGET_BUNDLE_DIR:JinGo>/bundle_config.json"
            COMMENT "Copying bundle_config.json to iOS App Bundle"
        )
        install(FILES ${BUNDLE_CONFIG_FILE} DESTINATION JinGo.app)
        message(STATUS "✓ bundle_config.json will be installed to iOS App Bundle")

    elseif(TARGET_ANDROID)
        # Android: 复制到 assets 目录
        set(ANDROID_CONFIG_ASSETS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/platform/android/assets")
        file(MAKE_DIRECTORY "${ANDROID_CONFIG_ASSETS_DIR}")
        file(COPY ${BUNDLE_CONFIG_FILE} DESTINATION "${ANDROID_CONFIG_ASSETS_DIR}")
        message(STATUS "✓ bundle_config.json copied to Android assets/")

    elseif(TARGET_WINDOWS)
        # Windows: 复制到可执行文件目录
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${BUNDLE_CONFIG_FILE}
                "$<TARGET_FILE_DIR:JinGo>/bundle_config.json"
            COMMENT "Copying bundle_config.json to build directory"
        )
        install(FILES ${BUNDLE_CONFIG_FILE} DESTINATION .)
        message(STATUS "✓ bundle_config.json will be installed to executable directory")

    else()
        # Linux: 复制到可执行文件目录
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${BUNDLE_CONFIG_FILE}
                "$<TARGET_FILE_DIR:JinGo>/bundle_config.json"
            COMMENT "Copying bundle_config.json to build directory"
        )
        install(FILES ${BUNDLE_CONFIG_FILE} DESTINATION share/jingo/)
        message(STATUS "✓ bundle_config.json will be installed to share/jingo/")
    endif()
else()
    message(WARNING "bundle_config.json not found - using default configuration")
endif()

# ============================================================================
# 第十四部分: 包含路径配置
# ============================================================================

# 1. 设置所有包含路径
target_include_directories(JinGo PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/core
        ${CMAKE_CURRENT_SOURCE_DIR}/src/network
        ${CMAKE_CURRENT_SOURCE_DIR}/src/storage
        ${CMAKE_CURRENT_SOURCE_DIR}/src/models
        ${CMAKE_CURRENT_SOURCE_DIR}/src/viewmodels
        ${CMAKE_CURRENT_SOURCE_DIR}/src/platform
        ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
        ${CMAKE_CURRENT_SOURCE_DIR}/src/ui
        ${CMAKE_CURRENT_BINARY_DIR}/JinGo_autogen/include
)

# Platform-specific include directories
if(WIN32)
    target_include_directories(JinGo PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/platform/windows
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/wintun/include
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/windows/include
    )
elseif(TARGET_LINUX)
    target_include_directories(JinGo PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/platform/linux
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/linux/include
    )
endif()

if(EXISTS ${LIBXRAY_INCLUDE_DIR})
    target_include_directories(JinGo PRIVATE ${LIBXRAY_INCLUDE_DIR})
endif()

if(TARGET_ANDROID)
    target_include_directories(JinGo PRIVATE ${Qt6Core_PRIVATE_INCLUDE_DIRS})
endif()

# 2. 收集所有头文件 (包括 platform 目录下的所有文件)
file(GLOB_RECURSE ALL_HEADER_FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.hpp"

        "${CMAKE_CURRENT_SOURCE_DIR}/src/core/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/core/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/models/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/models/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/network/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/network/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/storage/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/storage/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/ui/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/ui/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/utils/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/utils/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/viewmodels/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/viewmodels/*.hpp"
)

# ⚠️ 关键：定义需要排除的平台特定头文件（绝对路径）
set(EXCLUDED_PLATFORM_HEADERS)

if(TARGET_MACOS)
    # macOS：排除其他平台
    list(APPEND EXCLUDED_PLATFORM_HEADERS
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/WindowsPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/LinuxPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidVpnHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatformHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidStatusBarManager.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/core/AndroidXrayBridge.h"
    )
elseif(TARGET_IOS)
    list(APPEND EXCLUDED_PLATFORM_HEADERS
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/WindowsPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/LinuxPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/MacOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidVpnHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidStatusBarManager.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/ui/SystemTrayManager.h"
    )
elseif(TARGET_ANDROID)
    list(APPEND EXCLUDED_PLATFORM_HEADERS
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/WindowsPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/LinuxPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/MacOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatformHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/ui/SystemTrayManager.h"
    )
elseif(TARGET_WINDOWS)
    list(APPEND EXCLUDED_PLATFORM_HEADERS
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/LinuxPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/MacOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidVpnHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatformHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidStatusBarManager.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/core/AndroidXrayBridge.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/utils/VPNConnectionDebugger.h"
    )
else()
    # Linux
    list(APPEND EXCLUDED_PLATFORM_HEADERS
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/WindowsPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/MacOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatform.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidVpnHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/IOSPlatformHelper.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/AndroidStatusBarManager.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/core/AndroidXrayBridge.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/src/utils/VPNConnectionDebugger.h"
    )
    # 注意：Linux使用SystemTrayManager,所以不排除它
endif()

# ⚠️ 对排除的头文件设置 SKIP_AUTOMOC（防止 MOC 处理）
message(STATUS "Excluding platform headers from MOC:")
foreach(excluded_header ${EXCLUDED_PLATFORM_HEADERS})
    if(EXISTS ${excluded_header})
        set_source_files_properties(${excluded_header}
                PROPERTIES
                SKIP_AUTOMOC ON
                HEADER_FILE_ONLY TRUE
        )
        message(STATUS "  ✓ Skipped: ${excluded_header}")
    endif()
endforeach()

# 3. 移除副本和备份文件
list(FILTER ALL_HEADER_FILES EXCLUDE REGEX
        ".*(_副本|_backup|_old|/backup/|/old/).*")

# 5. IDE 文件显示：将所有头文件和 QML 文件添加到 target_sources,强制 IDE 显示。
#    这将确保所有文件出现在 IDE 项目树中。
if(MSVC OR XCODE)
    # 为所有头文件设置 HEADER_FILE_ONLY 属性
    foreach(header_file ${ALL_HEADER_FILES})
        set_source_files_properties(${header_file}
                PROPERTIES
                HEADER_FILE_ONLY TRUE
        )
    endforeach()

    # 将所有头文件添加到目标中
    target_sources(JinGo PRIVATE ${ALL_HEADER_FILES})

    # 为 Visual Studio/Xcode 创建文件夹分组
    source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
            PREFIX "Header Files" FILES ${ALL_HEADER_FILES})
    source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
            PREFIX "Source Files" FILES ${PROJECT_SOURCES})
    if(AVAILABLE_QML_FILES)
        source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/resources/qml"
                PREFIX "QML Files" FILES ${AVAILABLE_QML_FILES})
    endif()
endif()

# ============================================================================
# 第十五部分: 链接库
# ============================================================================

target_link_libraries(JinGo PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Network
        Qt6::Sql
        Qt6::Concurrent
        ${PLATFORM_LIBS}
)

# 链接 JinDoCore 静态库
if(USE_JINDO_LIB AND TARGET JinDoCore)
    target_link_libraries(JinGo PRIVATE JinDoCore)
    # 添加 JinDoCore 头文件目录及其所有子目录
    target_include_directories(JinGo PRIVATE
        ${JINDO_INCLUDE_DIR}
        ${JINDO_INCLUDE_DIR}/core
        ${JINDO_INCLUDE_DIR}/models
        ${JINDO_INCLUDE_DIR}/network
        ${JINDO_INCLUDE_DIR}/platform
        ${JINDO_INCLUDE_DIR}/platform/apple
        ${JINDO_INCLUDE_DIR}/storage
        ${JINDO_INCLUDE_DIR}/utils
        ${JINDO_INCLUDE_DIR}/viewmodels
        ${JINDO_INCLUDE_DIR}/ui
        ${JINDO_INCLUDE_DIR}/extensions
        ${JINDO_INCLUDE_DIR}/extensions/PacketTunnelProvider
    )

    # Windows 平台需要重新链接 JinDoCore 依赖的 Qt 模块和系统库
    # 原因: 静态库链接顺序问题 - 链接器在处理 PLATFORM_LIBS 时 JinDoCore 还未被处理
    # 所以这些库的符号被忽略了。现在 JinDoCore 已链接,需要再次声明这些依赖
    if(TARGET_WINDOWS)
        # 强制使用静态 pthread 库（不是 DLL 导入库）
        set(WINPTHREAD_STATIC_LIB "D:/Qt/Tools/mingw1310_64/x86_64-w64-mingw32/lib/libwinpthread.a")

        if(NOT EXISTS "${WINPTHREAD_STATIC_LIB}")
            message(FATAL_ERROR "winpthread static library not found: ${WINPTHREAD_STATIC_LIB}")
        endif()

        message(STATUS "✓ Using winpthread static library: ${WINPTHREAD_STATIC_LIB}")

        target_link_libraries(JinGo PRIVATE
            Qt6::Sql                    # JinDoCore 依赖 Qt SQL (DatabaseManager)
            Qt6::Gui                    # JinDoCore 依赖 Qt GUI (QSystemTrayIcon)
            Qt6::Widgets                # JinDoCore 依赖 Qt Widgets (QMenu, QAction)
            wininet                     # InternetSetOptionW
            crypt32                     # CryptProtectData, CryptUnprotectData
            ${WINPTHREAD_STATIC_LIB}   # pthread 静态库 (nanosleep64)
        )

        message(STATUS "✓ Re-linked Qt modules and system libraries for JinDoCore")
    endif()

    # Linux 平台也需要重新链接 JinDoCore 依赖的系统库和 Qt 模块
    # 原因: 同 Windows - 静态库链接顺序问题
    if(TARGET_LINUX)
        target_link_libraries(JinGo PRIVATE
            Qt6::Sql                   # JinDoCore 依赖 Qt SQL (DatabaseManager)
            Qt6::Gui                   # JinDoCore 依赖 Qt GUI (QSystemTrayIcon)
            Qt6::Widgets               # JinDoCore 依赖 Qt Widgets (QMenu, QAction)
            ${PLATFORM_LIBS}           # 重新链接 glib-2.0, libsecret 等
        )
        message(STATUS "✓ Re-linked Qt modules and system libraries for JinDoCore on Linux")
    endif()

    message(STATUS "✓ Linked JinDoCore static library")
endif()

if(UNIX AND NOT APPLE AND NOT ANDROID AND TARGET Qt6::DBus)
    target_link_libraries(JinGo PRIVATE Qt6::DBus)
    message(STATUS "✓ Qt6::DBus linked for Linux")
endif()

# ============================================================================
# OpenSSL 依赖 (用于授权系统加密)
# ============================================================================
if(TARGET_ANDROID OR ANDROID)
    # Android: 使用 NDK 中的 OpenSSL 或第三方库
    set(ANDROID_OPENSSL_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/android_openssl")
    if(EXISTS "${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}")
        set(ANDROID_OPENSSL_INCLUDE "${ANDROID_OPENSSL_ROOT}/include")
        set(ANDROID_OPENSSL_LIB_DIR "${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}")
        target_include_directories(JinGo PRIVATE ${ANDROID_OPENSSL_INCLUDE})
        # 使用完整库路径，因为库名是 libssl_3.so 和 libcrypto_3.so
        target_link_libraries(JinGo PRIVATE
            "${ANDROID_OPENSSL_LIB_DIR}/libssl_3.so"
            "${ANDROID_OPENSSL_LIB_DIR}/libcrypto_3.so"
        )
        message(STATUS "✓ Android OpenSSL: ${ANDROID_OPENSSL_LIB_DIR}")
    else()
        # 回退到系统 OpenSSL
        find_package(OpenSSL QUIET)
        if(OPENSSL_FOUND)
            target_link_libraries(JinGo PRIVATE OpenSSL::SSL OpenSSL::Crypto)
            message(STATUS "✓ Android OpenSSL: System OpenSSL")
        else()
            message(WARNING "Android: OpenSSL not found, license encryption will not work")
        endif()
    endif()
elseif(TARGET_IOS)
    # iOS: 使用 Security.framework + CommonCrypto，不使用 OpenSSL
    # iOS 不能使用 Homebrew OpenSSL（那是 macOS 版本）
    # RsaCrypto 和 AesCrypto 已经有 Apple 原生实现作为备用
    message(STATUS "✓ iOS: Using Security.framework + CommonCrypto (no OpenSSL)")
    # 注意：如果需要 OpenSSL，需要交叉编译 iOS 版本的 OpenSSL
elseif(TARGET_MACOS OR APPLE)
    # macOS: 使用 Security.framework + CommonCrypto（与 iOS 相同）
    # 不需要 OpenSSL，RsaCrypto 和 AesCrypto 使用 Apple 原生 API
    message(STATUS "✓ macOS: Using Security.framework + CommonCrypto (no OpenSSL)")
elseif(WIN32)
    # Windows: 使用 BCrypt/NCrypt (CNG) 而非 OpenSSL
    # RsaCrypto_windows.cpp 使用 Windows 原生加密 API
    # bcrypt, ncrypt, crypt32 库已在 Platform-Windows.cmake 中配置
    message(STATUS "✓ Windows: Using BCrypt/NCrypt (CNG) for crypto")
else()
    # Linux: 使用 third_party/linux_openssl 中的 OpenSSL 3.0.7
    set(LINUX_OPENSSL_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/linux_openssl")
    set(LINUX_OPENSSL_INCLUDE "${LINUX_OPENSSL_ROOT}/include")
    set(LINUX_OPENSSL_LIB_DIR "${LINUX_OPENSSL_ROOT}/x86_64")

    if(EXISTS "${LINUX_OPENSSL_LIB_DIR}/libssl.so" AND EXISTS "${LINUX_OPENSSL_LIB_DIR}/libcrypto.so")
        target_include_directories(JinGo PRIVATE ${LINUX_OPENSSL_INCLUDE})
        target_link_libraries(JinGo PRIVATE
            "${LINUX_OPENSSL_LIB_DIR}/libssl.so"
            "${LINUX_OPENSSL_LIB_DIR}/libcrypto.so"
        )
        message(STATUS "✓ Linux OpenSSL: 3.0.7 (third_party/linux_openssl)")
    else()
        # 回退到系统 OpenSSL
        find_package(OpenSSL REQUIRED)
        target_link_libraries(JinGo PRIVATE OpenSSL::SSL OpenSSL::Crypto)
        message(STATUS "✓ Linux OpenSSL: ${OPENSSL_VERSION} (system)")
    endif()
endif()

target_compile_definitions(JinGo PRIVATE
        QT_DEPRECATED_WARNINGS
        QT_DISABLE_DEPRECATED_BEFORE=0x060500
        APP_VERSION="${PROJECT_VERSION}"
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(JinGo PRIVATE QT_QML_DEBUG)
endif()

# ============================================================================
# 第十六部分: SuperRay集成 - 支持Android AAR
# ============================================================================

option(USE_SUPERRAY "Enable SuperRay support" ON)

if(USE_SUPERRAY)

    # 1. 检查头文件目录
    if(NOT EXISTS ${LIBXRAY_INCLUDE_DIR})
        message(WARNING "LibXray include directory not found: ${LIBXRAY_INCLUDE_DIR}")
        message(WARNING "Build will continue without LibXray support")
        set(USE_SUPERRAY OFF)

    # 2. 检查库文件
    elseif(ANDROID AND LIBXRAY_IS_AAR AND NOT EXISTS ${LIBXRAY_SO_PATH})
        # Android AAR: .so文件不存在
        message(WARNING "LibXray .so not found in AAR: ${LIBXRAY_SO_PATH}")
        message(WARNING "Build will continue without LibXray support")
        set(USE_SUPERRAY OFF)

    elseif(NOT (ANDROID AND LIBXRAY_IS_AAR) AND NOT EXISTS ${LIBXRAY_LIB})
        # 非AAR情况：库文件不存在
        message(WARNING "LibXray library not found: ${LIBXRAY_LIB}")
        message(WARNING "Build will continue without LibXray support")
        set(USE_SUPERRAY OFF)

    else()
        # 所有检查通过,继续配置
        # 3. 验证库文件格式
        # Android AAR: 跳过扩展名检查（因为LIBXRAY_LIB是导入目标名）
        if(ANDROID AND LIBXRAY_IS_AAR)
            set(VALID_LIBRARY ON)
            message(STATUS "✓ Using Android AAR library (imported target)")
        else()
            get_filename_component(LIBXRAY_EXT ${LIBXRAY_LIB} EXT)
            get_filename_component(LIBXRAY_NAME ${LIBXRAY_LIB} NAME)
            set(VALID_LIBRARY OFF)

            # Windows 平台验证
            if(WIN32)
                # Windows: .lib 或 .dll
                if(LIBXRAY_EXT STREQUAL ".lib" OR LIBXRAY_EXT STREQUAL ".dll")
                    set(VALID_LIBRARY ON)
                    # 如果是 .lib,检查对应的 .dll 是否存在
                    if(LIBXRAY_EXT STREQUAL ".lib" AND DEFINED LIBXRAY_DLL)
                        if(NOT EXISTS ${LIBXRAY_DLL})
                            message(WARNING "✗ libxray DLL not found: ${LIBXRAY_DLL}")
                            message(WARNING "   Runtime may fail if DLL is missing")
                        else()
                            message(STATUS "✓ Found libxray DLL: ${LIBXRAY_DLL}")
                        endif()
                    endif()
                endif()

            # Apple 平台验证
            elseif(APPLE)
                # Apple: .a (静态库) 或 .framework
                if(LIBXRAY_EXT STREQUAL ".a" OR LIBXRAY_EXT STREQUAL ".framework")
                    set(VALID_LIBRARY ON)
                endif()

            # Linux/Android 验证
            else()
                # Linux/Android: .so (共享库) 或 .a (静态库)
                if(LIBXRAY_EXT STREQUAL ".so" OR LIBXRAY_EXT STREQUAL ".a")
                    set(VALID_LIBRARY ON)
                endif()
            endif()

            if(NOT VALID_LIBRARY)
                message(WARNING "Unexpected libxray library format: ${LIBXRAY_NAME}")
                message(WARNING "Expected extensions: .lib/.dll (Windows), .a/.framework (Apple), .so/.a (Linux/Android)")
                message(WARNING "Build will continue, but linking may fail")
            endif()
        endif()

        # 4. 添加头文件目录
        target_include_directories(JinGo PRIVATE ${LIBXRAY_INCLUDE_DIR})

        # 5. 链接库文件（平台特定）
        if(TARGET_MACOS OR TARGET_IOS)
            # Apple平台：静态库,使用特殊链接选项
            # 修复：移除 -force_load 避免重复符号错误
            target_link_directories(JinGo PRIVATE "${LIBXRAY_LIBRARY_DIR}")
            target_link_options(JinGo PRIVATE "-F${LIBXRAY_LIBRARY_DIR}")
            target_link_libraries(JinGo PRIVATE
                    "${LIBXRAY_LIB}"
                    "-lz"
                    "-lresolv"
            )
        elseif(TARGET_ANDROID OR ANDROID)
            # Android: Link SuperRay shared library
            if(TARGET superray_imported)
                target_link_libraries(JinGo PRIVATE superray_imported)
                message(STATUS "✓ Android: Linking superray_imported target")
            elseif(SUPERRAY_LIB AND EXISTS "${SUPERRAY_LIB}")
                get_filename_component(SUPERRAY_SO_DIR "${SUPERRAY_LIB}" DIRECTORY)
                target_link_directories(JinGo PRIVATE "${SUPERRAY_SO_DIR}")
                target_link_libraries(JinGo PRIVATE superray)
                message(STATUS "✓ Android: Linking libsuperray.so from ${SUPERRAY_SO_DIR}")
            else()
                message(WARNING "Android: SuperRay library not available")
            endif()
        elseif(TARGET_WINDOWS)
            # Windows: Link SuperRay DLL
            set(SUPERRAY_WIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/windows")
            set(SUPERRAY_WIN_LIB "${SUPERRAY_WIN_DIR}/amd64/superray.dll")
            if(EXISTS "${SUPERRAY_WIN_LIB}")
                target_link_directories(JinGo PRIVATE "${SUPERRAY_WIN_DIR}/amd64")
                target_link_libraries(JinGo PRIVATE superray)
                message(STATUS "✓ Windows: Linking superray.dll from ${SUPERRAY_WIN_DIR}/amd64")
            else()
                message(WARNING "Windows: SuperRay DLL not found at ${SUPERRAY_WIN_LIB}")
            endif()
        elseif(TARGET_LINUX)
            # Linux: Link SuperRay shared library
            set(SUPERRAY_LINUX_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/linux")
            if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
                set(SUPERRAY_LINUX_LIB "${SUPERRAY_LINUX_DIR}/arm64/libsuperray.so")
                set(SUPERRAY_LINUX_LIB_DIR "${SUPERRAY_LINUX_DIR}/arm64")
            else()
                set(SUPERRAY_LINUX_LIB "${SUPERRAY_LINUX_DIR}/amd64/libsuperray.so")
                set(SUPERRAY_LINUX_LIB_DIR "${SUPERRAY_LINUX_DIR}/amd64")
            endif()
            if(EXISTS "${SUPERRAY_LINUX_LIB}")
                target_link_directories(JinGo PRIVATE "${SUPERRAY_LINUX_LIB_DIR}")
                target_link_libraries(JinGo PRIVATE superray)
                message(STATUS "✓ Linux: Linking libsuperray.so from ${SUPERRAY_LINUX_LIB_DIR}")
            else()
                message(WARNING "Linux: SuperRay library not found at ${SUPERRAY_LINUX_LIB}")
            endif()
        endif()

        # 6. 设置编译定义
        target_compile_definitions(JinGo PRIVATE HAVE_SUPERRAY)

        # 7. 配置 RPATH 以便运行时找到动态库（Linux/macOS）
        if(TARGET_LINUX)
            # Linux: 在可执行文件目录和 ../lib 中查找
            set_target_properties(JinGo PROPERTIES
                    INSTALL_RPATH "$ORIGIN:$ORIGIN/../lib"
                    BUILD_WITH_INSTALL_RPATH OFF
            )
            message(STATUS "✓ Linux RPATH configured: \$ORIGIN:\$ORIGIN/../lib")

        elseif(TARGET_MACOS)
            # macOS: 在 App Bundle 的 Frameworks 中查找
            set_target_properties(JinGo PROPERTIES
                    INSTALL_RPATH "@executable_path/../Frameworks"
                    BUILD_WITH_INSTALL_RPATH OFF
            )
            message(STATUS "✓ macOS RPATH configured: @executable_path/../Frameworks")

            # macOS: 使用静态库,不需要复制 Framework
            # 静态库已经链接到可执行文件中
            message(STATUS "✓ Using libxray static library (no framework copy needed)")

        elseif(TARGET_WINDOWS)
            # Windows: 复制 libXray.dll 到输出目录
            if(DEFINED LIBXRAY_DLL AND EXISTS ${LIBXRAY_DLL})
                add_custom_command(TARGET JinGo POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${LIBXRAY_DLL}"
                        "$<TARGET_FILE_DIR:JinGo>/libXray.dll"
                    COMMENT "Copying libXray.dll to output directory"
                )
                message(STATUS "✓ libXray.dll will be copied to output directory on build")
            endif()
        endif()

        if(ANDROID AND LIBXRAY_IS_AAR)
            message(STATUS "✓ LibXray AAR enabled: ${LIBXRAY_LIB}")
        else()
            message(STATUS "✓ LibXray enabled: ${LIBXRAY_LIB}")
        endif()
    endif()
endif()

# 如果 SuperRay 不可用,设置 NO_SUPERRAY 定义
if(NOT USE_SUPERRAY)
    target_compile_definitions(JinGo PRIVATE NO_SUPERRAY)
    message(STATUS "SuperRay disabled (USE_SUPERRAY=OFF or not found)")
endif()

# ============================================================================
# 第十七部分: WinTun驱动集成 (Windows)
# ============================================================================

if(WIN32)
    set(WINTUN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/wintun")

    # 检测系统架构并选择对应的 wintun.dll
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(WINTUN_DLL "${WINTUN_ROOT}/bin/amd64/wintun.dll")
    else()
        set(WINTUN_DLL "${WINTUN_ROOT}/bin/x86/wintun.dll")
    endif()

    # 如果 wintun.dll 存在,则在构建时拷贝到输出目录
    if(EXISTS ${WINTUN_DLL})
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${WINTUN_DLL}"
                "$<TARGET_FILE_DIR:JinGo>/wintun.dll"
            COMMENT "Copying wintun.dll to output directory"
        )
        message(STATUS "✓ wintun.dll will be copied to output directory on build: ${WINTUN_DLL}")
    else()
        message(WARNING "wintun.dll not found at: ${WINTUN_DLL}")
        message(WARNING "Please download WinTun from https://www.wintun.net/ and extract to third_party/wintun/")
    endif()

    # 复制 superray.dll 到输出目录（运行时始终需要）
    set(SUPERRAY_WIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/superray/windows")
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(SUPERRAY_DLL "${SUPERRAY_WIN_DIR}/amd64/superray.dll")
    else()
        set(SUPERRAY_DLL "${SUPERRAY_WIN_DIR}/x86/superray.dll")
    endif()

    if(EXISTS ${SUPERRAY_DLL})
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${SUPERRAY_DLL}"
                "$<TARGET_FILE_DIR:JinGo>/superray.dll"
            COMMENT "Copying superray.dll to output directory"
        )
        message(STATUS "✓ superray.dll will be copied to bin/ on build: ${SUPERRAY_DLL}")
    else()
        message(WARNING "superray.dll not found at: ${SUPERRAY_DLL}")
    endif()

    # 自动运行 windeployqt 部署 Qt 依赖（每次构建后自动执行）
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS ${CMAKE_PREFIX_PATH}/bin)

    if(WINDEPLOYQT_EXECUTABLE)
        add_custom_command(TARGET JinGo POST_BUILD
            COMMAND ${WINDEPLOYQT_EXECUTABLE}
                --qmldir "${CMAKE_SOURCE_DIR}/resources/qml"
                --no-compiler-runtime
                --no-translations
                "$<TARGET_FILE:JinGo>"
            COMMENT "Running windeployqt to deploy Qt dependencies..."
        )
        message(STATUS "✓ windeployqt will run automatically after each build")
        message(STATUS "  windeployqt path: ${WINDEPLOYQT_EXECUTABLE}")
    else()
        message(WARNING "windeployqt not found. Qt DLLs will not be automatically deployed.")
        message(WARNING "You may need to manually run: windeployqt <path-to-JinGo.exe>")
        message(WARNING "Or add Qt bin directory to PATH")
    endif()

    # 复制 MinGW 运行时 DLL 到输出目录（用于调试运行）
    # 查找 MinGW 安装目录
    get_filename_component(MINGW_BIN_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)

    set(MINGW_RUNTIME_DLLS
        "${MINGW_BIN_DIR}/libgcc_s_seh-1.dll"
        "${MINGW_BIN_DIR}/libstdc++-6.dll"
        "${MINGW_BIN_DIR}/libwinpthread-1.dll"
    )

    foreach(dll ${MINGW_RUNTIME_DLLS})
        if(EXISTS ${dll})
            get_filename_component(dll_name ${dll} NAME)
            add_custom_command(TARGET JinGo POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${dll}"
                    "$<TARGET_FILE_DIR:JinGo>/${dll_name}"
                COMMENT "Copying ${dll_name} to output directory"
            )
        endif()
    endforeach()

    message(STATUS "✓ MinGW runtime DLLs will be copied to bin/ on build")
    message(STATUS "  MinGW bin directory: ${MINGW_BIN_DIR}")
endif()

# ============================================================================
# 第十八点五部分: Linux TUN设备权限设置
# ============================================================================

if(TARGET_LINUX)
    # Linux TUN模式需要 CAP_NET_ADMIN 权限来创建和配置虚拟网络设备
    # 在编译完成后自动设置文件 capabilities

    add_custom_command(TARGET JinGo POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMAND ${CMAKE_COMMAND} -E echo "=========================================="
        COMMAND ${CMAKE_COMMAND} -E echo "设置 Linux TUN 权限 (CAP_NET_ADMIN)"
        COMMAND ${CMAKE_COMMAND} -E echo "=========================================="

        # 尝试使用 sudo 设置 capabilities
        COMMAND bash -c "if command -v sudo >/dev/null 2>&1; then \
                sudo setcap cap_net_admin+eip $<TARGET_FILE:JinGo> 2>/dev/null && \
                echo '✓ CAP_NET_ADMIN 权限已设置: cap_net_admin+eip' && \
                getcap $<TARGET_FILE:JinGo> || \
                echo '⚠ 无法自动设置权限 (需要 sudo 密码)'; \
            else \
                echo '⚠ sudo 命令不可用，无法自动设置权限'; \
            fi"

        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMAND ${CMAKE_COMMAND} -E echo "如果上述自动设置失败，请手动运行:"
        COMMAND ${CMAKE_COMMAND} -E echo "  sudo setcap cap_net_admin+eip $<TARGET_FILE:JinGo>"
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMAND ${CMAKE_COMMAND} -E echo "权限说明:"
        COMMAND ${CMAKE_COMMAND} -E echo "  cap_net_admin = 网络管理权限（创建TUN设备、配置路由）"
        COMMAND ${CMAKE_COMMAND} -E echo "  +e = Effective（进程启动时立即生效）"
        COMMAND ${CMAKE_COMMAND} -E echo "  +i = Inheritable（子进程可继承）"
        COMMAND ${CMAKE_COMMAND} -E echo "  +p = Permitted（允许进程拥有此权限）"
        COMMAND ${CMAKE_COMMAND} -E echo "=========================================="
        COMMAND ${CMAKE_COMMAND} -E echo ""

        COMMENT "设置 Linux TUN 设备所需的网络管理权限"
        VERBATIM
    )

    message(STATUS "✓ Linux TUN 权限设置已添加到构建流程")
    message(STATUS "  编译后将自动尝试设置 cap_net_admin+eip")
    message(STATUS "  如果自动设置失败，请手动运行:")
    message(STATUS "    sudo setcap cap_net_admin+eip <JinGo可执行文件路径>")
endif()

# ============================================================================
# 第十九部分: 编译选项
# ============================================================================

if(MSVC)
    target_compile_options(JinGo PRIVATE /W4 /utf-8 /MP /Zc:__cplusplus /permissive-)
else()
    target_compile_options(JinGo PRIVATE
            -Wall -Wextra -Wpedantic
            $<$<CONFIG:Release>:-O3>
            # Suppress common harmless warnings
            -Wno-unknown-pragmas          # Ignore MSVC-specific #pragma directives
            -Wno-unused-parameter         # Ignore unused function parameters
            -Wno-unused-variable          # Ignore unused variables
            -Wno-missing-field-initializers  # Ignore partial struct initialization
            -Wno-sign-compare             # Ignore signed/unsigned comparison
    )
    # GCC-specific warning suppressions
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(JinGo PRIVATE
            -Wno-cast-function-type       # Ignore Windows API function pointer casts
            $<$<COMPILE_LANGUAGE:CXX>:-Wno-reorder>  # Ignore member initialization order (C++ only)
            -Wno-stringop-overread        # Ignore string operation warnings (GCC 11+)
        )
    endif()
    # Clang-specific warning suppressions
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        target_compile_options(JinGo PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:-Wno-reorder-ctor>  # Clang equivalent of -Wno-reorder (C++ only)
        )
    endif()
    # Suppress Qt-specific nodiscard warnings
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(JinGo PRIVATE -Wno-unused-result)
    endif()
endif()

# Apple platforms require -fmodules for @import syntax in LibXray headers
if(TARGET_MACOS OR TARGET_IOS)
    # Use direct flags instead of generator expressions to avoid compile issues
    target_compile_options(JinGo PRIVATE -fmodules -fcxx-modules)
    # Also set Xcode attribute for modules
    set_target_properties(JinGo PROPERTIES
        XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES YES
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
    )
    message(STATUS "✓ Objective-C modules enabled for Apple platforms (@import support)")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(JinGo PRIVATE
            QT_QML_DEBUG
            DEBUG_MODE
            QT_MESSAGELOGCONTEXT
            ENABLE_VERBOSE_LOGGING
    )
    message(STATUS "Build type: Debug (verbose logging enabled)")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(JinGo PRIVATE
            QT_NO_DEBUG_OUTPUT
            NDEBUG
            QT_NO_WARNING_OUTPUT
    )
    if(NOT MSVC)
        # Disable LTO for faster development builds (enable for release distribution)
        target_compile_options(JinGo PRIVATE -O2)
        message(STATUS "LTO disabled for faster linking (enable for production builds)")

        # To enable LTO for production, uncomment below and comment above:
        # include(CheckCXXCompilerFlag)
        # check_cxx_compiler_flag("-flto" SUPPORTS_FLTO)
        # if(SUPPORTS_FLTO)
        #     target_compile_options(JinGo PRIVATE -O3 -flto=auto)
        #     target_link_options(JinGo PRIVATE -flto=auto)
        #     message(STATUS "LTO enabled with parallel compilation")
        # else()
        #     target_compile_options(JinGo PRIVATE -O3)
        # endif()
    endif()
    message(STATUS "Build type: Release (optimizations enabled)")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    target_compile_definitions(JinGo PRIVATE
            QT_MESSAGELOGCONTEXT
            RELEASE_WITH_DEBUG
    )
    message(STATUS "Build type: RelWithDebInfo")
endif()

target_compile_definitions(JinGo PRIVATE
        APP_NAME="JinGoVPN"
        APP_VERSION="${PROJECT_VERSION}"
        APP_ORGANIZATION="JinGo"
)

# ============================================================================
# 第二十部分: 平台特定Finalization配置
# ============================================================================
# 注意: 平台基础配置已经在第五.五部分include过了,这里只include finalization

if(TARGET_ANDROID)
    include(cmake/Platform-Android-Finalize.cmake)
endif()

# ============================================================================
# 第二十一部分: Extensions配置 (仅iOS平台)
# ============================================================================
# macOS 使用管理员模式 TUN（MacOSTunManager），不需要 Network Extension
# iOS 继续使用 Network Extension（PacketTunnelProvider）
if(TARGET_IOS)
    include(cmake/Extension-PacketTunnel.cmake)
endif()

# ============================================================================
# 第二十二部分: 代码签名和打包 (仅Apple平台)
# ============================================================================
if(APPLE AND NOT ANDROID)
    include(cmake/Signing-Apple.cmake)
endif()

# ============================================================================
# iOS Xcode 项目后处理
# ============================================================================
if(TARGET_IOS AND CMAKE_GENERATOR STREQUAL "Xcode")
    # 提示用户手动运行脚本（因为 Xcode 项目在 CMake 完成后才生成）
    message(STATUS "")
    message(STATUS "========================================")
    message(STATUS "iOS Xcode Project Configuration")
    message(STATUS "========================================")
    message(STATUS "After CMake generation completes, run:")
    message(STATUS "  ./scripts/fix-xcode-project-ios.sh")
    message(STATUS "")
    message(STATUS "This script will configure:")
    message(STATUS "  - Manual code signing")
    message(STATUS "  - Provisioning profiles for all targets")
    message(STATUS "========================================")
    message(STATUS "")
endif()

# ============================================================================
# 第二十三部分: 测试、文档和打包
# ============================================================================

option(BUILD_TESTS "Build test suite" OFF)
if(BUILD_TESTS)
    enable_testing()
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt)
        add_subdirectory(tests)
        message(STATUS "Tests enabled")
    endif()
endif()

option(BUILD_DOCS "Build documentation" OFF)
if(BUILD_DOCS)
    find_package(Doxygen)
    if(DOXYGEN_FOUND AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in
                ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)
        add_custom_target(docs
                ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMENT "Generating documentation with Doxygen"
                VERBATIM)
        message(STATUS "Documentation target enabled")
    endif()
endif()

option(ENABLE_PACKAGING "Enable CPack packaging" OFF)
if(ENABLE_PACKAGING)
    set(CPACK_PACKAGE_NAME "jingo-vpn")
    set(CPACK_PACKAGE_VENDOR "JinGo")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Cross-platform Xray VPN Client")
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "JinGoVPN")

    if(WIN32)
        set(CPACK_GENERATOR "NSIS;ZIP")
        set(CPACK_NSIS_DISPLAY_NAME "JinGoVPN")
        set(CPACK_NSIS_PACKAGE_NAME "JinGoVPN")
        set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    elseif(APPLE)
        set(CPACK_GENERATOR "DragNDrop")
        set(CPACK_DMG_VOLUME_NAME "JinGoVPN")
    else()
        set(CPACK_GENERATOR "DEB;RPM;TGZ")

        # DEB 包配置
        set(CPACK_DEBIAN_PACKAGE_MAINTAINER "JinGo Team <support@opine.work>")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6, libstdc++6, libgcc1, libsecret-1-0, libcap2-bin, libgtk-3-0")
        set(CPACK_DEBIAN_PACKAGE_SECTION "net")
        set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
        set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://github.com/jingo-vpn")
        set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")  # 标准命名: jingo-vpn_1.0.0_amd64.deb
        set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "JinGoVPN - Cross-platform VPN Client
 A modern, secure VPN client based on Xray-core.
 .
 Features:
  - Cross-platform support (Linux/Windows/macOS/iOS/Android)
  - TUN mode VPN with system-wide traffic interception
  - Modern Qt/QML user interface
  - Subscription management with auto-update
  - Multi-language support")

        # DEB 包安装前后脚本
        set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
            "${CMAKE_CURRENT_SOURCE_DIR}/platform/linux/debian/postinst;${CMAKE_CURRENT_SOURCE_DIR}/platform/linux/debian/postrm")

        # RPM 特定配置
        set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0")
        set(CPACK_RPM_PACKAGE_GROUP "Applications/Internet")
        set(CPACK_RPM_PACKAGE_REQUIRES "glibc, libstdc++, libgcc, libsecret, libcap")
        set(CPACK_RPM_PACKAGE_DESCRIPTION "JinGoVPN - Cross-platform VPN Client
A modern, secure VPN client based on Xray-core with TUN mode support.")
    endif()

    include(CPack)
    message(STATUS "Packaging enabled")
endif()

# ============================================================================
# MOC 诊断输出
# ============================================================================

option(ENABLE_MOC_DIAGNOSTICS "Enable MOC diagnostics" OFF)
if(ENABLE_MOC_DIAGNOSTICS)
    get_target_property(automoc_enabled JinGo AUTOMOC)
    message(STATUS "AUTOMOC enabled: ${automoc_enabled}")

    file(GLOB_RECURSE MOC_FILES "${CMAKE_CURRENT_BINARY_DIR}/*_autogen/mocs_compilation.cpp")
    if(MOC_FILES)
        message(STATUS "MOC files found:")
        foreach(moc_file ${MOC_FILES})
            message(STATUS "  ${moc_file}")
        endforeach()
    else()
        message(WARNING "No MOC files generated yet (check after first build)")
    endif()
endif()

# ============================================================================
# Linux 安装配置 (Desktop File & Icon)
# ============================================================================

if(LINUX AND NOT TARGET_ANDROID)
    # 安装可执行文件
    install(TARGETS JinGo
            RUNTIME DESTINATION bin
            COMPONENT applications)

    # 安装桌面文件
    install(FILES platform/linux/jingo.desktop
            DESTINATION share/applications
            COMPONENT applications)

    # 安装应用图标（多种尺寸）
    set(ICON_SIZES 16 22 24 32 48 64 128 256 512)
    foreach(size ${ICON_SIZES})
        # 检查是否存在该尺寸的图标
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app_${size}.png")
            install(FILES "resources/icons/app_${size}.png"
                    DESTINATION "share/icons/hicolor/${size}x${size}/apps"
                    RENAME "jingo.png"
                    COMPONENT applications)
        endif()
    endforeach()

    # 安装主图标（如果没有特定尺寸，使用通用图标）
    install(FILES resources/icons/app.png
            DESTINATION share/icons/hicolor/512x512/apps
            RENAME jingo.png
            COMPONENT applications)

    # 安装 SVG 图标（如果存在）
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.svg")
        install(FILES resources/icons/app.svg
                DESTINATION share/icons/hicolor/scalable/apps
                RENAME jingo.svg
                COMPONENT applications)
    endif()

    # 安装 pixmaps（兼容旧系统）
    install(FILES resources/icons/app.png
            DESTINATION share/pixmaps
            RENAME jingo.png
            COMPONENT applications)

    message(STATUS "✓ Linux desktop integration configured:")
    message(STATUS "  - Desktop file will be installed to share/applications/")
    message(STATUS "  - Icon will be installed to share/icons/hicolor/")
    message(STATUS "  - Pixmap will be installed to share/pixmaps/")
endif()

# ============================================================================
# 打印配置信息
# ============================================================================

message(STATUS "")
message(STATUS "========================================")
message(STATUS "JinGoVPN Configuration Summary")
message(STATUS "========================================")
message(STATUS "  Version:           ${PROJECT_VERSION}")
message(STATUS "  Platform:          ${PLATFORM_NAME}")
message(STATUS "  Build Type:        ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ Standard:      C++${CMAKE_CXX_STANDARD}")
message(STATUS "  Qt Version:        ${Qt6_VERSION}")
message(STATUS "  Install Prefix:    ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")
message(STATUS "Libraries:")
message(STATUS "  SuperRay:          ${SUPERRAY_ROOT}")
message(STATUS "")
message(STATUS "Features:")
if(TARGET_ANDROID)
    message(STATUS "  Android API:       ${ANDROID_MIN_SDK_VERSION} - ${ANDROID_TARGET_SDK_VERSION}")
endif()
if(APPLE AND NOT ANDROID)
    if(BUILD_NETWORK_EXTENSION)
        message(STATUS "  Network Extension: Enabled")
    else()
        message(STATUS "  Network Extension: Disabled")
    endif()
endif()
message(STATUS "  Tests:             ${BUILD_TESTS}")
message(STATUS "  Documentation:     ${BUILD_DOCS}")
message(STATUS "  Packaging:         ${ENABLE_PACKAGING}")
message(STATUS "========================================")
message(STATUS "")

# ============================================================================
# Finalize Qt target (IMPORTANT for iOS/Android to auto-import QML plugins)
# ============================================================================
if(TARGET_IOS OR TARGET_ANDROID)
    qt_finalize_target(JinGo)
    message(STATUS "Qt target finalized for mobile platform")
endif()
