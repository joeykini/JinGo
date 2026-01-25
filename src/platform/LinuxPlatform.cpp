// src/platform/LinuxPlatform.cpp

#include "LinuxPlatform.h"
#include "Logger.h"
#include <QProcess>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QSettings>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QUuid>
#include <QSysInfo>
#include <QHostAddress>
#include <QTimer>
#include <unistd.h>

// ============================================================================
// 辅助函数
// ============================================================================

/**
 * 将子网掩码转换为前缀长度
 * @param netmask 子网掩码字符串 (如"255.255.255.0")
 * @return 前缀长度 (如24)
 */
static uint8_t netmaskToPrefixLength(const QString& netmask)
{
    QHostAddress addr(netmask);
    if (addr.isNull()) {
        LOG_WARNING(QString("Invalid netmask: %1, using default /24").arg(netmask));
        return 24;
    }

    // 将子网掩码转换为32位整数,然后计算前缀长度
    quint32 mask = addr.toIPv4Address();
    uint8_t prefixLength = 0;

    // 计算掩码中1的位数
    while (mask) {
        prefixLength += (mask & 1);
        mask >>= 1;
    }

    return prefixLength;
}

// ============================================================================
// 构造和析构
// ============================================================================

LinuxPlatform::LinuxPlatform(QObject* parent)
    : PlatformInterface(parent)
{
    LOG_INFO(QString("OS: %1").arg(osVersion()));
    LOG_DEBUG(QString("Device ID: %1").arg(getDeviceId()));
    LOG_DEBUG(QString("Running as: %1").arg(geteuid() == 0 ? "root" : "user"));

    // 延迟检查 VPN 权限（避免阻塞 UI 初始化）
    QTimer::singleShot(1000, this, [this]() {
        checkAndRequestVPNPermissionIfNeeded();
    });
}

LinuxPlatform::~LinuxPlatform()
{
    LOG_DEBUG("Linux platform destroyed");
}

// ============================================================================
// VPN 权限相关
// ============================================================================

