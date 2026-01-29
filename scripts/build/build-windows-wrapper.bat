@echo off
REM ============================================================================
REM JinGo VPN - Windows Build Wrapper Script
REM ============================================================================
REM This script provides a native batch file interface for building JinGo
REM It wraps the PowerShell build script with proper environment detection
REM ============================================================================

setlocal enabledelayedexpansion

REM ============================================================================
REM Color codes for output (if supported)
REM ============================================================================
set "ESC="
set "RESET=%ESC%[0m"
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "CYAN=%ESC%[36m"

REM ============================================================================
REM Parse command line arguments
REM ============================================================================
set CLEAN_BUILD=
set BUILD_TYPE=Release
set SHOW_HELP=
set TRANSLATIONS_ONLY=

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--clean" set CLEAN_BUILD=-Clean
if /i "%~1"=="-c" set CLEAN_BUILD=-Clean
if /i "%~1"=="--debug" set BUILD_TYPE=Debug
if /i "%~1"=="-d" set BUILD_TYPE=Debug
if /i "%~1"=="--help" set SHOW_HELP=1
if /i "%~1"=="-h" set SHOW_HELP=1
if /i "%~1"=="--translations" set TRANSLATIONS_ONLY=-TranslationsOnly
if /i "%~1"=="-t" set TRANSLATIONS_ONLY=-TranslationsOnly
shift
goto :parse_args
:args_done

REM ============================================================================
REM Show help if requested
REM ============================================================================
if defined SHOW_HELP (
    echo.
    echo JinGo Windows Build Wrapper
    echo =============================
    echo.
    echo Usage: %~nx0 [OPTIONS]
    echo.
    echo Options:
    echo   --clean, -c        Clean build directory before building
    echo   --debug, -d        Build in Debug mode (default: Release^)
    echo   --translations, -t Build translations only
    echo   --help, -h         Show this help message
    echo.
    echo Environment Variables:
    echo   QT_DIR             Qt installation directory (default: D:\Qt\6.10.0\mingw_64^)
    echo   MINGW_DIR          MinGW installation directory (default: D:\Qt\Tools\mingw1310_64^)
    echo.
    echo Examples:
    echo   %~nx0                    Build in Release mode
    echo   %~nx0 --clean            Clean build and rebuild
    echo   %~nx0 --debug            Build in Debug mode
    echo   %~nx0 --clean --debug    Clean build in Debug mode
    echo   %~nx0 --translations     Build translations only
    echo.
    exit /b 0
)

REM ============================================================================
REM Print header
REM ============================================================================
echo.
echo ============================================================================
echo JinGo VPN - Windows Build Script
echo ============================================================================
echo.

REM ============================================================================
REM Check PowerShell availability
REM ============================================================================
echo [1/5] Checking PowerShell...
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set POWERSHELL=pwsh
    echo [OK] PowerShell Core found
) else (
    where powershell >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        set POWERSHELL=powershell
        echo [OK] Windows PowerShell found
    ) else (
        echo [ERROR] PowerShell not found! Please install PowerShell.
        exit /b 1
    )
)
echo.

REM ============================================================================
REM Detect Qt and MinGW paths
REM ============================================================================
echo [2/5] Detecting build environment...

REM Qt directory
if not defined QT_DIR (
    REM Try common locations (优先尝试 6.10.1，然后 6.10.0)
    if exist "D:\Qt\6.10.1\mingw_64" (
        set "QT_DIR=D:\Qt\6.10.1\mingw_64"
    ) else if exist "D:\Qt\6.10.0\mingw_64" (
        set "QT_DIR=D:\Qt\6.10.0\mingw_64"
    ) else if exist "C:\Qt\6.10.1\mingw_64" (
        set "QT_DIR=C:\Qt\6.10.1\mingw_64"
    ) else if exist "C:\Qt\6.10.0\mingw_64" (
        set "QT_DIR=C:\Qt\6.10.0\mingw_64"
    ) else if exist "%USERPROFILE%\Qt\6.10.1\mingw_64" (
        set "QT_DIR=%USERPROFILE%\Qt\6.10.1\mingw_64"
    ) else if exist "%USERPROFILE%\Qt\6.10.0\mingw_64" (
        set "QT_DIR=%USERPROFILE%\Qt\6.10.0\mingw_64"
    ) else (
        echo [WARNING] Qt not found in default locations
        echo Please set QT_DIR environment variable
    )
)

