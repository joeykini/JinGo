// qml/components/StatusIndicator.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

Item {
    id: root

    readonly property var mainWindow: Qt.application.topLevelWindow
    property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    property string status: "disconnected"          // connected, connecting, disconnected, error
    property string statusText: ""

    implicitWidth: 100
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: getStatusColor()

        RowLayout {
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: getStatusIcon()
                font.pixelSize: 18
                color: Theme.colors.textPrimary
            }
            Text {
                text: root.statusText || getDefaultStatusText()
                font.pixelSize: 14
                color: Theme.colors.textPrimary
                font.weight: Font.Medium
            }
        }
    }

    // 辅助函数 (简化)
    function getStatusColor() {
        switch(root.status) {
            case "connected": return Theme.colors.accentGold  // 金黄色
            case "connecting": return Theme.colors.warning  // 橙色
            case "error": return Theme.colors.error       // 红色
            default: return Theme.colors.info            // 蓝色
        }
    }

    function getStatusIcon() {
        switch(root.status) {
            case "connected": return "✓"
            case "connecting": return "..."
            case "error": return "✗"
            default: return "○"
        }
    }

    function getDefaultStatusText() {
        switch(root.status) {
            case "connected": return qsTr("Connected")
            case "connecting": return qsTr("Connecting")
            case "error": return qsTr("Error")
            default: return qsTr("Not Connected")
        }
    }
}
