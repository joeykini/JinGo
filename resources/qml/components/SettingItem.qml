// components/SettingItem.qml (设置项组件)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

// 单个设置项
Rectangle {
    id: settingItem

    property string label: ""
    property string description: ""
    property alias control: controlContainer.data

    Layout.fillWidth: true
    Layout.preferredHeight: description !== "" ? 72 : 56
    radius: Theme.radius.sm
    color: hoverArea.containsMouse ? Theme.colors.surfaceHover : "transparent"

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: function(mouse) { mouse.accepted = false }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.md
        anchors.rightMargin: Theme.spacing.md
        spacing: Theme.spacing.md

        // 标签和描述
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.xxs

            Label {
                text: settingItem.label
                font.pixelSize: Theme.typography.body1
                color: Theme.colors.textPrimary
            }

            Label {
                visible: settingItem.description !== ""
                text: settingItem.description
                font.pixelSize: Theme.typography.caption
                color: Theme.colors.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // 控件容器
        Item {
            id: controlContainer
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}