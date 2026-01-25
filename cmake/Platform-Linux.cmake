# ============================================================================
# Platform-Linux.cmake - Linux Platform Configuration
# ============================================================================
# This module handles:
# - Linux-specific source files
# - Linux system libraries (libsecret, dl, pthread)
# - Linux distribution detection
# - Desktop file configuration
# - TUN device support
#
# Usage:
#   if(TARGET_LINUX)
#       include(cmake/Platform-Linux.cmake)
#   endif()
#
# Variables set by this module:
#   PLATFORM_NAME - "Linux"
#   PLATFORM_SOURCES - Linux-specific source files
#   PLATFORM_LIBS - Linux system libraries
#   HAVE_LIBSECRET - Defined if libsecret is found
# ============================================================================

if(NOT TARGET_LINUX)
    message(WARNING "Platform-Linux.cmake included but TARGET_LINUX is not set")
    return()
endif()

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Configuring Linux Platform")
message(STATUS "========================================")

# ============================================================================
# Linux Platform Configuration
# ============================================================================

set(PLATFORM_NAME "Linux")

# ============================================================================
# Linux Source Files
# ============================================================================

set(PLATFORM_SOURCES
    src/platform/PlatformInterface.cpp
    src/platform/LinuxPlatform.cpp
    src/platform/linux/LinuxTunManager.cpp
)

message(STATUS "Linux source files configured:")
foreach(source ${PLATFORM_SOURCES})
    message(STATUS "  - ${source}")
endforeach()

# ============================================================================
# Linux System Libraries - libsecret for Secure Storage
# ============================================================================

find_package(PkgConfig REQUIRED)

# Find glib-2.0 (required by libsecret and JinDoCore)
pkg_check_modules(GLIB2 glib-2.0)
if(GLIB2_FOUND)
    include_directories(${GLIB2_INCLUDE_DIRS})
    link_directories(${GLIB2_LIBRARY_DIRS})
    set(PLATFORM_LIBS ${GLIB2_LIBRARIES})
    message(STATUS "glib-2.0 found: ${GLIB2_VERSION}")
    message(STATUS "  Include dirs: ${GLIB2_INCLUDE_DIRS}")
    message(STATUS "  Libraries: ${GLIB2_LIBRARIES}")
else()
    message(WARNING "glib-2.0 not found")
    message(WARNING "  Install with: sudo apt install libglib2.0-dev (Debian/Ubuntu)")
    set(PLATFORM_LIBS "")
endif()

# Find libsecret (for Secure Storage)
pkg_check_modules(LIBSECRET libsecret-1)

if(LIBSECRET_FOUND)
    include_directories(${LIBSECRET_INCLUDE_DIRS})
    link_directories(${LIBSECRET_LIBRARY_DIRS})
    list(APPEND PLATFORM_LIBS ${LIBSECRET_LIBRARIES})
    add_compile_definitions(HAVE_LIBSECRET)
    message(STATUS "libsecret found: ${LIBSECRET_VERSION}")
    message(STATUS "  Include dirs: ${LIBSECRET_INCLUDE_DIRS}")
    message(STATUS "  Library dirs: ${LIBSECRET_LIBRARY_DIRS}")
    message(STATUS "  Libraries: ${LIBSECRET_LIBRARIES}")
else()
    message(WARNING "libsecret not found, secure storage will use fallback")
    message(WARNING "  Install with: sudo apt install libsecret-1-dev (Debian/Ubuntu)")
    message(WARNING "             or: sudo dnf install libsecret-devel (Fedora/RHEL)")
endif()

# Add standard Linux libraries
list(APPEND PLATFORM_LIBS dl pthread)

message(STATUS "Linux platform libraries:")
foreach(lib ${PLATFORM_LIBS})
    message(STATUS "  - ${lib}")
endforeach()

# ============================================================================
# Linux Distribution Detection (for packaging)
# ============================================================================

