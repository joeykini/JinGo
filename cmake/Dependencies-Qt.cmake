# ============================================================================
# Dependencies-Qt.cmake - Qt6 Dependencies Configuration
# ============================================================================
# This module handles:
# - Qt6 package discovery (Core, Gui, Widgets, Qml, Quick, etc.)
# - Qt policies (QTP0002 for Android)
# - Platform-specific Qt components (DBus for Linux)
#
# Usage:
#   include(cmake/Dependencies-Qt.cmake)
#
# Variables set by this module:
#   Qt6_FOUND - Whether Qt6 was found
#   Qt6_VERSION - Qt6 version
# ============================================================================

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Configuring Qt6 Dependencies")
message(STATUS "========================================")

# ============================================================================
# Find Qt6 Required Components
# ============================================================================

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Qml
    Quick
    QuickControls2
    Network
    Sql
    Concurrent
    LinguistTools
)

message(STATUS "Qt6 found: ${Qt6_VERSION}")
message(STATUS "  Qt6_DIR: ${Qt6_DIR}")

# ============================================================================
# Platform-Specific Qt Components
# ============================================================================

if(TARGET_LINUX)
    find_package(Qt6 COMPONENTS DBus)
    if(Qt6DBus_FOUND)
        message(STATUS "  Qt6 DBus: ${Qt6DBus_VERSION}")
    else()
        message(WARNING "  Qt6 DBus not found - D-Bus integration disabled")
    endif()
endif()

# ============================================================================
# Qt Custom Policies (Must be set AFTER find_package(Qt6))
# ============================================================================

if(TARGET_ANDROID)
    # QTP0002: Android deployment paths with generator expressions must be valid JSON
    # Reference: https://doc.qt.io/qt-6/qt-cmake-policy-qtp0002.html
    # This prevents deployment errors related to JSON formatting in Android builds
    if(COMMAND qt_policy)
        qt_policy(SET QTP0002 NEW)
        message(STATUS "  Qt Policy QTP0002: NEW (Android JSON deployment paths)")
    elseif(COMMAND qt6_policy)
        qt6_policy(SET QTP0002 NEW)
        message(STATUS "  Qt Policy QTP0002: NEW (Android JSON deployment paths)")
    else()
        message(WARNING "  Qt policy commands not available - QTP0002 not set")
    endif()
endif()

message(STATUS "Qt6 dependencies configured successfully")
message(STATUS "========================================")
message(STATUS "")
