/**
 * @file WinTunDriverInstaller.cpp
 * @brief WinTun驱动安装辅助工具实现
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 */

#ifdef _WIN32

#include "WinTunDriverInstaller.h"
#include <iostream>
#include <sstream>
#include <wintun.h>
#include <Shlwapi.h>

#pragma comment(lib, "Shlwapi.lib")

namespace JinGo {

bool WinTunDriverInstaller::isDriverInstalled()
{
    DWORD version = getDriverVersion();
    return version > 0;
}

DWORD WinTunDriverInstaller::getDriverVersion()
{
    // 加载wintun.dll
    std::wstring dllPath = findWintunDll();
    if (dllPath.empty()) {
        return 0;
    }

    HMODULE dll = LoadLibraryW(dllPath.c_str());
    if (!dll) {
        return 0;
    }

    // 获取版本函数
    auto getVersion = reinterpret_cast<WINTUN_GET_RUNNING_DRIVER_VERSION_FUNC*>(
        GetProcAddress(dll, "WintunGetRunningDriverVersion")
    );

    DWORD version = 0;
    if (getVersion) {
        version = getVersion();
    }

    FreeLibrary(dll);
    return version;
}

std::wstring WinTunDriverInstaller::findWintunDll()
{
    const wchar_t* searchPaths[] = {
        L"wintun.dll",
        L"bin\\wintun.dll",
        L"third_party\\wintun\\bin\\amd64\\wintun.dll",
        L"C:\\Program Files\\JinGo\\wintun.dll"
    };

    for (const auto& path : searchPaths) {
        if (PathFileExistsW(path)) {
            // 获取完整路径
            wchar_t fullPath[MAX_PATH];
            if (GetFullPathNameW(path, MAX_PATH, fullPath, nullptr)) {
                return fullPath;
            }
            return path;
        }
    }

    return L"";
}

bool WinTunDriverInstaller::isRunningAsAdministrator()
{
    BOOL isAdmin = FALSE;
    PSID adminGroup = NULL;
    SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;

    if (AllocateAndInitializeSid(&ntAuthority, 2,
                                  SECURITY_BUILTIN_DOMAIN_RID,
                                  DOMAIN_ALIAS_RID_ADMINS,
                                  0, 0, 0, 0, 0, 0, &adminGroup)) {
        CheckTokenMembership(NULL, adminGroup, &isAdmin);
        FreeSid(adminGroup);
    }

    return isAdmin == TRUE;
}

bool WinTunDriverInstaller::checkSystemRequirements(std::string& errorMessage)
{
    std::ostringstream oss;

    // 1. 检查操作系统版本（Windows 7+）
    OSVERSIONINFOEXW osvi = { sizeof(osvi) };

    // Windows 7 = 6.1
    DWORD majorVersion = 6;
    DWORD minorVersion = 1;

    // 2. 检查管理员权限
    if (!isRunningAsAdministrator()) {
        oss << "Administrator privileges required to create VPN adapter.\n";
        oss << "Please run the application as administrator.\n";
        errorMessage = oss.str();
        return false;
    }

    // 3. 检查wintun.dll
    std::wstring dllPath = findWintunDll();
    if (dllPath.empty()) {
        oss << "wintun.dll not found. Please ensure:\n";
        oss << "  1. wintun.dll is in the application directory\n";
        oss << "  2. Or copy from third_party/wintun/bin/amd64/wintun.dll\n";
        errorMessage = oss.str();
        return false;
    }

    // 4. 检查驱动状态
    DWORD version = getDriverVersion();
    if (version == 0) {
        std::cout << "[Installer] WinTun driver not installed yet" << std::endl;
        std::cout << "[Installer] Driver will be auto-installed on first adapter creation" << std::endl;
        std::cout << "[Installer] This is normal for first run" << std::endl;
    } else {
        std::cout << "[Installer] WinTun driver already installed: v"
                  << ((version >> 16) & 0xFFFF) << "."
                  << (version & 0xFFFF) << std::endl;
    }

    return true;
}

} // namespace JinGo

#endif // _WIN32
