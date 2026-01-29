// qml/components/ServerCard.qml (FIXED)
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

ItemDelegate {
    id: serverCard

    property string title: qsTr("Plan Name")
    property string subtitle: qsTr("Price / Period")
    property string features: qsTr("Unlimited traffic, 5 devices")
    property bool isDarkMode: false

    width: parent.width
    height: 150
    // REMOVED: radius: 12 // ItemDelegate 不支持 radius 属性

    background: Rectangle { // 必须在 background 内部设置 radius
        radius: 12
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15 // FIX: 使用 anchors.margins
        spacing: 10

        Label {
            text: serverCard.title
            font.pixelSize: 20
            font.bold: true
            color: Theme.colors.textPrimary
        }

        Label {
            text: serverCard.subtitle
            font.pixelSize: 16
            color: Theme.colors.primary
        }

        Label {
            text: serverCard.features
            font.pixelSize: 12
            Layout.fillHeight: true
            color: Theme.colors.textSecondary
            wrapMode: Text.WordWrap
        }

        CustomButton {
            text: qsTr("Purchase Now")
            buttonColor: Theme.colors.success
            Layout.preferredWidth: 120
            Layout.alignment: Qt.AlignRight
        }
    }
}