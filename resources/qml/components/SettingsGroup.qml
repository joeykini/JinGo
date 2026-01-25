// components/SettingsGroup.qml (设置分组组件)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

// 设置分组容器
ColumnLayout {
    id: settingsGroup

    property string title: ""
    property string description: ""
    property bool collapsible: false
    property bool collapsed: false

    Layout.fillWidth: true
    spacing: Theme.spacing.xs

    // 分组标题
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: collapsible ? 48 : 40
        color: collapsible && hoverArea.containsMouse ?
               Theme.alpha(Theme.colors.primary, 0.05) : "transparent"
        radius: Theme.radius.xs

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            enabled: collapsible
            hoverEnabled: collapsible
            cursorShape: collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (collapsible) collapsed = !collapsed
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.xs
            anchors.rightMargin: Theme.spacing.xs
            spacing: Theme.spacing.sm

            // 折叠图标
            Label {
                visible: collapsible
                text: collapsed ? "▶" : "▼"
                font.pixelSize: Theme.typography.caption
                color: Theme.colors.textSecondary
                Layout.preferredWidth: 16
            }

            // 标题和描述
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.xxs

                Label {
                    text: settingsGroup.title
                    font.pixelSize: Theme.typography.h4
                    font.weight: Theme.typography.weightBold
                    color: Theme.colors.textPrimary
                }

                Label {
                    visible: settingsGroup.description !== ""
                    text: settingsGroup.description
                    font.pixelSize: Theme.typography.caption
                    color: Theme.colors.textTertiary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    // 内容区域
    ColumnLayout {
        id: contentArea
        Layout.fillWidth: true
        spacing: 0
        visible: !collapsed

        // 子项会被自动添加到这里
    }

    // 分隔线
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: Theme.spacing.md
        color: Theme.colors.divider
        visible: !collapsed
    }

    default property alias content: contentArea.children
}