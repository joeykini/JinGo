import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Rectangle {
    id: loginPage

    // 主窗口引用：用 Qt.application.topLevelWindow 更安全，防止直接访问 root 对象失败
    readonly property var mainWindow: Qt.application.topLevelWindow || null

    // 获取深色模式标识：避免窗口未加载时的 undefined
    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    // 页面背景色随全局主题变化 - 鹅黄色
    color: Theme.colors.pageBackground

    // 响应式判断
    readonly property bool isMobile: mainWindow ? mainWindow.isMobile : false

    // 隐藏侧边栏，加载 Guest 配置
    Component.onCompleted: {
        if (mainWindow) {
            mainWindow.sidebarCollapsed = true
        }
        // 加载 xboard/v2board 配置（验证码、邮箱验证等设置）
        if (!systemConfigManager.guestConfigLoaded) {
            systemConfigManager.fetchGuestConfig()
        }
    }

    // 使用 Flickable 让整个页面可滚动，避免键盘挤压
    Flickable {
        id: flickable
        anchors.fill: parent
        // Qt 会自动处理 iOS 安全区域，无需手动设置边距
        contentHeight: contentColumn.height + 40  // 内容高度 + 底部边距
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // 启用滚动条（仅移动端显示）
        ScrollBar.vertical: ScrollBar {
            visible: isMobile && flickable.contentHeight > flickable.height
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 0

            // 顶部弹性间距（桌面端居中，移动端固定）
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: isMobile ? 40 : Math.max(60, (flickable.height - 600) / 2)
            }

            // 主要内容区域
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                // 桌面端采用固定宽度，移动端保持自适应
                Layout.preferredWidth: mainWindow && mainWindow.isDesktop ? 400 : flickable.width - 40
                spacing: 16

                Image {
                    source: "qrc:/images/logo.png"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    Layout.alignment: Qt.AlignHCenter
                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    text: qsTr("Welcome to JinGo")
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 20
                    font.bold: true
                    color: isDarkMode ? "white" : "#333333"
                }

                // 登录/注册区域封装组件
                AuthView {
                    id: authView
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                }

                // 底部链接区域（现在在滚动内容中）
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    Layout.bottomMargin: 40
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    // 根据授权配置决定是否显示群组入口
                    property bool hasTelegram: bundleConfig.telegramUrl && bundleConfig.telegramUrl.length > 0
                    property bool hasDiscord: bundleConfig.discordUrl && bundleConfig.discordUrl.length > 0
                    property bool hasAnyGroup: hasTelegram || hasDiscord

                    Label {
                        visible: parent.hasAnyGroup
                        text: qsTr("Have any questions? Visit")
                        font.pixelSize: 14
                        color: isDarkMode ? "#CCCCCC" : "#666666"
                    }

                    Label {
                        visible: parent.hasTelegram
                        text: "Telegram"
                        font.pixelSize: 14
                        font.underline: true
                        color: "#0088CC"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(bundleConfig.telegramUrl)

                            onEntered: parent.color = "#006699"
                            onExited: parent.color = "#0088CC"
                        }
                    }

                    Label {
                        visible: parent.hasTelegram && parent.hasDiscord
                        text: "/"
                        font.pixelSize: 14
                        color: isDarkMode ? "#CCCCCC" : "#666666"
                    }

                    Label {
                        visible: parent.hasDiscord
                        text: "Discord"
                        font.pixelSize: 14
                        font.underline: true
                        color: "#5865F2"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(bundleConfig.discordUrl)

                            onEntered: parent.color = "#4752C4"
                            onExited: parent.color = "#5865F2"
                        }
                    }

                    Label {
                        visible: parent.hasAnyGroup
                        text: qsTr("群组")
                        font.pixelSize: 14
                        color: isDarkMode ? "#CCCCCC" : "#666666"
                    }
                }
            }
        }
    }
}