// qml/main.qml (完美优化版 - 无 GraphicalEffects 依赖)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15
import JinGo 1.0

ApplicationWindow {
    id: mainWindow

    // 暴露 stackView 给子页面使用
    property alias stackView: stackView

    visible: true

    // 移动端全屏显示标志
    flags: (Qt.platform.os === "android" || Qt.platform.os === "ios") ?
           Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint : Qt.Window

    // 移动端使用屏幕尺寸，桌面端使用固定尺寸
    width: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.width : 900
    height: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.height : 720
    minimumWidth: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.width : 880
    minimumHeight: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.height : 600
    title: "JinGo - " + qsTr("Secure. Fast. Borderless.")

    // 全局字体设置（针对移动端优化）
    font.family: Theme.typography.fontFamily
    font.weight: isMobile ? Theme.typography.mobileWeightNormal : Theme.typography.weightRegular

    // RTL布局镜像支持（根据应用布局方向自动启用）
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // 响应式断点
    readonly property bool isMobile: Qt.platform.os === "android" ||
                                     Qt.platform.os === "ios" ||
                                     width < 768
    readonly property bool isTablet: width >= 768 && width < 1024
    readonly property bool isDesktop: width >= 1024

    // 安全区域 - 底部导航栏/手势区域高度
    // Android: 根据屏幕密度计算，通常为 48dp (约 144px @ 3x density)
    // iOS: Home Indicator 约 34px
    // 如果导航栏底部紧贴系统导航区，则设为 0
    readonly property real safeAreaTop: Qt.platform.os === "ios" ? 47 : 0
    readonly property real safeAreaBottom: 0  // 导航栏直接贴底，不需要额外间距

    // 侧边栏状态
    property bool sidebarCollapsed: isMobile
    readonly property int sidebarWidth: isMobile ? 0 : 90

    // 主题系统 - 从 settingsViewModel 读取
    property bool isDarkMode: settingsViewModel ? settingsViewModel.isDarkMode : false

    // Android状态栏和导航栏图标颜色 - 始终使用深色图标
    onIsDarkModeChanged: {
        // 同步到 Theme 单例
        Theme.isDarkMode = isDarkMode

        if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined') {
            // 无论什么主题，都使用深色图标（黑色）
            // false = 深色图标，适合浅色背景
            androidStatusBarManager.setSystemBarIconsColor(false, false)
        }
    }

    // 监听主题变化
    Connections {
        target: configManager
        function onThemeChanged() {
            if (configManager && typeof configManager.theme !== 'undefined') {
                Theme.currentTheme = Theme.themes[configManager.theme] || Theme.jingoTheme
            }
        }
    }

    // 应用状态
    property bool isAuthenticated: false  // 修改为普通属性，避免在初始化时访问authManager
    property bool isConnected: false  // 使用本地属性，通过信号手动更新
    property string currentPage: "loading"
    property bool hasShownTrayHint: false

    // 更新连接状态的函数
    function updateVPNConnectionState() {
        try {
            if (vpnManager && typeof vpnManager.isConnected !== 'undefined') {
                isConnected = vpnManager.isConnected || false
            } else {
                isConnected = false
            }
        } catch (error) {
            isConnected = false
        }
    }

    // 背景色 - 使用主题配置
    color: Theme.colors.pageBackground

    // 页面切换函数
    function navigateTo(page, qmlFile) {
        currentPage = page
        stackView.replace(qmlFile)
    }

    // 推送新页面（用于子页面导航，如应用选择页面）
    function pushPage(qmlFile) {
        stackView.push(qmlFile)
    }

    // 弹出页面
    function popPage() {
        if (stackView.depth > 1) {
            stackView.pop()
        }
    }

    // 显示 Toast 提示
    function showToast(message) {
        toastLabel.text = message
        toastPopup.open()
    }

    // 监听宽度变化
    onWidthChanged: {
        if (isMobile) {
            sidebarCollapsed = true
        }
    }

    // 系统托盘连接
    Connections {
        target: systemTrayManager

        function onShowWindowRequested() {
            mainWindow.show()
            mainWindow.raise()
            mainWindow.requestActivate()
        }

        function onQuickConnectRequested() {
            if (vpnManager && !isConnected) {
                vpnManager.connecting(vpnManager.currentServer)
            }
        }

        function onDisconnectRequested() {
            if (vpnManager) {
                vpnManager.disconnect()
            }
        }

        function onSettingsRequested() {
            mainWindow.show()
            mainWindow.raise()
            mainWindow.requestActivate()
            navigateTo("settings", "pages/SettingsPage.qml")
        }

        function onQuitRequested() {
            Qt.quit()
        }
    }

    // VPN 状态变化通知
    Connections {
        target: vpnManager

        function onConnected() {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("Connected"), qsTr("VPN ConnectSuccess"))
            }
        }
        function onDisconnected() {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("Disconnected"), qsTr("VPN Disconnected"))
            }
        }
        function onConnectFailed(reason) {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("ConnectFailed"), reason)
            }
        }
        function onErrorOccurred(error) {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("Error"), error)
            }
        }
    }

    // 认证状态变化
    Connections {
        target: authManager

        function onAuthenticationChanged() {
            // 安全地更新isAuthenticated状态
            try {
                if (authManager && typeof authManager.isAuthenticated !== 'undefined') {
                    isAuthenticated = authManager.isAuthenticated || false
                }
            } catch (e) {
                isAuthenticated = false
            }

            // 根据状态导航到相应页面
            if (!isAuthenticated) {
                // 用户登出，重置数据加载标记
                hasLoadedInitialData = false
                navigateTo("login", "pages/LoginPage.qml")
            } else {
                // 用户登录，加载数据并导航到个人中心
                navigateTo("profile", "pages/ProfilePage.qml")
                // 延迟加载数据，确保页面已准备好
                Qt.callLater(loadInitialData)
            }
        }
    }

    // 菜单栏
    menuBar: MenuBar {
        visible: isDesktop

        Menu {
            title: qsTr("File")
            MenuItem { 
                text: qsTr("Preferences")
                onTriggered: navigateTo("settings", "pages/SettingsPage.qml")
            }
            MenuSeparator {}
            MenuItem { 
                text: qsTr("Quit")
                onTriggered: Qt.quit() 
            }
        }

        Menu {
            title: qsTr("Connect")
            MenuItem {
                text: isConnected ? qsTr("DisconnectConnect") : qsTr("Connect")
                enabled: isAuthenticated
                onTriggered: {
                    if (vpnManager) {
                        if (isConnected) { 
                            vpnManager.disconnect() 
                        } else { 
                            vpnManager.connecting(vpnManager.currentServer) 
                        }
                    }
                }
            }
            MenuItem {
                text: qsTr("Select Server")
                onTriggered: navigateTo("servers", "pages/ServerListPage.qml")
            }
        }

        Menu {
            title: qsTr("Help")
            MenuItem { 
                text: qsTr("Documentation")
                onTriggered: Qt.openUrlExternally(bundleConfig.docsUrl || "https://docs.jingo.com") 
            }
            MenuItem { 
                text: qsTr("Report Issue")
                onTriggered: Qt.openUrlExternally(bundleConfig.issuesUrl || "https://github.com/jingo/jingo-vpn/issues") 
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("About JinGo")
                onTriggered: aboutDialog.item && aboutDialog.item.open()
            }
        }
    }

    // 全局对话框 - 使用正确的路径加载（根据CMakeLists.txt，components映射到JinGo）
    Loader {
        id: aboutDialog
        source: "qrc:/qml/JinGo/AboutDialog.qml"
    }

    // 主布局
    Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ========================================================================
            // 左侧导航栏（桌面端）
            // ========================================================================
            Rectangle {
                id: sidebar
                Layout.preferredWidth: sidebarWidth
                Layout.fillHeight: true
                color: Theme.colors.navButtonBackground
                visible: !isMobile && currentPage !== "login"

                // 右边框（替代阴影）
                Rectangle {
                    anchors.right: parent.right
                    width: 0
                    height: parent.height
                    color: Qt.darker(Theme.colors.navButtonBackground, 1.05)
                }

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutCubic }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Logo/标题区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: "transparent"

                        // Logo 居中
                        Rectangle {
                            anchors.centerIn: parent
                            width: 56
                            height: 56
                            radius: 14
                            color: "transparent"

                            Image {
                                source: "qrc:/images/logo.png"
                                anchors.centerIn: parent
                                width: parent.width * 0.9
                                height: parent.height * 0.9
                                smooth: true
                                antialiasing: true
                            }
                        }
                    }

                    // 分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        height: 0
                        color: Qt.darker(Theme.colors.navButtonBackground, 1.05)
                    }

                    // 导航按钮组
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 8
                        clip: true
                        
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: sidebar.width
                            spacing: 2

                            // 连接页面
                            SidebarDelegate {
                                pageName: "connection"
                                labelText: qsTr("Connect")
                                iconSource: mainWindow.isConnected ?
                                    "qrc:/icons/connected.png" : "qrc:/icons/disconnected.png"
                                collapsed: true
                                visible: isAuthenticated
                                isCurrentPage: mainWindow.currentPage === "connection"
                                enabled: mainWindow.isAuthenticated

                                onClicked: navigateTo("connection", "pages/ConnectionPage.qml")
                            }

                            // 服务器列表
                            SidebarDelegate {
                                pageName: "servers"
                                labelText: qsTr("Servers")
                                iconSource: "qrc:/icons/services.png"
                                collapsed: true
                                visible: isAuthenticated
                                isCurrentPage: mainWindow.currentPage === "servers"

                                onClicked: navigateTo("servers", "pages/ServerListPage.qml")
                            }

                            // 订阅
                            SidebarDelegate {
                                pageName: "store"
                                labelText: qsTr("Subscription")
                                iconSource: "qrc:/icons/store.png"
                                collapsed: true
                                visible: isAuthenticated
                                isCurrentPage: mainWindow.currentPage === "store"

                                onClicked: navigateTo("store", "pages/StorePage.qml")
                            }

                            // 设置
                            SidebarDelegate {
                                pageName: "settings"
                                labelText: qsTr("Settings")
                                iconSource: "qrc:/icons/settings.png"
                                collapsed: true
                                visible: isAuthenticated
                                isCurrentPage: mainWindow.currentPage === "settings"

                                onClicked: navigateTo("settings", "pages/SettingsPage.qml")
                            }

                            // 填充空间
                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // 分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        height: 0
                        color: Qt.darker(Theme.colors.navButtonBackground, 1.05)
                    }

                    // 底部用户信息区域
                    ItemDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70

                        background: Rectangle {
                            color: parent.hovered ? 
                                (isDarkMode ? "#252525" : "#F8F8F8") : "transparent"
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            // 用户头像居中
                            Rectangle {
                                anchors.centerIn: parent
                                width: 44
                                height: 44
                                radius: 22

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#667EEA" }
                                    GradientStop { position: 1.0; color: "#764BA2" }
                                }

                                Label {
                                    text: isAuthenticated ?
                                        (authManager.user && authManager.user.name ?
                                            authManager.user.name.charAt(0).toUpperCase() : "U") : "?"
                                    anchors.centerIn: parent
                                    color: "white"
                                    font.pixelSize: 20
                                    font.bold: true
                                }

                                // 在线状态指示器
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: isConnected ? "#4CAF50" : "#999999"
                                    border.color: "white"
                                    border.width: 2
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                            }
                        }

                        onClicked: {
                            if (authManager && !authManager.isAuthenticated) {
                                navigateTo("login", "pages/LoginPage.qml")
                            } else {
                                navigateTo("profile", "pages/ProfilePage.qml")
                            }
                        }
                    }
                }
            }

            // ========================================================================
            // 右侧主内容区域
            // ========================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.colors.pageBackground

                // 状态栏区域背景（与导航按钮块背景色一致）
                // iOS 使用系统自带的安全区域处理，无需额外的顶部背景
                Rectangle {
                    width: parent.width
                    height: Qt.platform.os === "ios" ? 0 : 30
                    y: Qt.platform.os === "ios" ? 0 : -30
                    color: Theme.colors.navButtonBackground
                    visible: Qt.platform.os === "android" && currentPage !== "login"
                    z: 100
                }

                // 底部导航栏区域背景（与导航按钮块背景色一致）
                Rectangle {
                    width: parent.width
                    height: 40
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -40
                    color: Theme.colors.navButtonBackground
                    visible: Qt.platform.os === "android" || Qt.platform.os === "ios"
                    z: 100
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 顶部栏（移动端简化版，桌面端完整版）
                    // iOS 使用系统自带的安全区域，Qt 会自动处理
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: isMobile ? 60 : 70
                        color: Theme.colors.navButtonBackground
                        visible: currentPage !== "login"

                        Component.onCompleted: {
                        }

                        Connections {
                            target: Theme
                            function onCurrentThemeChanged() {
                            }
                        }

                        // 底部边框（替代阴影）
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.colors.divider
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: isMobile ? 60 : 70
                            anchors.leftMargin: isMobile ? 16 : 20
                            anchors.rightMargin: isMobile ? 16 : 20
                            spacing: 15

                            // 页面标题（移动端居中，桌面端靠左）
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                spacing: 2

                                Label {
                                    Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                    text: {
                                        if (currentPage === "connection") return qsTr("Connection")
                                        if (currentPage === "servers") return qsTr("Server List")
                                        if (currentPage === "settings") return qsTr("Settings")
                                        if (currentPage === "profile") return qsTr("Profile")
                                        if (currentPage === "login") return qsTr("Login/Register")
                                        if (currentPage === "store") return qsTr("Subscription")
                                        return "JinGo"
                                    }
                                    font.pixelSize: isMobile ? 18 : 20
                                    font.weight: isMobile ? Theme.typography.mobileWeightBold : Font.Bold
                                    color: Theme.colors.navButtonText
                                }

                                Label {
                                    Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                    text: {
                                        if (currentPage === "connection") return qsTr("Manage your VPN connection")
                                        if (currentPage === "servers") return qsTr("Select the best server")
                                        if (currentPage === "store") return qsTr("Upgrade your subscription plan")
                                        return ""
                                    }
                                    font.pixelSize: 12
                                    font.weight: isMobile ? Theme.typography.mobileWeightNormal : Font.Normal
                                    color: isDarkMode ? "#999999" : Theme.colors.textSecondary
                                    visible: text !== "" && !isMobile
                                }
                            }

                            // 连接状态指示器（仅桌面端显示）
                            Rectangle {
                                Layout.alignment: Qt.AlignRight
                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 36
                                radius: 18
                                color: isConnected ? "#FF980020" : "#99999920"
                                border.color: isConnected ? "#FF9800" : "#999999"
                                border.width: 1
                                visible: !isMobile && currentPage !== "login"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: isConnected ? "#FF9800" : "#999999"

                                        SequentialAnimation on opacity {
                                            running: isConnected
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                                        }
                                    }

                                    Label {
                                        text: isConnected ? qsTr("Connected") : qsTr("Not Connected")
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: isConnected ? "#FF9800" : "#999999"
                                    }
                                }
                            }
                        }
                    }

                    // 页面内容区域
                    StackView {
                        id: stackView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // 为底部导航栏预留空间（导航栏高度68px）
                        Layout.bottomMargin: isMobile && currentPage !== "login" && currentPage !== "loading" ? 68 : 0

                        // Android页面切换时重新设置状态栏
                        onCurrentItemChanged: {
                            if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined') {
                                // 无论什么主题，都使用深色图标（黑色）
                                androidStatusBarManager.setSystemBarIconsColor(false, false)
                            }
                        }

                        // 优化页面切换动画，避免闪烁
                        replaceEnter: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                        replaceExit: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 1
                                to: 0
                                duration: 100
                                easing.type: Easing.InQuad
                            }
                        }

                        // 确保背景色一致，避免闪烁
                        background: Rectangle {
                            color: Theme.colors.pageBackground
                        }
                    }
                }

                // 移动端底部导航栏 - 直接锚定到屏幕底部
                BottomNavigationBar {
                    id: bottomNavBar
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 0  // 直接贴底
                    visible: isMobile && currentPage !== "login" && currentPage !== "loading"

                    currentPage: mainWindow.currentPage
                    isDarkMode: mainWindow.isDarkMode
                    isConnected: mainWindow.isConnected

                    onNavigateToPage: function(page, qmlFile) {
                        mainWindow.navigateTo(page, qmlFile)
                    }
                }
            }
        }

    }

    // 窗口关闭事件
    onClosing: function(close) {
        if (!isMobile) {
            // 检查是否开启了最小化到系统托盘
            var shouldMinimizeToTray = configManager && configManager.minimizeToTray

            if (shouldMinimizeToTray) {
                // 最小化到系统托盘
                close.accepted = false
                mainWindow.hide()

                if (!hasShownTrayHint && systemTrayManager) {
                    systemTrayManager.showMessage(
                        qsTr("JinGo"),
                        qsTr("Application minimized to system tray, double-click the tray icon to reopen")
                    )
                    hasShownTrayHint = true
                }
            } else {
                // 直接退出应用
                close.accepted = true
                Qt.quit()
            }
        }
    }

    // 监听VPN状态变化
    Connections {
        target: vpnManager

        function onStateChanged(newState) {
            updateVPNConnectionState()
        }

        function onConnected() {
            updateVPNConnectionState()
        }

        function onDisconnected() {
            updateVPNConnectionState()
        }
    }

    // 应用启动时的数据加载标记
    property bool hasLoadedInitialData: false

    // 启动时预加载所有数据
    function loadInitialData() {
        if (hasLoadedInitialData || !authManager || !authManager.isAuthenticated) {
            return
        }

        hasLoadedInitialData = true

        // 1. 加载用户信息
        if (authManager && typeof authManager.loadUserInfo === 'function') {
            authManager.loadUserInfo()
        }

        // 2. 加载订阅信息
        if (authManager && typeof authManager.getUserSubscribe === 'function') {
            authManager.getUserSubscribe()
        }

        // 3. 加载套餐列表
        if (authManager && typeof authManager.fetchPlans === 'function') {
            authManager.fetchPlans()
        }

        // 4. 从数据库加载服务器列表到内存
        if (serverListViewModel && typeof serverListViewModel.loadServersFromDatabase === 'function') {
            serverListViewModel.loadServersFromDatabase()
        }

        // 注意：服务器列表的更新已移至 BackgroundDataUpdater
        // 不在此处主动更新，避免与后台更新冲突
        // 服务器列表会在应用启动时从数据库加载已缓存的数据
        // 并由 BackgroundDataUpdater 定期从服务器更新

    }

    // 初始化
    Component.onCompleted: {
        // 安全地更新isAuthenticated状态
        try {
            if (authManager && typeof authManager.isAuthenticated !== 'undefined') {
                isAuthenticated = authManager.isAuthenticated || false
            }
        } catch (e) {
            isAuthenticated = false
        }

        // 加载主题配置
        try {
            if (configManager && typeof configManager.theme !== 'undefined') {
                var loadedTheme = configManager.theme || "JinGO"
                Theme.currentTheme = Theme.themes[loadedTheme] || Theme.jingoTheme
            } else {
                Theme.currentTheme = Theme.jingoTheme
            }
        } catch (e) {
            Theme.currentTheme = Theme.jingoTheme
        }

        // Android状态栏和导航栏图标初始化 - 始终使用深色图标
        if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined') {
            // 无论什么主题，都使用深色图标（黑色）
            androidStatusBarManager.setSystemBarIconsColor(false, false)
        }

        // 延迟初始化连接状态，确保所有对象都已就绪
        Qt.callLater(updateVPNConnectionState)

        // 设置初始页面
        if (isAuthenticated) {
            navigateTo("profile", "pages/ProfilePage.qml")
            // 应用启动时预加载所有数据
            Qt.callLater(loadInitialData)
        } else {
            navigateTo("login", "pages/LoginPage.qml")
        }
    }

    // Toast 弹窗组件
    Popup {
        id: toastPopup
        x: (parent.width - width) / 2
        y: parent.height - height - 100
        width: Math.min(toastLabel.implicitWidth + 40, parent.width - 40)
        height: 48
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: isDarkMode ? "#424242" : "#323232"
            radius: 24
            opacity: 0.95
        }

        contentItem: Label {
            id: toastLabel
            text: ""
            color: "white"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        // 自动关闭定时器
        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: toastPopup.close()
        }

        onOpened: toastTimer.start()
        onClosed: toastTimer.stop()

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 }
        }
    }
}