void LinuxPlatform::checkAndRequestVPNPermissionIfNeeded()
{
    LOG_DEBUG("Checking VPN permission status on startup...");

    // 如果已经有权限，无需申请
    if (hasVPNPermission()) {
        LOG_INFO("✓ VPN permissions already available");
        return;
    }

    // 没有权限，自动发起申请
    LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    LOG_INFO("  检测到应用缺少 TUN 模式所需权限");
    LOG_INFO("  正在自动申请 VPN 权限...");
    LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    // 调用权限申请（会弹出 pkexec 授权对话框）
    bool granted = requestVPNPermission();

    if (granted) {
        // 权限授予成功，但需要重启应用
        LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        LOG_INFO("  ✓ 权限授予成功！");
        LOG_INFO("  ⚠️  请重启应用以使用 TUN 模式");
        LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    } else {
        LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        LOG_INFO("  权限申请未完成或被取消");
        LOG_INFO("  提示：TUN 模式需要管理员权限");
        LOG_INFO("       您也可以使用代理模式（无需权限）");
        LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
}

bool LinuxPlatform::requestVPNPermission()
{
    LOG_DEBUG("Requesting VPN permission (Linux)");

    // 1. 检查是否已经有权限
    if (hasVPNPermission()) {
        LOG_DEBUG("VPN permissions already granted");
        return true;
    }

    // 2. 获取应用程序路径
    QString appPath = QCoreApplication::applicationFilePath();
    LOG_INFO(QString("Attempting to grant VPN permissions to: %1").arg(appPath));

    // 3. 尝试使用pkexec自动提升权限
    // pkexec是PolicyKit的图形化授权工具，类似Windows UAC
    QString pkexecPath = "/usr/bin/pkexec";
    QString setcapPath = "/usr/sbin/setcap";

    // 检查pkexec是否可用
    if (!QFile::exists(pkexecPath)) {
        LOG_WARNING("pkexec not found, cannot auto-elevate permissions");
        LOG_WARNING("Please run manually: sudo setcap cap_net_admin+eip " + appPath);
        return false;
    }

    // 检查setcap是否可用
    if (!QFile::exists(setcapPath)) {
        setcapPath = "/sbin/setcap";
        if (!QFile::exists(setcapPath)) {
            LOG_WARNING("setcap not found in system");
            LOG_WARNING("Please install libcap2-bin package");
            return false;
        }
    }

    // 4. 使用pkexec调用setcap授予CAP_NET_ADMIN权限
    LOG_INFO("Requesting administrator permission to grant VPN capabilities...");
    LOG_INFO("A system authorization dialog will appear");

    QProcess process;
    QStringList args;
    // 使用 cap_net_admin+eip：e=Effective, i=Inheritable（TUN模式需要）, p=Permitted
    args << setcapPath << "cap_net_admin+eip" << appPath;

    process.start(pkexecPath, args);

    // 等待用户授权并完成（最多30秒）
    if (!process.waitForFinished(30000)) {
        LOG_WARNING("Permission elevation timed out or was cancelled");
        LOG_WARNING("Please run manually: sudo setcap cap_net_admin+eip " + appPath);
        return false;
    }

    // 5. 检查执行结果
    int exitCode = process.exitCode();
    QString output = QString::fromUtf8(process.readAllStandardOutput());
    QString errorOutput = QString::fromUtf8(process.readAllStandardError());

    if (exitCode != 0) {
        LOG_WARNING(QString("Failed to grant VPN permissions (exit code: %1)").arg(exitCode));
        if (!errorOutput.isEmpty()) {
            LOG_WARNING(QString("Error: %1").arg(errorOutput));
        }
        LOG_WARNING("Fallback: Please run manually:");
        LOG_WARNING("  sudo setcap cap_net_admin+eip " + appPath);
        return false;
    }

    // 6. 权限授予成功，但需要重启应用才能生效
    LOG_INFO("✓ VPN permissions granted successfully!");
    LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    LOG_INFO("  重要提示：需要重启应用才能使用 TUN 模式");
    LOG_INFO("  Please restart the application to use TUN mode");
    LOG_INFO("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    // Linux capabilities 是在进程启动时加载的
    // 新授予的权限需要重新启动进程才能生效

    // 提示用户重启（可以在 UI 中显示友好的对话框）
    // 返回 false 让调用者知道当前进程还没有权限
    return false;
}

bool LinuxPlatform::hasVPNPermission()
{
    LOG_INFO("[DEBUG] hasVPNPermission() called");

    bool isRoot = (geteuid() == 0);

    if (isRoot) {
        LOG_DEBUG("Running with root privileges");
        return true;
    }

    // 检查进程的实际capabilities（而不仅仅是文件capabilities）
    // 读取 /proc/self/status 查看进程的有效capabilities
    QFile statusFile("/proc/self/status");
    if (statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&statusFile);
        while (!in.atEnd()) {
            QString line = in.readLine();
            // CapEff 是进程的有效capabilities
            if (line.startsWith("CapEff:")) {
                QString capEffStr = line.mid(7).trimmed();  // 获取16进制字符串
                LOG_INFO(QString("[DEBUG] Read CapEff: '%1'").arg(capEffStr));

                // CAP_NET_ADMIN 是第12位，对应 0x1000 (bit 12)
                // 在64位系统中，capabilities表示为16进制字符串
                bool ok;
                quint64 capEff = capEffStr.toULongLong(&ok, 16);
                LOG_INFO(QString("[DEBUG] Conversion ok=%1, capEff=0x%2").arg(ok).arg(capEff, 16, 16, QChar('0')));
                LOG_INFO(QString("[DEBUG] Checking bit 12: (0x%1 & 0x1000) = 0x%2")
                    .arg(capEff, 16, 16, QChar('0'))
                    .arg(capEff & (1ULL << 12), 0, 16));

                if (ok && (capEff & (1ULL << 12))) {
                    LOG_INFO("[DEBUG] ✓ Process has effective CAP_NET_ADMIN capability");
                    statusFile.close();
                    return true;
                } else {
                    LOG_WARNING("[DEBUG] ✗ Process does NOT have CAP_NET_ADMIN in CapEff");
                    LOG_WARNING(QString("[DEBUG] CapEff: %1, ok=%2, bit12=%3").arg(capEffStr).arg(ok).arg(bool(capEff & (1ULL << 12))));
                }
                break;
            }
        }
        statusFile.close();
    } else {
        LOG_WARNING("[DEBUG] Failed to open /proc/self/status");
    }

    // 作为后备，检查文件是否有capabilities（但这不代表进程有权限）
    QString appPath = QCoreApplication::applicationFilePath();
    QString output = executeCommandWithOutput("getcap", QStringList() << appPath);

    if (output.contains("cap_net_admin")) {
        LOG_WARNING("File has CAP_NET_ADMIN capability, but process does not");
        LOG_WARNING("This usually happens when launching from UI");
        LOG_WARNING("Need to use pkexec or run from command line");
        return false;  // 返回false因为进程实际没有权限
    }
    
    LOG_DEBUG("Application lacks VPN permissions");
    return false;
}

// ============================================================================
// 系统代理设置
// ============================================================================

bool LinuxPlatform::setupSystemProxy(const QString& host, int port)
{
    
    bool success = false;
    DesktopEnvironment de = detectDesktopEnvironment();
    
    // 根据桌面环境选择合适的方法
    switch (de) {
        case GNOME:
        case MATE:
        case Cinnamon:
            success = setGnomeProxy(host, port);
            break;
            
        case KDE:
            success = setKdeProxy(host, port);
            break;
            
        default:
            success = setEnvironmentProxy(host, port);
            break;
    }
    
    // 同时设置环境变量作为补充
    setEnvironmentProxy(host, port);
    
    if (success) {
    } else {
        LOG_WARNING("Failed to configure system proxy via desktop settings");
    }
    
    return success;
}

bool LinuxPlatform::clearSystemProxy()
{
    
    bool success = false;
    DesktopEnvironment de = detectDesktopEnvironment();
    
    switch (de) {
        case GNOME:
        case MATE:
        case Cinnamon:
            success = clearGnomeProxy();
            break;
            
        case KDE:
            success = clearKdeProxy();
            break;
            
        default:
            success = clearEnvironmentProxy();
            break;
    }
    
    // 清除环境变量
    clearEnvironmentProxy();
    
    if (success) {
    } else {
        LOG_WARNING("Failed to clear system proxy");
    }
    
    return success;
}

bool LinuxPlatform::setGnomeProxy(const QString& host, int port)
{
    LOG_DEBUG("Setting GNOME/GTK proxy");
    
    bool allSuccess = true;
    
    // 设置代理模式为手动
    if (!executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy" << "mode" << "manual")) {
        LOG_ERROR("Failed to set GNOME proxy mode");
        allSuccess = false;
    }
    
    // 设置 HTTP 代理
    if (!executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy.http" << "host" << host)) {
        LOG_ERROR("Failed to set GNOME HTTP proxy host");
        allSuccess = false;
    }
    
    if (!executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy.http" << "port" << QString::number(port))) {
        LOG_ERROR("Failed to set GNOME HTTP proxy port");
        allSuccess = false;
    }
    
    // 设置 HTTPS 代理
    executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy.https" << "host" << host);
    executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy.https" << "port" << QString::number(port));
    
    // 设置 SOCKS 代理
    executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy.socks" << "host" << host);
    executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy.socks" << "port" << QString::number(port));
    
    if (allSuccess) {
        LOG_DEBUG("GNOME proxy configured successfully");
    }
    
    return allSuccess;
}

bool LinuxPlatform::clearGnomeProxy()
{
    LOG_DEBUG("Clearing GNOME proxy");
    
    if (executeCommand("gsettings", 
        QStringList() << "set" << "org.gnome.system.proxy" << "mode" << "none")) {
        LOG_DEBUG("GNOME proxy cleared successfully");
        return true;
    }
    
    LOG_ERROR("Failed to clear GNOME proxy");
    return false;
}

bool LinuxPlatform::setKdeProxy(const QString& host, int port)
{
    LOG_DEBUG("Setting KDE proxy");
    
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QString kioConfigFile = configPath + "/kioslaverc";
    
    QSettings settings(kioConfigFile, QSettings::IniFormat);
    settings.beginGroup("Proxy Settings");
    settings.setValue("ProxyType", 1); // 手动代理
    settings.setValue("httpProxy", QString("http://%1:%2").arg(host).arg(port));
    settings.setValue("httpsProxy", QString("http://%1:%2").arg(host).arg(port));
    settings.setValue("socksProxy", QString("socks://%1:%2").arg(host).arg(port));
    settings.endGroup();
    settings.sync();
    
    // 通知 KDE 刷新配置
    executeCommand("dbus-send", QStringList() 
        << "--type=signal" 
        << "/KIO/Scheduler" 
        << "org.kde.KIO.Scheduler.reparseSlaveConfiguration"
        << "string:''");
    
    LOG_DEBUG("KDE proxy configured");
    return true;
}

bool LinuxPlatform::clearKdeProxy()
{
    LOG_DEBUG("Clearing KDE proxy");
    
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QString kioConfigFile = configPath + "/kioslaverc";
    
    QSettings settings(kioConfigFile, QSettings::IniFormat);
    settings.beginGroup("Proxy Settings");
    settings.setValue("ProxyType", 0); // 不使用代理
    settings.endGroup();
    settings.sync();
    
    executeCommand("dbus-send", QStringList() 
        << "--type=signal" 
        << "/KIO/Scheduler" 
        << "org.kde.KIO.Scheduler.reparseSlaveConfiguration"
        << "string:''");
    
    return true;
}

bool LinuxPlatform::setEnvironmentProxy(const QString& host, int port)
{
    LOG_DEBUG("Setting environment proxy variables");
    
    QString httpProxy = QString("http://%1:%2").arg(host).arg(port);
    QString socksProxy = QString("socks5://%1:%2").arg(host).arg(port);
    
    qputenv("http_proxy", httpProxy.toUtf8());
    qputenv("https_proxy", httpProxy.toUtf8());
    qputenv("ftp_proxy", httpProxy.toUtf8());
    qputenv("socks_proxy", socksProxy.toUtf8());
    qputenv("HTTP_PROXY", httpProxy.toUtf8());
    qputenv("HTTPS_PROXY", httpProxy.toUtf8());
    qputenv("FTP_PROXY", httpProxy.toUtf8());
    qputenv("SOCKS_PROXY", socksProxy.toUtf8());
    qputenv("no_proxy", "localhost,127.0.0.1");
    qputenv("NO_PROXY", "localhost,127.0.0.1");
    
    LOG_DEBUG("Environment proxy variables set");
    return true;
}

bool LinuxPlatform::clearEnvironmentProxy()
{
    LOG_DEBUG("Clearing environment proxy variables");
    
    qunsetenv("http_proxy");
    qunsetenv("https_proxy");
    qunsetenv("ftp_proxy");
    qunsetenv("socks_proxy");
    qunsetenv("HTTP_PROXY");
    qunsetenv("HTTPS_PROXY");
    qunsetenv("FTP_PROXY");
    qunsetenv("SOCKS_PROXY");
    qunsetenv("no_proxy");
    qunsetenv("NO_PROXY");
    
    return true;
}

// ============================================================================
// 开机自启动
// ============================================================================

bool LinuxPlatform::setAutoStart(bool enable)
{
    
    QString autostartPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) +
                           "/autostart";
    
    // 确保目录存在
    if (!QDir().mkpath(autostartPath)) {
        LOG_ERROR(QString("Failed to create autostart directory: %1").arg(autostartPath));
        return false;
    }
    
    QString desktopFile = getAutostartFilePath();
    
    if (enable) {
        if (createDesktopFile(desktopFile)) {
            return true;
        } else {
            LOG_ERROR("Failed to create desktop file");
            return false;
        }
    } else {
        if (QFile::exists(desktopFile)) {
            if (QFile::remove(desktopFile)) {
                return true;
            } else {
                LOG_ERROR("Failed to remove desktop file");
                return false;
            }
        }
        return true;
    }
}

