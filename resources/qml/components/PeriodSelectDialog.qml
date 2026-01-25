// components/PeriodSelectDialog.qml - 订阅周期选择对话框
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Dialog {
    id: periodSelectDialog

    property string planName: ""
    property int planId: 0
    property var periodOptions: []  // [{period: "month_price", name: "月付", price: "9.99"}, ...]
    property int selectedIndex: 0
    property string currency: "¥"

    signal periodConfirmed(int planId, string period, string periodName, string price)

    title: qsTr("Select Subscription Period")
    modal: true
    standardButtons: Dialog.NoButton

    width: Math.min(400, parent ? parent.width * 0.85 : 400)
    height: Math.min(500, parent ? parent.height * 0.7 : 500)

    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    background: Rectangle {
        color: Theme.colors.surface
        radius: Theme.radius.lg
        border.width: 1
        border.color: Theme.colors.border
    }

    header: Rectangle {
        height: 70
        color: Theme.colors.surface
        radius: Theme.radius.lg

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.radius.lg
            color: parent.color
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            spacing: Theme.spacing.xs

            Label {
                text: periodSelectDialog.title
                font.pixelSize: Theme.typography.h4
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
            }

            Label {
                text: qsTr("Plan: %1").arg(planName)
                font.pixelSize: Theme.typography.body2
                color: Theme.colors.textSecondary
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing.md

        Label {
            text: qsTr("Choose your billing cycle:")
            font.pixelSize: Theme.typography.body1
            color: Theme.colors.textPrimary
            Layout.fillWidth: true
        }

        // 周期选项列表
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: periodListView
                model: periodOptions
                spacing: Theme.spacing.sm

                delegate: Rectangle {
                    width: periodListView.width
                    height: 70
                    radius: Theme.radius.md
                    color: periodMouseArea.containsMouse || selectedIndex === index ?
                           Theme.alpha(Theme.colors.primary, 0.1) : Theme.colors.background
                    border.width: selectedIndex === index ? 2 : 1
                    border.color: selectedIndex === index ?
                                  Theme.colors.primary : Theme.colors.border

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    MouseArea {
                        id: periodMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            selectedIndex = index
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.md
                        spacing: Theme.spacing.sm

                        // 选择指示器 - 左对齐，固定宽度
                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: selectedIndex === index ?
                                   Theme.colors.primary : "transparent"
                            border.width: 2
                            border.color: selectedIndex === index ?
                                          Theme.colors.primary : Theme.colors.divider

                            Label {
                                anchors.centerIn: parent
                                text: "✓"
                                font.pixelSize: 14
                                color: "white"
                                visible: selectedIndex === index
                            }
                        }

                        // 周期信息 - 左对齐，填充剩余空间
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Label {
                                text: modelData.name || qsTr("Unknown Period")
                                font.pixelSize: Theme.typography.body1
                                font.weight: Theme.typography.weightMedium
                                color: Theme.colors.textPrimary
                                Layout.alignment: Qt.AlignLeft
                            }

                            Label {
                                text: modelData.description || ""
                                font.pixelSize: Theme.typography.caption
                                color: Theme.colors.textSecondary
                                visible: modelData.description && modelData.description !== ""
                                Layout.alignment: Qt.AlignLeft
                            }
                        }

                        // 价格 - 右对齐，固定宽度
                        ColumnLayout {
                            Layout.preferredWidth: 90
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            spacing: 0

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: 0

                                Label {
                                    text: currency
                                    font.pixelSize: 14
                                    font.weight: Theme.typography.weightBold
                                    color: Theme.colors.primary
                                }

                                Label {
                                    text: modelData.price || "0"
                                    font.pixelSize: 20
                                    font.weight: Theme.typography.weightBold
                                    color: Theme.colors.primary
                                }
                            }

                            // 如果有折扣，显示月均价
                            Label {
                                visible: modelData.monthlyPrice && modelData.monthlyPrice !== modelData.price
                                text: qsTr("≈ %1%2/mo").arg(currency).arg(modelData.monthlyPrice || "")
                                font.pixelSize: Theme.typography.caption
                                color: Theme.colors.success
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }
                }
            }
        }

        // 空状态
        Label {
            visible: periodOptions.length === 0
            text: qsTr("No pricing options available")
            font.pixelSize: Theme.typography.body2
            color: Theme.colors.textSecondary
            Layout.alignment: Qt.AlignHCenter
        }
    }

    footer: DialogButtonBox {
        background: Rectangle {
            color: Theme.colors.surface
            radius: Theme.radius.lg

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Theme.radius.lg
                color: parent.color
            }
        }

        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }

        CustomButton {
            text: qsTr("Continue")
            variant: "primary"
            enabled: periodOptions.length > 0 && selectedIndex >= 0 && selectedIndex < periodOptions.length
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
    }

    onAccepted: {
        if (selectedIndex >= 0 && selectedIndex < periodOptions.length) {
            var option = periodOptions[selectedIndex]
            periodConfirmed(planId, option.period, option.name, option.price)
        }
    }

    onOpened: {
        // 默认选择第一个
        selectedIndex = 0
    }
}
