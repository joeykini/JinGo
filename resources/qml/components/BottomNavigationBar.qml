// components/BottomNavigationBar.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

Rectangle {
    id: bottomNav

    property string currentPage: "connection"
    property bool isDarkMode: false
    property bool isConnected: false

    signal navigateToPage(string page, string qmlFile)

    // 导航栏高度，不包含安全区域
    // 导航栏底部应与系统安全区域顶部对齐
    readonly property int navBarHeight: 68
    height: navBarHeight
    color: Theme.colors.navButtonBackground

    Component.onCompleted: {
    }

    // 顶部边框/阴影
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.colors.divider
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: navBarHeight
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 0

        // 服务器
        BottomNavButton {
            Layout.fillWidth: true
            Layout.fillHeight: true

            iconSource: "qrc:/icons/services.png"
            labelText: qsTr("Servers")
            isActive: currentPage === "servers"
            isDarkMode: bottomNav.isDarkMode

            onClicked: navigateToPage("servers", "pages/ServerListPage.qml")
        }

        // 订阅与套餐
        BottomNavButton {
            Layout.fillWidth: true
            Layout.fillHeight: true

            iconSource: "qrc:/icons/store.png"
            labelText: qsTr("Subscription")
            isActive: currentPage === "store"
            isDarkMode: bottomNav.isDarkMode

            onClicked: navigateToPage("store", "pages/StorePage.qml")
        }

        // 中间大圆按钮 - 连接
        Item {
            Layout.preferredWidth: 90
            Layout.fillHeight: true

            // 背景圆形
            Rectangle {
                id: centerButton
                width: 64
                height: 64
                radius: 32
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10

                // 透明背景
                color: "transparent"

                // 图标
                Image {
                    source: isConnected ?
                        "qrc:/icons/connected.png" : "qrc:/icons/disconnected.png"
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    smooth: true
                    antialiasing: true

                    // 连接时的脉冲动画
                    SequentialAnimation on scale {
                        running: isConnected
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.1; duration: 1000; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.1; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                    }
                }

                // 按下效果
                scale: centerButtonArea.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                MouseArea {
                    id: centerButtonArea
                    anchors.fill: parent
                    onClicked: navigateToPage("connection", "pages/ConnectionPage.qml")
                }
            }

            // 底部标签
            Label {
                text: qsTr("Connect")
                font.pixelSize: 11
                font.weight: Font.Medium
                color: currentPage === "connection" ?
                    Theme.colors.bottomNavTextActive :
                    Theme.colors.bottomNavTextDefault
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
        }

        // 个人资料（原"我的"，改成"资料"并移到前面）
        BottomNavButton {
            Layout.fillWidth: true
            Layout.fillHeight: true

            iconSource: "qrc:/icons/user.png"
            labelText: qsTr("Profile")  // ⭐ 修改：我的 → 资料
            isActive: currentPage === "profile"
            isDarkMode: bottomNav.isDarkMode

            onClicked: navigateToPage("profile", "pages/ProfilePage.qml")
        }

        // 设置（移到最后）
        BottomNavButton {
            Layout.fillWidth: true
            Layout.fillHeight: true

            iconSource: "qrc:/icons/settings.png"
            labelText: qsTr("Settings")
            isActive: currentPage === "settings"
            isDarkMode: bottomNav.isDarkMode

            onClicked: navigateToPage("settings", "pages/SettingsPage.qml")
        }
    }
}