bool LinuxPlatform::isAutoStartEnabled()
{
    QString desktopFile = getAutostartFilePath();
    bool enabled = QFile::exists(desktopFile);
    
    LOG_DEBUG(QString("Auto-start status: %1").arg(enabled ? "enabled" : "disabled"));
    
    if (enabled) {
        LOG_DEBUG(QString("Desktop file: %1").arg(desktopFile));
    }
    
    return enabled;
}

QString LinuxPlatform::getAutostartFilePath() const
{
    QString autostartDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) 
                          + "/autostart";
    
    QString appName = QCoreApplication::applicationName();
    if (appName.isEmpty()) {
        appName = "jingo";
    }
    
    return autostartDir + "/" + appName.toLower() + ".desktop";
}

bool LinuxPlatform::createDesktopFile(const QString& filePath)
{
    QFile file(filePath);
    
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        LOG_ERROR(QString("Failed to create desktop file: %1").arg(filePath));
        return false;
    }
    
    QTextStream out(&file);
    
    QString appName = QCoreApplication::applicationName();
    if (appName.isEmpty()) {
        appName = "JinGo";
    }
    
    QString execPath = QCoreApplication::applicationFilePath();
    
    out << "[Desktop Entry]\n";
    out << "Type=Application\n";
    out << "Version=1.0\n";
    out << "Name=" << appName << "\n";
    out << "Comment=" << appName << " VPN Client\n";
    out << "Exec=" << execPath << "\n";
    out << "Icon=network-vpn\n";
    out << "Terminal=false\n";
    out << "StartupNotify=false\n";
    out << "Hidden=false\n";
    out << "NoDisplay=false\n";
    out << "X-GNOME-Autostart-enabled=true\n";
    out << "X-KDE-autostart-after=panel\n";
    out << "X-MATE-Autostart-enabled=true\n";
    
    file.close();
    
    // 设置可执行权限
    file.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner |
                       QFile::ReadGroup | QFile::ReadOther);
    
    LOG_DEBUG(QString("Desktop file created successfully: %1").arg(filePath));
    return true;
}

