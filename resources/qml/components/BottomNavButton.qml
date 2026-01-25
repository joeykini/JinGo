// components/BottomNavButton.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

ItemDelegate {
    id: navButton

    property string iconSource: ""
    property string labelText: ""
    property bool isActive: false
    property bool isDarkMode: false

    onClicked: {
    }

    background: Rectangle {
        color: navButton.pressed ?
            Theme.colors.cardPressed :
            (navButton.hovered ?
                Theme.colors.cardHover : "transparent")

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    contentItem: ColumnLayout {
        spacing: 4

        // 图标容器 (放大到1.2倍)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 34  // 28 * 1.2 ≈ 34
            Layout.preferredHeight: 34

            // 活跃状态背景
            Rectangle {
                anchors.fill: parent
                radius: 17  // 34 / 2 = 17
                color: isActive ?
                    Theme.colors.navButtonBackground : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            // 图标
            Image {
                source: iconSource
                anchors.centerIn: parent
                width: 24  // 20 * 1.2 = 24
                height: 24
                smooth: true
                antialiasing: true
                opacity: isActive ? 1.0 : 0.6

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }

        // 标签
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: labelText
            font.pixelSize: 11
            font.weight: isActive ? Font.Medium : Font.Normal
            color: isActive ?
                Theme.colors.navButtonText :
                Theme.colors.bottomNavTextDefault

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }
}
