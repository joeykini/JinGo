/**
 * @file icon_usage_example.cpp
 * @brief Windows 图标使用示例
 * @details 展示如何在 Qt 应用程序中使用 app.ico
 */

#include <QApplication>
#include <QMainWindow>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QIcon>

/**
 * 示例 1: 设置应用程序全局图标
 * 所有窗口默认都会使用这个图标
 */
void setApplicationIcon(QApplication &app)
{
    QIcon appIcon(":/icons/app.ico");
    app.setWindowIcon(appIcon);
}

/**
 * 示例 2: 设置单个窗口的图标
 */
void setWindowIcon(QMainWindow *window)
{
    window->setWindowIcon(QIcon(":/icons/app.ico"));
}

/**
 * 示例 3: 创建系统托盘图标
 */
QSystemTrayIcon* createSystemTrayIcon(QObject *parent)
{
    QSystemTrayIcon *trayIcon = new QSystemTrayIcon(parent);

    // 设置托盘图标
    trayIcon->setIcon(QIcon(":/icons/app.ico"));

    // 设置工具提示
    trayIcon->setToolTip("JinGo VPN");

    // 创建托盘菜单
    QMenu *trayMenu = new QMenu();
    trayMenu->addAction("显示主窗口");
    trayMenu->addAction("连接");
    trayMenu->addAction("断开");
    trayMenu->addSeparator();
    trayMenu->addAction("退出");

    trayIcon->setContextMenu(trayMenu);
    trayIcon->show();

    return trayIcon;
}

/**
 * 示例 4: 在消息框中使用图标
 */
void showMessageWithIcon(QWidget *parent)
{
    QMessageBox msgBox(parent);
    msgBox.setWindowIcon(QIcon(":/icons/app.ico"));
    msgBox.setIconPixmap(QPixmap(":/icons/app.ico").scaled(48, 48, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    msgBox.setText("这是一个带有应用图标的消息框");
    msgBox.exec();
}

/**
 * 示例 5: 完整的应用程序初始化
 */
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // 设置应用程序信息
    app.setApplicationName("JinGo VPN");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("JinGo Team");

    // 设置应用程序图标
    setApplicationIcon(app);

    // 创建主窗口
    QMainWindow mainWindow;
    mainWindow.setWindowTitle("JinGo VPN");
    mainWindow.resize(800, 600);

    // 可以选择单独设置窗口图标（如果已设置应用程序图标则不必要）
    // setWindowIcon(&mainWindow);

    // 创建系统托盘图标
    QSystemTrayIcon *trayIcon = createSystemTrayIcon(&app);

    // 连接托盘图标点击事件
    QObject::connect(trayIcon, &QSystemTrayIcon::activated, [&](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger) {
            if (mainWindow.isVisible()) {
                mainWindow.hide();
            } else {
                mainWindow.show();
                mainWindow.activateWindow();
            }
        }
    });

    mainWindow.show();

    return app.exec();
}

/**
 * 注意事项：
 *
 * 1. 资源路径前缀
 *    - C++ 使用: ":/icons/app.ico"
 *    - QML 使用: "qrc:/icons/app.ico"
 *
 * 2. 图标格式选择
 *    - Windows: 推荐使用 .ico 格式，支持多尺寸
 *    - macOS: 使用 .icns 格式
 *    - Linux: 使用 .png 格式
 *    - 跨平台: 可以使用条件编译选择不同格式
 *
 * 3. 图标缩放
 *    - QIcon 会自动选择最接近的尺寸
 *    - 如需手动缩放: QPixmap(":/icons/app.ico").scaled(size, size)
 *
 * 4. 高 DPI 支持
 *    - Qt 会自动处理高 DPI 显示
 *    - ICO 文件包含多种尺寸，确保各种 DPI 下清晰显示
 *
 * 5. 跨平台图标设置
 */

#ifdef Q_OS_WIN
    // Windows 特定的图标设置
    void setWindowsSpecificIcon(QWidget *widget) {
        widget->setWindowIcon(QIcon(":/icons/app.ico"));
    }
#elif defined(Q_OS_MACOS)
    // macOS 特定的图标设置
    void setMacOSSpecificIcon(QWidget *widget) {
        widget->setWindowIcon(QIcon(":/icons/app.icns"));
    }
#else
    // Linux/其他平台
    void setLinuxSpecificIcon(QWidget *widget) {
        widget->setWindowIcon(QIcon(":/icons/app.png"));
    }
#endif

/**
 * 跨平台图标设置示例
 */
void setCrossPlatformIcon(QWidget *widget)
{
    QIcon icon;

#ifdef Q_OS_WIN
    icon.addFile(":/icons/app.ico");
#elif defined(Q_OS_MACOS)
    icon.addFile(":/icons/app.icns");
#else
    icon.addFile(":/icons/app.png");
#endif

    widget->setWindowIcon(icon);
}
