# ============================================================================
# Platform-Android.cmake - Android Platform Configuration
# ============================================================================
# This module configures Android-specific settings and toolchain.
# IMPORTANT: Must be included BEFORE project() command.

# Android SDK and NDK paths (使用环境变量或默认值)
if(NOT ANDROID_SDK_ROOT)
    if(DEFINED ENV{ANDROID_SDK_ROOT})
        set(ANDROID_SDK_ROOT "$ENV{ANDROID_SDK_ROOT}" CACHE PATH "Android SDK path")
    else()
        set(ANDROID_SDK_ROOT "/Volumes/mindata/Library/Android/aarch64/sdk" CACHE PATH "Android SDK path")
    endif()
endif()

if(NOT ANDROID_NDK)
    if(DEFINED ENV{ANDROID_NDK})
        set(ANDROID_NDK "$ENV{ANDROID_NDK}" CACHE PATH "Android NDK path")
    else()
        set(ANDROID_NDK "${ANDROID_SDK_ROOT}/ndk/27.2.12479018" CACHE PATH "Android NDK path")
    endif()
endif()

set(CMAKE_TOOLCHAIN_FILE "${ANDROID_NDK}/build/cmake/android.toolchain.cmake" CACHE FILEPATH "Android toolchain file")

# Android ABI (arm64-v8a, armeabi-v7a, x86, x86_64)
if(NOT DEFINED ANDROID_ABI)
    set(ANDROID_ABI "arm64-v8a" CACHE STRING "Android ABI")
endif()

# Ensure CMAKE_ANDROID_ARCH_ABI matches ANDROID_ABI
set(CMAKE_ANDROID_ARCH_ABI "${ANDROID_ABI}" CACHE STRING "Android architecture ABI")

# Android platform version (API level)
if(NOT DEFINED ANDROID_PLATFORM)
    set(ANDROID_PLATFORM "android-28" CACHE STRING "Android platform version")
endif()

# Qt configuration for Android (优先使用环境变量)
if(NOT QT_HOST_PATH)
    if(DEFINED ENV{QT_HOST_PATH})
        set(QT_HOST_PATH "$ENV{QT_HOST_PATH}" CACHE PATH "Qt host tools path")
    else()
        # 默认值 (macOS 开发环境)
        set(QT_HOST_PATH "/Volumes/mindata/Applications/Qt/6.10.0/macos" CACHE PATH "Qt host tools path")
    endif()
endif()

if(NOT CMAKE_PREFIX_PATH)
    if(DEFINED ENV{QT_BASE_PATH})
        set(CMAKE_PREFIX_PATH "$ENV{QT_BASE_PATH}/android_arm64_v8a" CACHE PATH "Qt Android libraries path")
    else()
        set(CMAKE_PREFIX_PATH "/Volumes/mindata/Applications/Qt/6.10.0/android_arm64_v8a" CACHE PATH "Qt Android libraries path")
    endif()
endif()

set(CMAKE_FIND_ROOT_PATH "${CMAKE_PREFIX_PATH}" CACHE PATH "CMake find root path")

# OpenSSL configuration for Android
set(ANDROID_OPENSSL_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/android_openssl" CACHE PATH "Android OpenSSL path")

if(EXISTS "${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}")
    # 设置 ANDROID_EXTRA_LIBS 用于APK打包
    # Qt需要 libssl_3.so 和 libcrypto_3.so 来识别OpenSSL 3.x
    set(ANDROID_EXTRA_LIBS
        "${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}/libcrypto_3.so"
        "${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}/libssl_3.so"
        CACHE STRING "Extra libraries to bundle in APK"
    )

    message(STATUS "Android OpenSSL: ${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}")
    message(STATUS "  libcrypto_3.so: ${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}/libcrypto_3.so")
    message(STATUS "  libssl_3.so: ${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}/libssl_3.so")
else()
    message(WARNING "Android OpenSSL not found: ${ANDROID_OPENSSL_ROOT}/${ANDROID_ABI}")
endif()

message(STATUS "Android SDK: ${ANDROID_SDK_ROOT}")
message(STATUS "Android NDK: ${ANDROID_NDK}")
message(STATUS "Android ABI: ${ANDROID_ABI}")
message(STATUS "Android Platform: ${ANDROID_PLATFORM}")
message(STATUS "Qt Host Path: ${QT_HOST_PATH}")
message(STATUS "Qt Android Path: ${CMAKE_PREFIX_PATH}")

# ============================================================================
# Android Platform Sources
# ============================================================================

set(PLATFORM_SOURCES
    src/platform/PlatformInterface.cpp
    src/platform/AndroidPlatform.cpp
    src/platform/AndroidVpnHelper.cpp
    src/platform/AndroidStatusBarManager.cpp
)

message(STATUS "Android platform sources configured:")
foreach(source ${PLATFORM_SOURCES})
    message(STATUS "  - ${source}")
endforeach()