// ============================================================================
// 通知
// ============================================================================

void LinuxPlatform::showNotification(const QString& title, const QString& message)
{
    LOG_DEBUG(QString("Showing notification: %1 - %2").arg(title, message));
    
    // 方法1: 尝试使用 D-Bus
    if (sendDbusNotification(title, message)) {
        LOG_DEBUG("Notification sent via D-Bus");
        return;
    }
    
    // 方法2: 回退到 notify-send
    if (sendNotifySendNotification(title, message)) {
        LOG_DEBUG("Notification sent via notify-send");
        return;
    }
    
    LOG_WARNING("Failed to show notification using all available methods");
}

bool LinuxPlatform::sendDbusNotification(const QString& title, const QString& message)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications",
        "Notify"
    );
    
    QString appName = QCoreApplication::applicationName();
    if (appName.isEmpty()) {
        appName = "JinGo";
    }
    
    QVariantList args;
    args << appName;                     // app_name
    args << static_cast<uint>(0);       // replaces_id
    args << QString("network-vpn");     // app_icon
    args << title;                       // summary
    args << message;                     // body
    args << QStringList();              // actions
    args << QVariantMap();              // hints
    args << static_cast<int>(5000);     // timeout (5 seconds)
    
    msg.setArguments(args);
    
    QDBusMessage reply = QDBusConnection::sessionBus().call(msg);
    
    if (reply.type() == QDBusMessage::ErrorMessage) {
        LOG_DEBUG(QString("D-Bus notification error: %1").arg(reply.errorMessage()));
        return false;
    }
    
    return true;
}

