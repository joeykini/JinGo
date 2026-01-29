# ============================================================================
# Toolchain-MinGW.cmake - MinGW Toolchain Configuration for Windows
# ============================================================================
# This toolchain file forces CMake to use MinGW instead of MSVC on Windows
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=cmake/Toolchain-MinGW.cmake ..
# ============================================================================

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)

# Set MinGW paths
set(MINGW_ROOT "D:/Qt/Tools/mingw1310_64" CACHE PATH "MinGW installation directory")

# Set compilers
set(CMAKE_C_COMPILER "${MINGW_ROOT}/bin/gcc.exe")
set(CMAKE_CXX_COMPILER "${MINGW_ROOT}/bin/g++.exe")
set(CMAKE_RC_COMPILER "${MINGW_ROOT}/bin/windres.exe")

# Set make tool
set(CMAKE_MAKE_PROGRAM "${MINGW_ROOT}/bin/mingw32-make.exe" CACHE PATH "MinGW make program")

# Search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH "${MINGW_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

message(STATUS "✓ MinGW Toolchain configured")
message(STATUS "  MinGW Root: ${MINGW_ROOT}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "  RC Compiler: ${CMAKE_RC_COMPILER}")
message(STATUS "  Make: ${CMAKE_MAKE_PROGRAM}")