if(EXISTS "/etc/os-release")
    file(STRINGS "/etc/os-release" OS_RELEASE_CONTENTS)
    foreach(line ${OS_RELEASE_CONTENTS})
        if(line MATCHES "^ID=(.+)")
            set(LINUX_DISTRO_ID "${CMAKE_MATCH_1}")
            string(REPLACE "\"" "" LINUX_DISTRO_ID "${LINUX_DISTRO_ID}")
        endif()
        if(line MATCHES "^VERSION_ID=(.+)")
            set(LINUX_DISTRO_VERSION "${CMAKE_MATCH_1}")
            string(REPLACE "\"" "" LINUX_DISTRO_VERSION "${LINUX_DISTRO_VERSION}")
        endif()
    endforeach()

    if(DEFINED LINUX_DISTRO_ID)
        message(STATUS "Linux distribution: ${LINUX_DISTRO_ID}")
        if(DEFINED LINUX_DISTRO_VERSION)
            message(STATUS "  Version: ${LINUX_DISTRO_VERSION}")
        endif()
    endif()
endif()

# ============================================================================
# Linux Desktop File Configuration
# ============================================================================

set(LINUX_DESKTOP_FILE "${CMAKE_CURRENT_SOURCE_DIR}/platform/linux/jingo.desktop")
if(EXISTS "${LINUX_DESKTOP_FILE}")
    message(STATUS "Linux desktop file: ${LINUX_DESKTOP_FILE}")
    # Desktop file will be installed during install phase
else()
    message(WARNING "Linux desktop file not found: ${LINUX_DESKTOP_FILE}")
endif()

# ============================================================================
# Verification
# ============================================================================

message(STATUS "Verifying Linux platform source files:")
foreach(platform_source ${PLATFORM_SOURCES})
    set(full_path ${CMAKE_CURRENT_SOURCE_DIR}/${platform_source})
    if(NOT EXISTS ${full_path})
        message(WARNING "  Linux source file not found: ${platform_source}")
        list(REMOVE_ITEM PLATFORM_SOURCES ${platform_source})
    else()
        message(STATUS "   ${platform_source}")
    endif()
endforeach()

# ============================================================================
# Linux OpenSSL 3.0.7 Libraries
# ============================================================================

set(LINUX_OPENSSL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/linux_openssl")
set(LINUX_OPENSSL_LIB_DIR "${LINUX_OPENSSL_DIR}/x86_64")
set(LINUX_OPENSSL_INCLUDE_DIR "${LINUX_OPENSSL_DIR}/include")

if(EXISTS "${LINUX_OPENSSL_LIB_DIR}")
    message(STATUS "Linux OpenSSL 3.0.7 libraries found: ${LINUX_OPENSSL_LIB_DIR}")

    # Create lib directory in build output
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin/lib")

    # Copy OpenSSL libraries to build/bin/lib
    file(GLOB OPENSSL_LIBS "${LINUX_OPENSSL_LIB_DIR}/libssl.so*" "${LINUX_OPENSSL_LIB_DIR}/libcrypto.so*")
    foreach(lib ${OPENSSL_LIBS})
        get_filename_component(lib_name ${lib} NAME)
        configure_file(${lib} "${CMAKE_BINARY_DIR}/bin/lib/${lib_name}" COPYONLY)
        message(STATUS "  Copied: ${lib_name}")
    endforeach()

    message(STATUS "OpenSSL 3.0.7 libraries deployed to build/bin/lib/")
else()
    message(WARNING "Linux OpenSSL 3.0.7 libraries not found at: ${LINUX_OPENSSL_LIB_DIR}")
    message(WARNING "  TLS connections may fail. Please build OpenSSL 3.0.7 and place in third_party/linux_openssl/x86_64/")
endif()


# ============================================================================
# End of Linux Platform Configuration
# ============================================================================

message(STATUS "Linux platform configured with TUN and VPN bridge support")
message(STATUS "========================================")
message(STATUS "")