bool LinuxPlatform::sendNotifySendNotification(const QString& title, const QString& message)
{
    QProcess process;
    process.start("notify-send", QStringList() << title << message << "-t" << "5000");
    
    if (!process.waitForStarted(1000)) {
        LOG_DEBUG("Failed to start notify-send");
        return false;
    }
    
    process.waitForFinished(1000);
    return true;
}

// ============================================================================
// 设备信息
// ============================================================================

QString LinuxPlatform::getDeviceId()
{
    // 方法1: 读取 machine-id
    QString machineId = getMachineId();
    if (!machineId.isEmpty()) {
        LOG_DEBUG(QString("Device ID from machine-id: %1").arg(machineId));
        return machineId;
    }
    
    // 方法2: 使用主机名
    QString hostname = getHostname();
    if (!hostname.isEmpty()) {
        LOG_DEBUG(QString("Device ID from hostname: %1").arg(hostname));
        return hostname;
    }
    
    // 方法3: 生成并保存 UUID
    QSettings settings(QSettings::UserScope, 
                      QCoreApplication::organizationName(),
                      QCoreApplication::applicationName());
    
    QString deviceId = settings.value("DeviceId").toString();
    if (deviceId.isEmpty()) {
        deviceId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        settings.setValue("DeviceId", deviceId);
        settings.sync();
    }
    
    return deviceId;
}