REM MinGW directory
if not defined MINGW_DIR (
    REM Try common locations (优先 Qt Tools 下的 MinGW)
    if exist "D:\Qt\Tools\mingw1400_64" (
        set "MINGW_DIR=D:\Qt\Tools\mingw1400_64"
    ) else if exist "D:\Qt\Tools\mingw1310_64" (
        set "MINGW_DIR=D:\Qt\Tools\mingw1310_64"
    ) else if exist "D:\Qt\Tools\mingw1120_64" (
        set "MINGW_DIR=D:\Qt\Tools\mingw1120_64"
    ) else if exist "C:\Qt\Tools\mingw1400_64" (
        set "MINGW_DIR=C:\Qt\Tools\mingw1400_64"
    ) else if exist "C:\Qt\Tools\mingw1310_64" (
        set "MINGW_DIR=C:\Qt\Tools\mingw1310_64"
    ) else if exist "C:\Qt\Tools\mingw1120_64" (
        set "MINGW_DIR=C:\Qt\Tools\mingw1120_64"
    ) else if exist "%USERPROFILE%\Qt\Tools\mingw1400_64" (
        set "MINGW_DIR=%USERPROFILE%\Qt\Tools\mingw1400_64"
    ) else if exist "%USERPROFILE%\Qt\Tools\mingw1310_64" (
        set "MINGW_DIR=%USERPROFILE%\Qt\Tools\mingw1310_64"
    ) else if exist "%USERPROFILE%\Qt\Tools\mingw1120_64" (
        set "MINGW_DIR=%USERPROFILE%\Qt\Tools\mingw1120_64"
    ) else (
        echo [WARNING] MinGW not found in default locations
        echo Please set MINGW_DIR environment variable
    )
)

REM Verify paths
if defined QT_DIR (
    if exist "%QT_DIR%\bin\qmake.exe" (
        echo [OK] Qt found: %QT_DIR%
    ) else (
        echo [ERROR] Qt directory exists but qmake not found: %QT_DIR%
        exit /b 1
    )
) else (
    echo [ERROR] Qt directory not found
    exit /b 1
)

if defined MINGW_DIR (
    if exist "%MINGW_DIR%\bin\gcc.exe" (
        echo [OK] MinGW found: %MINGW_DIR%
    ) else (
        echo [ERROR] MinGW directory exists but gcc not found: %MINGW_DIR%
        exit /b 1
    )
) else (
    echo [ERROR] MinGW directory not found
    exit /b 1
)
echo.

REM ============================================================================
REM Check CMake
REM ============================================================================
echo [3/5] Checking CMake...

REM Check if cmake is in PATH
where cmake >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=3" %%i in ('cmake --version ^| findstr /r "^cmake"') do set CMAKE_VERSION=%%i
    echo [OK] CMake %CMAKE_VERSION% found in PATH
) else (
    REM Try Qt's bundled CMake
    set "QT_CMAKE="
    if exist "D:\Qt\Tools\CMake_64\bin\cmake.exe" (
        set "QT_CMAKE=D:\Qt\Tools\CMake_64\bin"
    ) else if exist "C:\Qt\Tools\CMake_64\bin\cmake.exe" (
        set "QT_CMAKE=C:\Qt\Tools\CMake_64\bin"
    ) else if exist "%USERPROFILE%\Qt\Tools\CMake_64\bin\cmake.exe" (
        set "QT_CMAKE=%USERPROFILE%\Qt\Tools\CMake_64\bin"
    )

    if defined QT_CMAKE (
        set "PATH=%QT_CMAKE%;%PATH%"
        for /f "tokens=3" %%i in ('"%QT_CMAKE%\cmake.exe" --version ^| findstr /r "^cmake"') do set CMAKE_VERSION=%%i
        echo [OK] CMake %CMAKE_VERSION% found in Qt Tools
    ) else (
        echo [ERROR] CMake not found! Please install CMake.
        echo   Download from: https://cmake.org/download/
        echo   Or install via: winget install Kitware.CMake
        exit /b 1
    )
)
echo.

REM ============================================================================
REM Navigate to project root
REM ============================================================================
echo [4/5] Navigating to project root...
cd /d "%~dp0..\.."
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to navigate to project root
    exit /b 1
)
echo [OK] Project root: %CD%
echo.

REM ============================================================================
REM Build information
REM ============================================================================
echo [5/5] Build configuration:
echo   Build Type: %BUILD_TYPE%
if defined CLEAN_BUILD (
    echo   Clean Build: Yes
) else (
    echo   Clean Build: No
)
if defined TRANSLATIONS_ONLY (
    echo   Translations Only: Yes
)
echo.

REM ============================================================================
REM Execute PowerShell build script
REM ============================================================================
echo ============================================================================
echo Starting build process...
echo ============================================================================
echo.

REM Prepare PowerShell arguments
set PS_ARGS=
if defined CLEAN_BUILD set PS_ARGS=%PS_ARGS% %CLEAN_BUILD%
if "%BUILD_TYPE%"=="Debug" set PS_ARGS=%PS_ARGS% -DebugBuild
if defined TRANSLATIONS_ONLY set PS_ARGS=%PS_ARGS% %TRANSLATIONS_ONLY%

REM Execute PowerShell script
%POWERSHELL% -ExecutionPolicy Bypass -File "%~dp0build-windows.ps1" %PS_ARGS%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================================================
    echo [ERROR] Build failed! Exit code: %ERRORLEVEL%
    echo ============================================================================
    exit /b %ERRORLEVEL%
)

REM ============================================================================
REM Build successful
REM ============================================================================
echo.
echo ============================================================================
echo [SUCCESS] Build completed successfully!
echo ============================================================================
echo.
echo Output location: build-windows\bin\JinGo.exe
echo.

REM Check if package was created
if exist "pkg\*.zip" (
    echo Deployment package created:
    dir /b pkg\*.zip
    echo.
)

echo To run the application:
echo   build-windows\bin\JinGo.exe
echo.
echo ============================================================================

endlocal
exit /b 0
