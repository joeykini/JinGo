// components/SidebarDelegate.qml (完美优化版 - 已修复 gradient 问题)
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

ItemDelegate {
    id: control
    readonly property var mainWindow: Qt.application.topLevelWindow 

    // 公开属性
    property string pageName: ""
    property string iconSource: ""
    property alias labelText: label.text
    property bool isCurrentPage: false
    property bool collapsed: false
    property bool showBadge: false
    property string badgeText: ""

    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    Layout.fillWidth: true
    height: 64
    padding: 0
    
    // 同步 checked 状态
    checked: isCurrentPage
    
    // 背景 - 使用 Item 包含两个 Rectangle 避免 gradient null 问题
    background: Item {
        anchors.fill: parent
        
        // 底层：未选中状态（纯色）
        Rectangle {
            id: normalBg
            anchors.fill: parent
            anchors.margins: 4
            radius: 8
            color: control.hovered ? (control.isDarkMode ? "#2A2A2A" : "#F5F5F5") : "transparent"
            opacity: control.isCurrentPage ? 0 : 1
            
            Behavior on color { 
                ColorAnimation { duration: 150; easing.type: Easing.OutCubic } 
            }
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
        
        // 顶层：选中状态（仅左侧指示条，背景透明）
        Item {
            id: selectedBg
            anchors.fill: parent
            anchors.margins: 4
            opacity: control.isCurrentPage ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            // 左侧选中指示条
            Rectangle {
                width: 3
                height: parent.height - 8
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                radius: 1.5
                color: "#007BFF"

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }
        
        // 按下效果
        scale: control.pressed ? 0.98 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
    }

    // 内容
    contentItem: Item {
        implicitHeight: 60

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: 2

            // 图标容器
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignHCenter

                // 图标（背景透明）
                Image {
                    id: icon
                    source: iconSource
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    smooth: true
                    antialiasing: true

                    // 图标缩放动画
                    scale: control.isCurrentPage ? 1.1 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                }
            }

            // 标签
            Label {
                id: label
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
                font.weight: control.isCurrentPage ? Font.DemiBold : Font.Normal
                color: control.isCurrentPage ?
                       (control.isDarkMode ? "#FFFFFF" : "#007BFF") :
                       (control.isDarkMode ? "#CCCCCC" : "#666666")

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // 徽章（可选 - 放在右上角）
            Rectangle {
                Layout.preferredWidth: badgeLabel.implicitWidth + 8
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignHCenter
                radius: 8
                color: Theme.colors.error
                visible: showBadge && badgeText !== ""

                Label {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: badgeText
                    font.pixelSize: 9
                    font.bold: true
                    color: "white"
                }
            }
        }
    }
    
    // 工具提示（折叠时显示）
    ToolTip.visible: collapsed && hovered
    ToolTip.text: label.text
    ToolTip.delay: 500
}