QString LinuxPlatform::getMachineId() const
{
    // 尝试读取 /etc/machine-id
    QFile file("/etc/machine-id");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString id = file.readAll().trimmed();
        file.close();
        if (!id.isEmpty()) {
            return id;
        }
    }
    
    // 尝试 /var/lib/dbus/machine-id
    QFile file2("/var/lib/dbus/machine-id");
    if (file2.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString id = file2.readAll().trimmed();
        file2.close();
        if (!id.isEmpty()) {
            return id;
        }
    }
    
    LOG_DEBUG("Could not read machine-id");
    return QString();
}

QString LinuxPlatform::getHostname() const
{
    return QSysInfo::machineHostName();
}

QString LinuxPlatform::osVersion() const
{
    QString prettyName = QSysInfo::prettyProductName();
    QString kernel = QSysInfo::kernelVersion();
    
    return QString("%1 (Kernel %2)").arg(prettyName, kernel);
}

// ============================================================================
// 桌面环境检测
// ============================================================================

LinuxPlatform::DesktopEnvironment LinuxPlatform::detectDesktopEnvironment() const
{
    QString desktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP").toLower();
    QString session = qEnvironmentVariable("DESKTOP_SESSION").toLower();
    
    LOG_DEBUG(QString("XDG_CURRENT_DESKTOP: %1").arg(desktop));
    LOG_DEBUG(QString("DESKTOP_SESSION: %1").arg(session));
    
    if (desktop.contains("gnome") || session.contains("gnome")) {
        return GNOME;
    } else if (desktop.contains("kde") || session.contains("kde") || 
               qEnvironmentVariableIsSet("KDE_FULL_SESSION")) {
        return KDE;
    } else if (desktop.contains("xfce") || session.contains("xfce")) {
        return XFCE;
    } else if (desktop.contains("mate") || session.contains("mate")) {
        return MATE;
    } else if (desktop.contains("cinnamon") || session.contains("cinnamon")) {
        return Cinnamon;
    } else if (desktop.contains("lxde") || session.contains("lxde")) {
        return LXDE;
    }
    
    return Unknown;
}

QString LinuxPlatform::getDesktopEnvironmentName() const
{
    switch (detectDesktopEnvironment()) {
        case GNOME: return "GNOME";
        case KDE: return "KDE Plasma";
        case XFCE: return "XFCE";
        case MATE: return "MATE";
        case Cinnamon: return "Cinnamon";
        case LXDE: return "LXDE";
        case Other: return "Other";
        default: return "Unknown";
    }
}

// ============================================================================
// 辅助方法
// ============================================================================

bool LinuxPlatform::executeCommand(const QString& program, const QStringList& arguments)
{
    QProcess process;
    process.start(program, arguments);
    
    if (!process.waitForFinished(5000)) {
        LOG_DEBUG(QString("Command timeout: %1 %2").arg(program, arguments.join(" ")));
        process.kill();
        return false;
    }
    
    int exitCode = process.exitCode();
    if (exitCode != 0) {
        QString error = process.readAllStandardError();
        LOG_DEBUG(QString("Command failed: %1 %2 (exit code: %3, error: %4)")
            .arg(program, arguments.join(" "))
            .arg(exitCode)
            .arg(error.trimmed()));
        return false;
    }
    
    return true;
}

QString LinuxPlatform::executeCommandWithOutput(const QString& program, const QStringList& arguments)
{
    QProcess process;
    process.start(program, arguments);

    if (!process.waitForFinished(5000)) {
        LOG_DEBUG(QString("Command timeout: %1").arg(program));
        process.kill();
        return QString();
    }

    QString output = process.readAllStandardOutput().trimmed();
    return output;
}

