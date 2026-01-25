# ============================================================================
# Platform-Windows.cmake - Windows Platform Configuration
# ============================================================================
# This module handles:
# - Windows-specific source files
# - Windows system libraries
# - Windows resource file (.rc) configuration
# - MSVC compiler settings
# - Windows icon generation from PNG
# - Windows manifest for admin privileges
#
# Usage:
#   if(TARGET_WINDOWS)
#       include(cmake/Platform-Windows.cmake)
#   endif()
#
# Variables set by this module:
#   PLATFORM_NAME - "Windows"
#   PLATFORM_SOURCES - Windows-specific source files
#   PLATFORM_LIBS - Windows system libraries
#   PLATFORM_RC - Windows resource file (.rc)
# ============================================================================

if(NOT TARGET_WINDOWS)
    message(WARNING "Platform-Windows.cmake included but TARGET_WINDOWS is not set")
    return()
endif()

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Configuring Windows Platform")
message(STATUS "========================================")

# ============================================================================
# Windows Platform Configuration
# ============================================================================

set(PLATFORM_NAME "Windows")

# ============================================================================
# Windows Source Files
# ============================================================================

set(PLATFORM_SOURCES
    src/platform/PlatformInterface.cpp
    src/platform/WindowsPlatform.cpp
    src/platform/windows/WinTunManager.cpp
    src/platform/windows/WinTunDriverInstaller.cpp
    src/utils/RsaCrypto_windows.cpp
)

message(STATUS "Windows source files configured:")
foreach(source ${PLATFORM_SOURCES})
    message(STATUS "  - ${source}")
endforeach()

# ============================================================================
# Windows System Libraries
# ============================================================================

set(PLATFORM_LIBS
    wininet
    advapi32
    iphlpapi
    ws2_32
    crypt32
    bcrypt
    ncrypt
    netapi32
    shlwapi
)

message(STATUS "Windows system libraries:")
foreach(lib ${PLATFORM_LIBS})
    message(STATUS "  - ${lib}")
endforeach()

# ============================================================================
# Windows Icon Generation
# ============================================================================

set(APP_PNG "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.png")
set(APP_ICO "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.ico")
set(ICON_GENERATOR "${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/generate_icon.py")

if(EXISTS ${APP_PNG} AND EXISTS ${ICON_GENERATOR})
    if(NOT EXISTS ${APP_ICO})
        message(STATUS "Generating app.ico from app.png...")
        find_package(Python3 COMPONENTS Interpreter)
        if(Python3_FOUND)
            execute_process(
                COMMAND ${Python3_EXECUTABLE} ${ICON_GENERATOR} ${APP_PNG} ${APP_ICO}
                RESULT_VARIABLE ICON_GEN_RESULT
                OUTPUT_VARIABLE ICON_GEN_OUTPUT
                ERROR_VARIABLE ICON_GEN_ERROR
            )
            if(ICON_GEN_RESULT EQUAL 0)
                message(STATUS " app.ico generated successfully")
            else()
                message(WARNING "Failed to generate app.ico: ${ICON_GEN_ERROR}")
                message(WARNING "The executable will not have an icon. Install Pillow with: pip install Pillow")
            endif()
        else()
            message(WARNING "Python3 not found. Cannot auto-generate app.ico")
            message(WARNING "Please install Python3 or manually create resources/icons/app.ico")
        endif()
    else()
        message(STATUS " app.ico already exists")
    endif()
endif()

# ============================================================================
# Windows Resource File (.rc)
# ============================================================================

# Use minimal RC file (only manifest, avoids windres command line overflow)
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/JinGo.rc)
    set(PLATFORM_RC ${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/JinGo.rc)
    message(STATUS " Using JinGo.rc with admin manifest")
else()
    set(PLATFORM_RC "")
    message(WARNING "JinGo.rc not found - executable will not have manifest")
endif()

# ============================================================================
# Windows Compiler Definitions
# ============================================================================

add_compile_definitions(
    WINVER=0x0A00              # Windows 10
    _WIN32_WINNT=0x0A00        # Windows 10
    _CRT_SECURE_NO_WARNINGS    # Disable CRT security warnings
    NOMINMAX                   # Prevent min/max macro conflicts
    WIN32_LEAN_AND_MEAN        # Exclude rarely-used Windows headers
)

message(STATUS "Windows compiler definitions:")
message(STATUS "  - WINVER=0x0A00 (Windows 10)")
message(STATUS "  - _WIN32_WINNT=0x0A00")
message(STATUS "  - _CRT_SECURE_NO_WARNINGS")
message(STATUS "  - NOMINMAX")
message(STATUS "  - WIN32_LEAN_AND_MEAN")

# ============================================================================
# Verification
# ============================================================================

message(STATUS "Verifying Windows platform source files:")
foreach(platform_source ${PLATFORM_SOURCES})
    set(full_path ${CMAKE_CURRENT_SOURCE_DIR}/${platform_source})
    if(NOT EXISTS ${full_path})
        message(WARNING "  Windows source file not found: ${platform_source}")
        list(REMOVE_ITEM PLATFORM_SOURCES ${platform_source})
    else()
        message(STATUS "   ${platform_source}")
    endif()
endforeach()

message(STATUS "Windows platform configured successfully")
message(STATUS "========================================")
message(STATUS "")
