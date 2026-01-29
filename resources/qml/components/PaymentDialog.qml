// components/PaymentDialog.qml - 支付方式选择对话框
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Dialog {
    id: paymentDialog

    property string planName: ""
    property string planPrice: ""
    property string currency: "¥"
    property int planId: 0
    property var paymentMethods: []
    property int selectedPaymentMethod: -1
    property bool isProcessing: false

    signal paymentConfirmed(int planId, var paymentMethod)

    title: qsTr("Select Payment Method")
    modal: true
    standardButtons: Dialog.NoButton

    width: Math.min(500, parent ? parent.width * 0.9 : 500)
    height: Math.min(600, parent ? parent.height * 0.8 : 600)

    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    background: Rectangle {
        color: Theme.colors.surface
        radius: Theme.radius.lg
        border.width: 1
        border.color: Theme.colors.border
    }

    header: Rectangle {
        height: 60
        color: Theme.colors.surface
        radius: Theme.radius.lg

        // 只有顶部圆角
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
                text: paymentDialog.title
                font.pixelSize: Theme.typography.h4
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
            }

            Label {
                text: qsTr("Plan: %1 - %2%3").arg(planName).arg(currency).arg(planPrice)
                font.pixelSize: Theme.typography.body2
                color: Theme.colors.textSecondary
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing.md

        // 顶部间距，避免覆盖 header
        Item {
            Layout.preferredHeight: 10
        }

        // 支付方式列表
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: paymentMethodList
                model: paymentMethods
                spacing: Theme.spacing.sm

                delegate: Rectangle {
                    width: paymentMethodList.width
                    height: 80
                    radius: Theme.radius.md
                    color: mouseArea.containsMouse || selectedPaymentMethod === index ?
                           Theme.alpha(Theme.colors.primary, 0.1) : Theme.colors.background
                    border.width: selectedPaymentMethod === index ? 2 : 1
                    border.color: selectedPaymentMethod === index ?
                                  Theme.colors.primary : Theme.colors.border

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            selectedPaymentMethod = index
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.md
                        spacing: Theme.spacing.sm

                        // 支付图标 - 左对齐，固定宽度
                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignVCenter
                            radius: 22
                            color: Theme.alpha(Theme.colors.primary, 0.2)

                            Label {
                                anchors.centerIn: parent
                                text: getPaymentIcon(modelData.type || modelData.payment)
                                font.pixelSize: 22
                            }
                        }

                        // 支付方式信息 - 左对齐，填充剩余空间
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Label {
                                text: modelData.name || qsTr("Unknown Method")
                                font.pixelSize: Theme.typography.body1
                                font.weight: Theme.typography.weightMedium
                                color: Theme.colors.textPrimary
                                Layout.alignment: Qt.AlignLeft
                            }

                            Label {
                                text: getPaymentDescription(modelData.type || modelData.payment)
                                font.pixelSize: Theme.typography.body2
                                color: Theme.colors.textSecondary
                                Layout.alignment: Qt.AlignLeft
                            }
                        }

                        // 选中标记 - 右对齐，固定宽度
                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: selectedPaymentMethod === index ?
                                   Theme.colors.primary : "transparent"
                            border.width: 2
                            border.color: selectedPaymentMethod === index ?
                                          Theme.colors.primary : Theme.colors.divider

                            Label {
                                anchors.centerIn: parent
                                text: "✓"
                                font.pixelSize: 14
                                color: "white"
                                visible: selectedPaymentMethod === index
                            }

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }
                    }
                }
            }
        }

        // 加载状态
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            spacing: Theme.spacing.sm
            visible: paymentMethods.length === 0 && !isProcessing

            Label {
                text: "📭"
                font.pixelSize: 32
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("No payment methods available")
                font.pixelSize: Theme.typography.body2
                color: Theme.colors.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // 处理中状态
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            spacing: Theme.spacing.sm
            visible: isProcessing

            BusyIndicator {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                running: isProcessing
            }

            Label {
                text: qsTr("Processing payment...")
                font.pixelSize: Theme.typography.body2
                color: Theme.colors.textSecondary
            }
        }
    }

    footer: DialogButtonBox {
        background: Rectangle {
            color: Theme.colors.surface
            radius: Theme.radius.lg

            // 只有底部圆角
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
            enabled: !isProcessing
        }

        CustomButton {
            text: isProcessing ? qsTr("Processing...") : qsTr("Confirm Payment")
            variant: "primary"
            enabled: selectedPaymentMethod >= 0 && !isProcessing
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
    }

    onOpened: {
        selectedPaymentMethod = -1  // 重置选择
    }

    onAccepted: {
        if (selectedPaymentMethod >= 0 && selectedPaymentMethod < paymentMethods.length) {
            var method = paymentMethods[selectedPaymentMethod]
            var methodId = method.id || method.payment || 0
            paymentConfirmed(planId, methodId)
        }
    }

    // 辅助函数
    function getPaymentIcon(type) {
        switch(type) {
            case "alipay": return "💳"
            case "wechat": return "💚"
            case "stripe": return "💵"
            case "paypal": return "🅿️"
            case "bank": return "🏦"
            case "crypto": return "₿"
            default: return "💰"
        }
    }

    function getPaymentDescription(type) {
        switch(type) {
            case "alipay": return qsTr("Alipay")
            case "wechat": return qsTr("WeChat Pay")
            case "stripe": return qsTr("Credit/Debit Card")
            case "paypal": return qsTr("PayPal")
            case "bank": return qsTr("Bank Transfer")
            case "crypto": return qsTr("Cryptocurrency")
            default: return qsTr("Online Payment")
        }
    }
}