// ============================================================================
// TUN设备管理
// ============================================================================

bool LinuxPlatform::createTunDevice(const QString& deviceName)
{
    LOG_INFO(QString("Creating TUN device: %1").arg(deviceName));

    // 检查VPN权限
    if (!hasVPNPermission()) {
        LOG_WARNING("No VPN permissions, attempting to request...");

        // 尝试请求权限
        if (!requestVPNPermission()) {
            LOG_ERROR("Failed to obtain VPN permissions");
            LOG_ERROR("TUN device creation requires CAP_NET_ADMIN capability");
            LOG_ERROR("Please run: sudo setcap cap_net_admin+eip " + QCoreApplication::applicationFilePath());
            return false;
        }

        LOG_INFO("VPN permissions granted successfully");
    }

    if (!m_tunManager) {
        m_tunManager = std::make_unique<JinGo::LinuxTunManager>();
        LOG_DEBUG("LinuxTunManager instance created");
    }

    bool success = m_tunManager->initialize(deviceName.toStdString(), 1500);

    if (success) {
        LOG_INFO(QString("TUN device created successfully: %1 (fd=%2)")
            .arg(deviceName).arg(m_tunManager->getFd()));
    } else {
        LOG_ERROR(QString("Failed to create TUN device: %1").arg(deviceName));
        m_tunManager.reset();
    }

    return success;
}

bool LinuxPlatform::closeTunDevice()
{
    LOG_INFO("Closing TUN device");

    if (m_tunManager) {
        m_tunManager->shutdown();
        m_tunManager.reset();
        LOG_DEBUG("TUN device closed and resources released");
        return true;
    }

    LOG_WARNING("No TUN device to close");
    return false;
}

bool LinuxPlatform::configureTunDevice(const TunDeviceConfig& config)
{
    LOG_INFO("╔════════════════════════════════════════╗");
    LOG_INFO("║   Configuring TUN Device               ║");
    LOG_INFO("╠════════════════════════════════════════╣");
    LOG_INFO(QString("║ IP Address:  %1              ").arg(config.ipAddress));
    LOG_INFO(QString("║ Netmask:     %1         ").arg(config.netmask));
    LOG_INFO(QString("║ MTU:         %1                   ").arg(config.mtu));
    LOG_INFO("╚════════════════════════════════════════╝");

    if (!m_tunManager) {
        LOG_ERROR("TUN manager not initialized");
        return false;
    }

    // 设置IP地址和子网掩码
    // 将子网掩码(如"255.255.255.0")转换为前缀长度(如24)
    uint8_t prefixLength = netmaskToPrefixLength(config.netmask);
    LOG_INFO(QString("Converting netmask %1 to prefix length: %2").arg(config.netmask).arg(prefixLength));

    if (!m_tunManager->setIPAddress(config.ipAddress.toStdString(), prefixLength)) {
        LOG_ERROR("Failed to set TUN IP address");
        return false;
    }
    LOG_INFO(QString("✓ TUN IP address set: %1/%2").arg(config.ipAddress).arg(prefixLength));

    // 设置MTU
    if (config.mtu > 0) {
        if (!m_tunManager->setMTU(config.mtu)) {
            LOG_WARNING("Failed to set TUN MTU, continuing anyway");
        } else {
            LOG_INFO(QString("✓ TUN MTU set: %1").arg(config.mtu));
        }
    }

    // 启动设备（设置为UP状态）
    if (!m_tunManager->setDeviceState(true)) {
        LOG_ERROR("Failed to set TUN device to UP state");
        return false;
    }
    LOG_INFO("✓ TUN device set to UP state");

    QString deviceName = QString::fromStdString(m_tunManager->getDeviceName());
    LOG_INFO("╔════════════════════════════════════════╗");
    LOG_INFO(QString("║ ✓ TUN Device Ready: %1          ").arg(deviceName));
    LOG_INFO("╚════════════════════════════════════════╝");

    return true;
}

