// components/OrderListDialog.qml - 订单列表对话框 (现代风格)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Dialog {
    id: orderListDialog

    property var orderList: []
    property bool isLoading: false
    property string errorMessage: ""
    property var paymentMethods: []
    property bool isLoadingPayment: false

    // 当前页面状态: "list", "detail", "payment"
    property string currentView: "list"
    property var currentOrder: null

    title: qsTr("Order Management")
    modal: true
    standardButtons: Dialog.NoButton

    // 移动端检测
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios" ||
                                     (parent ? parent.width < 768 : false)

    // 移动端接近全屏，桌面端保持合理大小
    width: isMobile ? (parent ? parent.width * 0.95 : 350) : Math.min(700, parent ? parent.width * 0.9 : 700)
    height: isMobile ? (parent ? parent.height * 0.9 : 500) : Math.min(600, parent ? parent.height * 0.8 : 600)

    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    background: Rectangle {
        color: Theme.colors.surface
        radius: Theme.radius.lg
        border.width: 1
        border.color: Theme.colors.border
    }

    header: Rectangle {
        height: isMobile ? 52 : 56
        color: Theme.colors.surface
        radius: isMobile ? Theme.radius.md : Theme.radius.lg

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.radius.lg
            color: parent.color
        }

        // 底部分隔线
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.colors.divider
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.lg
            anchors.rightMargin: Theme.spacing.lg
            spacing: Theme.spacing.md

            // 返回按钮 (非列表页显示)
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.sm
                color: backMouseArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"
                visible: currentView !== "list"

                Label {
                    text: "←"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: Theme.colors.textPrimary
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentView = "list"
                        currentOrder = null
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Label {
                text: {
                    if (currentView === "detail") return qsTr("Order Detail")
                    if (currentView === "payment") return qsTr("Select Payment")
                    return qsTr("Order Management")
                }
                font.pixelSize: Theme.typography.body1
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
                Layout.fillWidth: true
            }

            // 刷新按钮 (仅列表页显示)
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.sm
                color: refreshMouseArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"
                visible: currentView === "list"

                IconSymbol {
                    id: refreshIcon
                    icon: "refresh"
                    size: 18
                    color: isLoading ? Theme.colors.primary : Theme.colors.textSecondary
                    anchors.centerIn: parent

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: isLoading
                    }
                }

                MouseArea {
                    id: refreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !isLoading
                    onClicked: loadOrders()
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // 关闭按钮
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.sm
                color: closeMouseArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"

                Label {
                    text: "×"
                    font.pixelSize: 20
                    color: Theme.colors.textSecondary
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: orderListDialog.close()
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    contentItem: Item {
        id: contentContainer

        // 错误提示 (带动画)
        Rectangle {
            id: errorBanner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacing.md
            height: errorMessage !== "" ? 52 : 0
            radius: Theme.radius.md
            color: Theme.alpha(Theme.colors.error, 0.08)
            border.width: 1
            border.color: Theme.alpha(Theme.colors.error, 0.3)
            visible: errorMessage !== ""
            clip: true
            opacity: errorMessage !== "" ? 1 : 0

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.md
                spacing: Theme.spacing.sm

                Label {
                    text: "⚠"
                    font.pixelSize: 18
                    color: Theme.colors.error
                }

                Label {
                    text: errorMessage
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.error
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        // 订单列表
        ScrollView {
            anchors.fill: parent
            anchors.margins: 0
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !isLoading && orderList.length > 0 && currentView === "list"

            ListView {
                id: orderListView
                model: orderList
                spacing: Theme.spacing.sm

                delegate: Rectangle {
                    id: orderCard
                    width: orderListView.width
                    height: orderContentCol.implicitHeight + 24
                    radius: Theme.radius.md
                    color: orderCardArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.background
                    border.width: 1
                    border.color: orderCardArea.containsMouse ? Theme.colors.primary : Theme.colors.border

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    MouseArea {
                        id: orderCardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentOrder = modelData
                            currentView = "detail"
                        }
                    }

                    ColumnLayout {
                        id: orderContentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 12
                        spacing: 8

                        // 订单头部：订单号和状态
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.md

                            Label {
                                text: qsTr("Order #%1").arg(modelData.trade_no || "N/A")
                                font.pixelSize: Theme.typography.body2
                                font.weight: Theme.typography.weightMedium
                                color: Theme.colors.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            // 订单状态标签 - 现代胶囊设计
                            Rectangle {
                                Layout.preferredWidth: statusLabelText.implicitWidth + 20
                                Layout.preferredHeight: 26
                                radius: 13
                                color: Theme.alpha(getStatusColor(modelData.status), 0.12)

                                Label {
                                    id: statusLabelText
                                    text: getStatusText(modelData.status)
                                    font.pixelSize: Theme.typography.small
                                    font.weight: Theme.typography.weightMedium
                                    color: getStatusColor(modelData.status)
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.colors.divider
                        }

                        // 订单详情 - 简化布局
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // 套餐名称
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: qsTr("Plan:")
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textSecondary
                                }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: getPlanName(modelData)
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textPrimary
                                }
                            }

                            // 金额
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: qsTr("Amount:")
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textSecondary
                                }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: formatAmount(modelData.total_amount)
                                    font.pixelSize: Theme.typography.body2
                                    font.weight: Theme.typography.weightMedium
                                    color: Theme.colors.primary
                                }
                            }

                            // 创建时间
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: qsTr("Created:")
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textSecondary
                                }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: formatDateTime(modelData.created_at)
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textPrimary
                                }
                            }

                            // 支付时间（仅已支付订单显示）
                            RowLayout {
                                Layout.fillWidth: true
                                visible: modelData.status === 3 && modelData.paid_at
                                Label {
                                    text: qsTr("Paid:")
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textSecondary
                                }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: formatDateTime(modelData.paid_at)
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.success
                                }
                            }
                        }

                        // 操作按钮（待支付订单显示支付和取消按钮）
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.spacing.xs
                            spacing: Theme.spacing.sm
                            visible: modelData.status === 0

                            Item { Layout.fillWidth: true }

                            CustomButton {
                                text: qsTr("Cancel")
                                variant: "outline"
                                enabled: !orderManager.isProcessing
                                onClicked: {
                                    cancelOrder(modelData.trade_no)
                                }
                            }

                            CustomButton {
                                text: qsTr("Pay Now")
                                variant: "primary"
                                enabled: !orderManager.isProcessing
                                onClicked: {
                                    currentOrder = modelData
                                    currentView = "payment"
                                    loadPaymentMethods()
                                }
                            }
                        }

                        // 查看详情按钮（非待支付订单）
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.spacing.xs
                            spacing: Theme.spacing.sm
                            visible: modelData.status !== 0

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: detailLabelText.implicitWidth + 24
                                Layout.preferredHeight: 32
                                radius: Theme.radius.sm
                                color: detailBtnArea.containsMouse ? Theme.alpha(Theme.colors.primary, 0.08) : "transparent"
                                border.width: 1
                                border.color: Theme.colors.border

                                Label {
                                    id: detailLabelText
                                    text: qsTr("View Details")
                                    font.pixelSize: Theme.typography.caption
                                    color: Theme.colors.primary
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: detailBtnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        currentOrder = modelData
                                        currentView = "detail"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ========== 订单详情视图 ==========
        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: "transparent"
            visible: currentView === "detail" && currentOrder

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacing.md

                // 订单状态大标签 - 现代风格
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: Theme.radius.lg
                    color: Theme.alpha(getStatusColor(currentOrder ? currentOrder.status : 0), 0.08)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: getStatusColor(currentOrder ? currentOrder.status : 0)
                            }

                            Label {
                                text: getStatusText(currentOrder ? currentOrder.status : 0)
                                font.pixelSize: Theme.typography.h4
                                font.weight: Theme.typography.weightBold
                                color: getStatusColor(currentOrder ? currentOrder.status : 0)
                            }
                        }

                        Label {
                            text: qsTr("Order #%1").arg(currentOrder ? currentOrder.trade_no : "")
                            font.pixelSize: Theme.typography.caption
                            color: Theme.colors.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // 订单详情卡片
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radius.md
                    color: Theme.colors.background
                    border.width: 1
                    border.color: Theme.colors.border

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.md
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.spacing.lg

                            // 套餐信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.sm

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 4
                                        height: 16
                                        radius: 2
                                        color: Theme.colors.primary
                                    }
                                    Label {
                                        text: qsTr("Plan Information")
                                        font.pixelSize: Theme.typography.body2
                                        font.weight: Theme.typography.weightBold
                                        color: Theme.colors.textPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { text: qsTr("Plan Name:"); color: Theme.colors.textSecondary; font.pixelSize: Theme.typography.body2 }
                                        Item { Layout.fillWidth: true }
                                        Label { text: currentOrder ? getPlanName(currentOrder) : ""; color: Theme.colors.textPrimary; font.pixelSize: Theme.typography.body2 }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { text: qsTr("Period:"); color: Theme.colors.textSecondary; font.pixelSize: Theme.typography.body2 }
                                        Item { Layout.fillWidth: true }
                                        Label { text: currentOrder ? formatPeriod(currentOrder.period) : ""; color: Theme.colors.textPrimary; font.pixelSize: Theme.typography.body2 }
                                    }
                                }
                            }

                            // 金额信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.sm

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 4
                                        height: 16
                                        radius: 2
                                        color: Theme.colors.success
                                    }
                                    Label {
                                        text: qsTr("Payment Information")
                                        font.pixelSize: Theme.typography.body2
                                        font.weight: Theme.typography.weightBold
                                        color: Theme.colors.textPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { text: qsTr("Original Price:"); color: Theme.colors.textSecondary; font.pixelSize: Theme.typography.body2 }
                                        Item { Layout.fillWidth: true }
                                        Label { text: formatAmount(currentOrder ? currentOrder.total_amount : 0); color: Theme.colors.textPrimary; font.pixelSize: Theme.typography.body2 }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: currentOrder && currentOrder.discount_amount > 0
                                        Label { text: qsTr("Discount:"); color: Theme.colors.textSecondary; font.pixelSize: Theme.typography.body2 }
                                        Item { Layout.fillWidth: true }
                                        Label { text: "-" + formatAmount(currentOrder ? currentOrder.discount_amount : 0); color: Theme.colors.success; font.pixelSize: Theme.typography.body2 }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { text: qsTr("Final Amount:"); color: Theme.colors.textPrimary; font.pixelSize: Theme.typography.body2; font.weight: Theme.typography.weightBold }
                                        Item { Layout.fillWidth: true }
                                        Label { text: formatAmount(currentOrder ? (currentOrder.total_amount - (currentOrder.discount_amount || 0)) : 0); color: Theme.colors.primary; font.pixelSize: Theme.typography.h4; font.weight: Theme.typography.weightBold }
                                    }
                                }
                            }

                            // 时间信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.sm

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 4
                                        height: 16
                                        radius: 2
                                        color: Theme.colors.info
                                    }
                                    Label {
                                        text: qsTr("Time Information")
                                        font.pixelSize: Theme.typography.body2
                                        font.weight: Theme.typography.weightBold
                                        color: Theme.colors.textPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { text: qsTr("Created:"); color: Theme.colors.textSecondary; font.pixelSize: Theme.typography.body2 }
                                        Item { Layout.fillWidth: true }
                                        Label { text: formatDateTime(currentOrder ? currentOrder.created_at : 0); color: Theme.colors.textPrimary; font.pixelSize: Theme.typography.body2 }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: currentOrder && currentOrder.paid_at
                                        Label { text: qsTr("Paid:"); color: Theme.colors.textSecondary; font.pixelSize: Theme.typography.body2 }
                                        Item { Layout.fillWidth: true }
                                        Label { text: formatDateTime(currentOrder ? currentOrder.paid_at : 0); color: Theme.colors.success; font.pixelSize: Theme.typography.body2 }
                                    }
                                }
                            }
                        }
                    }
                }

                // 操作按钮 (待支付订单)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.md
                    visible: currentOrder && currentOrder.status === 0

                    CustomButton {
                        text: qsTr("Cancel Order")
                        variant: "outline"
                        Layout.fillWidth: true
                        enabled: !orderManager.isProcessing
                        onClicked: {
                            cancelOrder(currentOrder.trade_no)
                            currentView = "list"
                            currentOrder = null
                        }
                    }

                    CustomButton {
                        text: qsTr("Pay Now")
                        variant: "primary"
                        Layout.fillWidth: true
                        enabled: !orderManager.isProcessing
                        onClicked: {
                            currentView = "payment"
                            loadPaymentMethods()
                        }
                    }
                }
            }
        }

        // ========== 支付方式选择视图 ==========
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            color: "transparent"
            visible: currentView === "payment" && currentOrder

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacing.md

                // 订单金额显示 - 现代风格
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    radius: Theme.radius.lg
                    color: Theme.colors.background
                    border.width: 1
                    border.color: Theme.colors.border

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Label {
                            text: qsTr("Amount to Pay")
                            font.pixelSize: Theme.typography.body2
                            color: Theme.colors.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: formatAmount(currentOrder ? (currentOrder.total_amount - (currentOrder.discount_amount || 0)) : 0)
                            font.pixelSize: 36
                            font.weight: Theme.typography.weightBold
                            color: Theme.colors.primary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // 支付方式标题
                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 4
                        height: 16
                        radius: 2
                        color: Theme.colors.primary
                    }
                    Label {
                        text: qsTr("Select Payment Method")
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightBold
                        color: Theme.colors.textPrimary
                    }
                }

                // 加载状态
                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: isLoadingPayment
                    visible: isLoadingPayment
                }

                // 支付方式网格
                GridLayout {
                    Layout.fillWidth: true
                    // 移动端使用单列，桌面端使用双列
                    columns: isMobile ? 1 : 2
                    rowSpacing: isMobile ? Theme.spacing.xs : Theme.spacing.sm
                    columnSpacing: Theme.spacing.sm
                    visible: !isLoadingPayment && paymentMethods.length > 0

                    Repeater {
                        model: paymentMethods

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: Theme.radius.md
                            color: paymentArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.background
                            border.width: 1
                            border.color: paymentArea.containsMouse ? Theme.colors.primary : Theme.colors.border

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 150 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.spacing.md
                                spacing: Theme.spacing.md

                                // 支付图标 - 纯字体图标
                                Label {
                                    text: getPaymentIcon(modelData.method || modelData.id)
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    color: getPaymentColor(modelData.method || modelData.id)
                                    Layout.preferredWidth: 36
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: modelData.name || modelData.method || qsTr("Unknown")
                                        font.pixelSize: Theme.typography.body2
                                        font.weight: Theme.typography.weightMedium
                                        color: Theme.colors.textPrimary
                                    }

                                    Label {
                                        text: modelData.fee ? qsTr("Fee: %1%").arg(modelData.fee) : ""
                                        font.pixelSize: Theme.typography.caption
                                        color: Theme.colors.textSecondary
                                        visible: modelData.fee && modelData.fee > 0
                                    }
                                }

                                Label {
                                    text: "→"
                                    font.pixelSize: 16
                                    color: Theme.colors.textTertiary
                                }
                            }

                            MouseArea {
                                id: paymentArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !orderManager.isProcessing
                                onClicked: {
                                    initiatePayment(modelData.method || modelData.id)
                                }
                            }
                        }
                    }
                }

                // 无支付方式
                Label {
                    text: qsTr("No payment methods available")
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                    visible: !isLoadingPayment && paymentMethods.length === 0
                }

                Item { Layout.fillHeight: true }
            }
        }

        // 加载状态 - 骨架屏
        ScrollView {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: isLoading

            Column {
                width: parent.width
                spacing: Theme.spacing.sm

                Repeater {
                    model: 3

                    Rectangle {
                        width: parent.width
                        height: 120
                        radius: Theme.radius.md
                        color: Theme.colors.background
                        border.width: 1
                        border.color: Theme.colors.border

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.spacing.md
                            spacing: Theme.spacing.sm

                            Row {
                                width: parent.width
                                spacing: Theme.spacing.md

                                Rectangle {
                                    width: parent.width * 0.5
                                    height: 18
                                    radius: Theme.radius.sm
                                    color: Theme.colors.surfaceElevated

                                    SequentialAnimation on opacity {
                                        running: isLoading
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.5; duration: 800 }
                                        NumberAnimation { to: 1; duration: 800 }
                                    }
                                }

                                Item { width: 1; height: 1 }

                                Rectangle {
                                    width: 70
                                    height: 24
                                    radius: 12
                                    color: Theme.colors.surfaceElevated

                                    SequentialAnimation on opacity {
                                        running: isLoading
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.5; duration: 800 }
                                        NumberAnimation { to: 1; duration: 800 }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.colors.divider
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacing.xs

                                Repeater {
                                    model: 3

                                    Row {
                                        width: parent.width

                                        Rectangle {
                                            width: 50
                                            height: 14
                                            radius: Theme.radius.sm
                                            color: Theme.colors.surfaceElevated

                                            SequentialAnimation on opacity {
                                                running: isLoading
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.5; duration: 800 }
                                                NumberAnimation { to: 1; duration: 800 }
                                            }
                                        }

                                        Item { width: parent.width - 140; height: 1 }

                                        Rectangle {
                                            width: 90
                                            height: 14
                                            radius: Theme.radius.sm
                                            color: Theme.colors.surfaceElevated

                                            SequentialAnimation on opacity {
                                                running: isLoading
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.5; duration: 800 }
                                                NumberAnimation { to: 1; duration: 800 }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 空状态 - 纯字体图标
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacing.md
            visible: !isLoading && orderList.length === 0 && errorMessage === "" && currentView === "list"

            Label {
                text: "○"
                font.pixelSize: 64
                color: Theme.colors.textTertiary
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("No orders yet")
                font.pixelSize: Theme.typography.body1
                font.weight: Theme.typography.weightMedium
                color: Theme.colors.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("Your order history will appear here")
                font.pixelSize: Theme.typography.body2
                color: Theme.colors.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    footer: DialogButtonBox {
        visible: false
    }

    // 打开时自动加载订单
    onOpened: {
        currentView = "list"
        currentOrder = null
        loadOrders()
    }

    onClosed: {
        currentView = "list"
        currentOrder = null
        paymentMethods = []
    }

    // OrderManager 信号连接
    Connections {
        target: orderManager

        function onOrdersLoaded(orders) {
            isLoading = false
            errorMessage = ""
            var tempList = []
            for (var i = 0; i < orders.length; i++) {
                tempList.push(orders[i])
            }
            orderList = tempList
        }

        function onOrdersFailed(error) {
            isLoading = false
            errorMessage = error
        }

        function onOrderCancelled(orderId) {
            loadOrders()
        }

        function onOrderCancelFailed(error) {
            errorMessage = error
        }

        function onPaymentMethodsLoaded(methods) {
            isLoadingPayment = false
            var tempMethods = []
            for (var i = 0; i < methods.length; i++) {
                tempMethods.push(methods[i])
            }
            paymentMethods = tempMethods
        }

        function onPaymentMethodsFailed(error) {
            isLoadingPayment = false
            errorMessage = error
        }

        function onPaymentUrlReady(url, type) {
            Qt.openUrlExternally(url)
            currentView = "list"
            currentOrder = null
            loadOrders()
        }

        function onPaymentFailed(error) {
            errorMessage = error
        }
    }

    // 辅助函数
    function loadOrders() {
        if (isLoading) return

        isLoading = true
        errorMessage = ""
        orderList = []

        if (orderManager) {
            orderManager.fetchOrders()
        } else {
            isLoading = false
            errorMessage = qsTr("OrderManager not available")
        }
    }

    function cancelOrder(tradeNo) {
        if (orderManager) {
            orderManager.cancelOrder(tradeNo)
        }
    }

    function loadPaymentMethods() {
        isLoadingPayment = true
        paymentMethods = []
        if (orderManager) {
            orderManager.fetchPaymentMethods()
        } else {
            isLoadingPayment = false
        }
    }

    function initiatePayment(method) {
        if (orderManager && currentOrder) {
            orderManager.getPaymentUrl(currentOrder.trade_no, method)
        }
    }

    function getPaymentIcon(method) {
        switch(method.toLowerCase()) {
            case "alipay": return "A"
            case "wechat":
            case "wxpay": return "W"
            case "stripe":
            case "card": return "C"
            case "paypal": return "P"
            case "crypto":
            case "usdt": return "₿"
            default: return "$"
        }
    }

    function getPaymentColor(method) {
        switch(method.toLowerCase()) {
            case "alipay": return "#1677FF"
            case "wechat":
            case "wxpay": return "#07C160"
            case "stripe":
            case "card": return "#635BFF"
            case "paypal": return "#003087"
            case "crypto":
            case "usdt": return "#F7931A"
            default: return Theme.colors.primary
        }
    }

    function formatPeriod(period) {
        if (!period) return qsTr("N/A")
        switch(period) {
            case "month_price": return qsTr("Monthly")
            case "quarter_price": return qsTr("Quarterly")
            case "half_year_price": return qsTr("Semi-Annual")
            case "year_price": return qsTr("Annual")
            case "two_year_price": return qsTr("2 Years")
            case "three_year_price": return qsTr("3 Years")
            case "onetime_price": return qsTr("One-time")
            default: return period
        }
    }

    // 获取套餐名称 - 兼容不同API返回格式
    function getPlanName(order) {
        if (!order) return qsTr("N/A")
        // 尝试直接获取 plan_name
        if (order.plan_name) return order.plan_name
        // 尝试从嵌套 plan 对象获取
        if (order.plan && order.plan.name) return order.plan.name
        // 尝试 plan_title
        if (order.plan_title) return order.plan_title
        // 回退到显示套餐ID
        if (order.plan_id) return qsTr("Plan #%1").arg(order.plan_id)
        return qsTr("Unknown Plan")
    }

    function getStatusText(status) {
        switch(status) {
            case 0: return qsTr("Pending Payment")
            case 1: return qsTr("Processing")
            case 2: return qsTr("Cancelled")
            case 3: return qsTr("Completed")
            case 4: return qsTr("Refunded")
            default: return qsTr("Unknown")
        }
    }

    function getStatusColor(status) {
        switch(status) {
            case 0: return "#FF9800"
            case 1: return "#2196F3"
            case 2: return "#9E9E9E"
            case 3: return "#4CAF50"
            case 4: return "#F44336"
            default: return "#9E9E9E"
        }
    }

    function formatAmount(amount) {
        if (typeof amount === 'undefined' || amount === null) {
            return "¥0.00"
        }
        var yuan = (amount / 100).toFixed(2)
        return "¥" + yuan
    }

    function formatDateTime(timestamp) {
        if (!timestamp) return qsTr("N/A")

        var date = new Date(timestamp * 1000)

        var year = date.getFullYear()
        var month = String(date.getMonth() + 1).padStart(2, '0')
        var day = String(date.getDate()).padStart(2, '0')
        var hours = String(date.getHours()).padStart(2, '0')
        var minutes = String(date.getMinutes()).padStart(2, '0')

        return year + "-" + month + "-" + day + " " + hours + ":" + minutes
    }
}
