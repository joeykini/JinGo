// src/platform/PlatformInterface.cpp
#include "PlatformInterface.h"
#include <QDebug>

// 根据平台包含对应的头文件
#if defined(Q_OS_WIN)
#include "WindowsPlatform.h"
#elif defined(Q_OS_MACOS)
#include "MacOSPlatform.h"
#elif defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
#include "LinuxPlatform.h"
#elif defined(Q_OS_ANDROID)
#include "AndroidPlatform.h"
#elif defined(Q_OS_IOS)
#include "IOSPlatform.h"
#endif

// ============================================================================
// 工厂方法 - 创建平台特定实例
// ============================================================================
PlatformInterface* PlatformInterface::create(QObject* parent)
{
#if defined(Q_OS_WIN)
    return new WindowsPlatform(parent);

#elif defined(Q_OS_MACOS)
    return new MacOSPlatform(parent);

#elif defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    return new LinuxPlatform(parent);

#elif defined(Q_OS_ANDROID)
    return new AndroidPlatform(parent);

#elif defined(Q_OS_IOS)
    return new IOSPlatform(parent);

#else
    // 不支持的平台
    qWarning() << "Unsupported platform! No TUN support available.";
    return nullptr;
#endif
}