QByteArray LinuxPlatform::readPacket()
{
    if (!m_tunManager || !m_tunManager->isRunning()) {
        return QByteArray();
    }

    uint8_t buffer[2048];
    ssize_t len = m_tunManager->readPacket(buffer, sizeof(buffer));

    if (len > 0) {
        return QByteArray(reinterpret_cast<const char*>(buffer), len);
    } else if (len < 0) {
        LOG_DEBUG("Failed to read packet from TUN device");
    }

    return QByteArray();
}

bool LinuxPlatform::writePacket(const QByteArray& packet)
{
    if (!m_tunManager || !m_tunManager->isRunning()) {
        LOG_WARNING("TUN manager not running, cannot write packet");
        return false;
    }

    ssize_t written = m_tunManager->writePacket(
        reinterpret_cast<const uint8_t*>(packet.data()),
        packet.size()
    );

    if (written != packet.size()) {
        LOG_WARNING(QString("Failed to write complete packet: wrote %1 of %2 bytes")
            .arg(written).arg(packet.size()));
        return false;
    }

    return true;
}

bool LinuxPlatform::addRoute(const RouteConfig& route)
{
    if (!m_tunManager || !m_tunManager->isRunning()) {
        LOG_ERROR("TUN manager not running, cannot add route");
        return false;
    }

    // 将 netmask 转换为前缀长度
    // 例如: "0.0.0.0" -> 0, "128.0.0.0" -> 1, "255.255.255.0" -> 24
    uint8_t prefixLength = 0;
    if (route.netmask == "0.0.0.0") {
        prefixLength = 0;
    } else if (route.netmask == "128.0.0.0") {
        prefixLength = 1;
    } else if (route.netmask == "255.255.255.0") {
        prefixLength = 24;
    } else {
        // 默认处理，尝试计算前缀长度
        QHostAddress addr(route.netmask);
        quint32 mask = addr.toIPv4Address();
        while (mask > 0) {
            if (mask & 1) break;
            mask >>= 1;
            prefixLength++;
        }
        prefixLength = 32 - prefixLength;
    }

    LOG_INFO(QString("Adding route: %1/%2 via %3")
        .arg(route.destination)
        .arg(prefixLength)
        .arg(route.gateway.isEmpty() ? "TUN device" : route.gateway));

    bool success = m_tunManager->addRoute(
        route.destination.toStdString(),
        prefixLength,
        route.gateway.toStdString()
    );

    if (success) {
        LOG_DEBUG("Route added successfully");
    } else {
        LOG_ERROR("Failed to add route");
    }

    return success;
}

bool LinuxPlatform::deleteRoute(const RouteConfig& route)
{
    if (!m_tunManager) {
        LOG_WARNING("TUN manager not available, cannot delete route");
        return false;
    }

    // 将 netmask 转换为前缀长度
    uint8_t prefixLength = 0;
    if (route.netmask == "0.0.0.0") {
        prefixLength = 0;
    } else if (route.netmask == "128.0.0.0") {
        prefixLength = 1;
    } else if (route.netmask == "255.255.255.0") {
        prefixLength = 24;
    } else {
        QHostAddress addr(route.netmask);
        quint32 mask = addr.toIPv4Address();
        while (mask > 0) {
            if (mask & 1) break;
            mask >>= 1;
            prefixLength++;
        }
        prefixLength = 32 - prefixLength;
    }

    LOG_INFO(QString("Deleting route: %1/%2")
        .arg(route.destination)
        .arg(prefixLength));

    bool success = m_tunManager->deleteRoute(
        route.destination.toStdString(),
        prefixLength
    );

    if (success) {
        LOG_DEBUG("Route deleted successfully");
    } else {
        LOG_WARNING("Failed to delete route (may not exist)");
    }

    return success;
}

int LinuxPlatform::getTunFileDescriptor()
{
    if (m_tunManager && m_tunManager->isRunning()) {
        int fd = m_tunManager->getFd();
        LOG_DEBUG(QString("TUN file descriptor: %1").arg(fd));
        return fd;
    }

    LOG_WARNING("TUN manager not running, no file descriptor available");
    return -1;
}

bool LinuxPlatform::isTunDeviceCreated() const
{
    return m_tunManager && m_tunManager->isRunning();
}
