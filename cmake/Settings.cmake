# ============================================================================
# h@�n���
# ============================================================================

# ============================================================================
# �s��K(���a�$�	
# ============================================================================
# �In��s���M��;:s���s�
set(TARGET_MACOS OFF)
set(TARGET_IOS OFF)
set(TARGET_ANDROID OFF)
set(TARGET_WINDOWS OFF)
set(TARGET_LINUX OFF)

if(ANDROID)
    set(TARGET_ANDROID ON)
    message(STATUS " Target platform: Android (${ANDROID_ABI})")
elseif(IOS)
    set(TARGET_IOS ON)
    message(STATUS " Target platform: iOS")
elseif(APPLE)
    set(TARGET_MACOS ON)
    message(STATUS " Target platform: macOS")
elseif(WIN32)
    set(TARGET_WINDOWS ON)
    message(STATUS " Target platform: Windows")
elseif(UNIX)
    set(TARGET_LINUX ON)
    message(STATUS " Target platform: Linux")
endif()

# ============================================================================
# C++ƾn
# ============================================================================
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# MSVC specific: Enable correct __cplusplus macro value
if(MSVC)
    add_compile_options(/Zc:__cplusplus)
endif()

# ============================================================================
# Qt��w
# ============================================================================
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# ============================================================================
# ���UMn
# ============================================================================
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# ============================================================================
# AndroidH,Mn
# ============================================================================
set(ANDROID_MIN_SDK_VERSION 28)
set(ANDROID_TARGET_SDK_VERSION 35)
set(ANDROID_COMPILE_SDK_VERSION 35)
set(ANDROID_BUILD_TOOLS_VERSION "35.0.0")

# ============================================================================
# ��{�
# ============================================================================
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()
