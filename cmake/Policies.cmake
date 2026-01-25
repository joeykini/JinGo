# ============================================================================
# CMake Policies Configuration
# ============================================================================

# CMP0071: Let AUTOMOC and AUTOUIC process GENERATED files
if(POLICY CMP0071)
    cmake_policy(SET CMP0071 NEW)
endif()

# CMP0100: Let AUTOMOC and AUTOUIC process .hh files
if(POLICY CMP0100)
    cmake_policy(SET CMP0100 NEW)
endif()

# CMP0143: USE_FOLDERS global property is treated as ON by default
if(POLICY CMP0143)
    cmake_policy(SET CMP0143 NEW)
endif()

# CMP0167: Use FETCHCONTENT_TRY_FIND_PACKAGE_MODE by default
if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

# CMP0157: Swift_COMPILATION_MODE default for Ninja generators is WholeModule
# Also affects -no_warn_duplicate_libraries on Apple (CMake 3.29+)
if(POLICY CMP0157)
    cmake_policy(SET CMP0157 OLD)
endif()

# Workaround for CMake 3.29+ adding -no_warn_duplicate_libraries which Xcode clang doesn't understand
if(APPLE AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.29")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
    # Remove the flag if it was added
    string(REPLACE "-Wl,-no_warn_duplicate_libraries" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
    string(REPLACE "-Wl,-no_warn_duplicate_libraries" "" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
endif()

# Qt Policy QTP0002 - Android deployment paths in JSON
# This policy is set after find_package(Qt6) in Dependencies-Qt.cmake
