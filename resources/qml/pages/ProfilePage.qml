import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Rectangle {
    id: profilePage
    readonly property var mainWindow: Qt.application.topLevelWindow || null
    color: Theme.colors.pageBackground

    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    // Changed from readonly bindings to simple properties to avoid accessing authManager during init
    property bool isPremium: false
    property string userEmail: qsTr("Users")
    property string userAccountId: "N/A"
    property string userExpiryDate: "--"

    // 邮箱是否脱敏显示
    property bool emailMasked: true

    // 邮箱脱敏：@前最后2位用**，域名.后面用**
    // 例如: user@example.com -> us**@example.**
    function maskEmail(email) {
        if (!email || email.indexOf("@") === -1) return email

        var parts = email.split("@")
        var localPart = parts[0]
        var domainPart = parts[1]

        // 处理@前面部分：保留除最后2位之外的字符
        var maskedLocal = localPart
        if (localPart.length > 2) {
            maskedLocal = localPart.substring(0, localPart.length - 2) + "**"
        } else {
            maskedLocal = "**"
        }

        // 处理域名部分：.后面的用**代替
        var maskedDomain = domainPart
        var lastDotIndex = domainPart.lastIndexOf(".")
        if (lastDotIndex !== -1) {
            maskedDomain = domainPart.substring(0, lastDotIndex + 1) + "**"
        }

        return maskedLocal + "@" + maskedDomain
    }

    // 安全地更新用户信息
    function updateUserInfo() {
        try {
            if (authManager && typeof authManager.currentUser !== 'undefined' && authManager.currentUser) {
                var user = authManager.currentUser

                if (typeof user.email !== 'undefined' && user.email !== null) {
                    userEmail = String(user.email)
                } else {
                    userEmail = qsTr("Users")
                }

                if (typeof user.isPremium !== 'undefined' && user.isPremium !== null) {
                    isPremium = user.isPremium
                } else {
                    isPremium = false
                }

                if (typeof user.id !== 'undefined' && user.id !== null) {
                    userAccountId = String(user.id).substring(0, 8)
                } else {
                    userAccountId = "N/A"
                }

                if (typeof user.formatExpiryDate === 'function') {
                    userExpiryDate = user.formatExpiryDate()
                } else {
                    userExpiryDate = "--"
                }
            } else {
                // Reset to defaults if no user
                userEmail = qsTr("Users")
                isPremium = false
                userAccountId = "N/A"
                userExpiryDate = "--"
            }
        } catch (e) {
            userEmail = qsTr("Users")
            isPremium = false
            userAccountId = "N/A"
            userExpiryDate = "--"
        }
    }

    // 初始化
    Component.onCompleted: {
        updateUserInfo()
    }

    // 监听认证状态变化
    Connections {
        target: authManager

        function onCurrentUserChanged() {
            updateUserInfo()
        }

        function onAuthenticationChanged() {
            updateUserInfo()
        }
    }

    // 监听后台数据更新完成
    Connections {
        target: typeof backgroundDataUpdater !== 'undefined' ? backgroundDataUpdater : null
        enabled: typeof backgroundDataUpdater !== 'undefined' && backgroundDataUpdater !== null

        function onUserInfoUpdated() {
            // 检查是否正在更新，如果是则跳过
            if (!backgroundDataUpdater.isUpdating) {
                updateUserInfo()
            }
        }

        function onSubscriptionInfoUpdated() {
            // 检查是否正在更新，如果是则跳过
            if (!backgroundDataUpdater.isUpdating) {
                updateUserInfo()
            }
        }

        function onDataUpdateCompleted() {
            // 所有数据更新完成，刷新用户信息
            if (!backgroundDataUpdater.isUpdating) {
                updateUserInfo()
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.leftMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 20
        anchors.rightMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 20
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: 0

            Item { Layout.preferredHeight: 30 }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: (mainWindow && mainWindow.isDesktop) ? 600 : parent.width
                spacing: 20

                // 用户信息与订阅状态合并卡片
                Rectangle {
                    id: profileCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: isMobileLayout ? 160 : 120
                    radius: 20
                    color: Theme.colors.surface
                    border.color: Theme.colors.border
                    border.width: 1

                    property bool isMobileLayout: Qt.platform.os === "android" || Qt.platform.os === "ios"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        visible: profileCard.isMobileLayout

                        // 移动端第一行: 头像 + 邮箱账户ID
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 50
                                Layout.preferredHeight: 50
                                radius: 25
                                color: Theme.colors.surfaceElevated

                                Label {
                                    text: userEmail.charAt(0).toUpperCase()
                                    font.pixelSize: 24
                                    font.bold: true
                                    color: "#007BFF"
                                    anchors.centerIn: parent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: emailMasked ? maskEmail(userEmail) : userEmail
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: qsTr("Account ID: ") + userAccountId
                                    font.pixelSize: 11
                                    color: isDarkMode ? "#999999" : "#666666"
                                }
                            }

                            LevelBadge {
                                level: isPremium ? 2 : 0
                                compact: false
                            }

                            // 眼睛图标 - 切换邮箱显示/隐藏
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.rightMargin: 4
                                color: "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: emailMasked ? "qrc:/icons/eye-closed.svg" : "qrc:/icons/eye-open.svg"
                                    sourceSize: Qt.size(22, 22)
                                    opacity: 0.7
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        emailMasked = !emailMasked
                                    }
                                }
                            }
                        }

                        // 移动端第二行: 月度流量 + 使用天数 + 订阅状态 + 有效时间 (水平居中)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 10

                            // 左侧弹性空间
                            Item { Layout.fillWidth: true }

                            // 月度流量
                            RowLayout {
                                spacing: 4

                                IconSymbol {
                                    icon: "traffic"
                                    size: 26
                                    color: Theme.colors.info
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 2

                                    Label {
                                        text: "15.8 GB"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.colors.textPrimary
                                    }

                                    Label {
                                        text: qsTr("Traffic")
                                        font.pixelSize: 8
                                        color: isDarkMode ? "#999999" : "#666666"
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 28
                                color: Theme.colors.border
                            }

                            // 使用天数
                            RowLayout {
                                spacing: 4

                                IconSymbol {
                                    icon: "clock"
                                    size: 26
                                    color: Theme.colors.warning
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 2

                                    Label {
                                        text: "45"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.colors.textPrimary
                                    }

                                    Label {
                                        text: qsTr("Days")
                                        font.pixelSize: 8
                                        color: isDarkMode ? "#999999" : "#666666"
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 28
                                color: Theme.colors.border
                            }

                            // 订阅状态
                            RowLayout {
                                spacing: 4

                                IconSymbol {
                                    icon: "subscription"
                                    size: 26
                                    color: isPremium ? Theme.colors.success : Theme.colors.textSecondary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 2

                                    Label {
                                        text: isPremium ? qsTr("Active") : qsTr("None")
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: isPremium ? Theme.colors.success : Theme.colors.textSecondary
                                    }

                                    Label {
                                        text: qsTr("Status")
                                        font.pixelSize: 8
                                        color: isDarkMode ? "#999999" : "#666666"
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 28
                                color: Theme.colors.border
                            }

                            // 有效时间
                            RowLayout {
                                spacing: 4

                                IconSymbol {
                                    icon: "calendar"
                                    size: 26
                                    color: Theme.colors.primary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 2

                                    Label {
                                        text: isPremium ? userExpiryDate : "--"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.colors.textPrimary
                                    }

                                    Label {
                                        text: qsTr("Expires")
                                        font.pixelSize: 8
                                        color: isDarkMode ? "#999999" : "#666666"
                                    }
                                }
                            }

                            // 右侧弹性空间
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // 桌面端布局: 单行四等分
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 0
                        visible: !profileCard.isMobileLayout

                        // 1/4: 头像 + 邮箱
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                spacing: 6

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 50
                                    height: 50
                                    radius: 25
                                    color: Theme.colors.surfaceElevated

                                    Label {
                                        text: userEmail.charAt(0).toUpperCase()
                                        font.pixelSize: 24
                                        font.bold: true
                                        color: "#007BFF"
                                        anchors.centerIn: parent
                                    }
                                }

                                Label {
                                    text: maskEmail(userEmail)
                                    font.pixelSize: 11
                                    color: Theme.colors.textPrimary
                                    elide: Text.ElideMiddle
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 100
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: parent.height - 16
                                color: Theme.colors.border
                            }
                        }

                        // 2/4: 月度流量
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                spacing: 4

                                IconSymbol {
                                    icon: "traffic"
                                    size: 20
                                    color: Theme.colors.info
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: "15.8 GB"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: qsTr("Monthly Traffic")
                                    font.pixelSize: 9
                                    color: isDarkMode ? "#999999" : "#666666"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: parent.height - 16
                                color: Theme.colors.border
                            }
                        }

                        // 3/4: 使用天数
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                spacing: 4

                                IconSymbol {
                                    icon: "clock"
                                    size: 20
                                    color: Theme.colors.warning
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: "45"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: qsTr("Days Used")
                                    font.pixelSize: 9
                                    color: isDarkMode ? "#999999" : "#666666"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: parent.height - 16
                                color: Theme.colors.border
                            }
                        }

                        // 4/4: 订阅状态
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                spacing: 4

                                Label {
                                    text: qsTr("Subscription")
                                    font.pixelSize: 10
                                    color: isDarkMode ? "#999999" : "#666666"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: isPremium ? qsTr("Active") : qsTr("None")
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: isPremium ? Theme.colors.success : Theme.colors.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: isPremium ? userExpiryDate : "--"
                                    font.pixelSize: 10
                                    color: isDarkMode ? "#999999" : "#666666"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1  // 放到最底层，不阻挡其他元素的点击
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mainWindow) {
                                mainWindow.currentPage = "store"
                                mainWindow.stackView.replace("pages/StorePage.qml")
                            }
                        }
                    }
                }

                // 账户操作
                Rectangle {
                    Layout.fillWidth: true
                    // 移动端使用动态高度适配内容
                    Layout.preferredHeight: accountActionsColumn.implicitHeight + 48
                    Layout.minimumHeight: 280
                    radius: (mainWindow && mainWindow.isMobile) ? 16 : 20
                    color: Theme.colors.surface
                    border.color: Theme.colors.border
                    border.width: 1

                    ColumnLayout {
                        id: accountActionsColumn
                        anchors.fill: parent
                        anchors.margins: (mainWindow && mainWindow.isMobile) ? 16 : 24
                        spacing: (mainWindow && mainWindow.isMobile) ? 10 : 12

                        Label {
                            text: qsTr("Account Actions")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.colors.textPrimary
                        }

                        // 订单管理
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (mainWindow && mainWindow.isMobile) ? 52 : 50
                            Layout.minimumHeight: Theme.size.touchTarget  // 确保触摸目标足够大
                            radius: (mainWindow && mainWindow.isMobile) ? 10 : 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "order"
                                    size: 20
                                    color: Theme.colors.primary
                                }

                                Label {
                                    text: qsTr("Order Management")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    orderListDialog.open()
                                }
                            }
                        }

                        // 工单系统
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (mainWindow && mainWindow.isMobile) ? 52 : 50
                            Layout.minimumHeight: Theme.size.touchTarget
                            radius: (mainWindow && mainWindow.isMobile) ? 10 : 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "edit"
                                    size: 20
                                    color: Theme.colors.info
                                }

                                Label {
                                    text: qsTr("Ticket System")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ticketListDialog.open()
                                }
                            }
                        }

                        // 帮助中心
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (mainWindow && mainWindow.isMobile) ? 52 : 50
                            Layout.minimumHeight: Theme.size.touchTarget
                            radius: (mainWindow && mainWindow.isMobile) ? 10 : 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "help"
                                    size: 20
                                    color: Theme.colors.success
                                }

                                Label {
                                    text: qsTr("Help Center")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    helpCenterDialog.open()
                                }
                            }
                        }

                        // 修改密码
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (mainWindow && mainWindow.isMobile) ? 52 : 50
                            Layout.minimumHeight: Theme.size.touchTarget
                            radius: (mainWindow && mainWindow.isMobile) ? 10 : 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "key"
                                    size: 20
                                    color: Theme.colors.warning
                                }

                                Label {
                                    text: qsTr("Change Password")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    changePasswordDialog.open()
                                }
                            }
                        }

                        // 退出登录
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (mainWindow && mainWindow.isMobile) ? 52 : 50
                            Layout.minimumHeight: Theme.size.touchTarget
                            Layout.topMargin: (mainWindow && mainWindow.isMobile) ? 20 : 30
                            Layout.bottomMargin: 5
                            radius: (mainWindow && mainWindow.isMobile) ? 10 : 12
                            color: Theme.colors.warning

                            Label {
                                text: qsTr("Logout")
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.colors.textPrimary
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (authManager) {
                                        authManager.logout()
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 55 }  // ⭐ 增加底部边距防止溢出
            }
        }
    }

    // 订单列表对话框
    OrderListDialog {
        id: orderListDialog
        anchors.centerIn: parent
    }

    // 修改密码对话框
    ChangePasswordDialog {
        id: changePasswordDialog
        anchors.centerIn: parent
        // authManager 现在直接从全局上下文访问

        onAccepted: {
            // 显示成功提示
            successToast.text = qsTr("Password changed successfully")
            successToast.show()
        }
    }

    // 工单系统对话框
    TicketListDialog {
        id: ticketListDialog
        anchors.centerIn: parent
        ticketMgr: ticketManager
    }

    // 帮助中心对话框
    HelpCenterDialog {
        id: helpCenterDialog
        anchors.centerIn: parent
        sysConfigMgr: systemConfigManager  // 使用全局上下文属性
    }

    // 成功提示 Toast
    Rectangle {
        id: successToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: Math.min(parent.width * 0.8, 400)
        height: 60
        radius: Theme.radius.lg
        color: Theme.colors.success
        visible: opacity > 0
        opacity: 0

        property string text: ""

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            spacing: Theme.spacing.sm

            Label {
                text: "✓"
                font.pixelSize: 24
                color: "white"
            }

            Label {
                text: successToast.text
                font.pixelSize: Theme.typography.body1
                color: "white"
                Layout.fillWidth: true
            }
        }

        function show() {
            opacity = 1
            hideTimer.restart()
        }

        Timer {
            id: hideTimer
            interval: 3000
            onTriggered: successToast.opacity = 0
        }
    }
}
