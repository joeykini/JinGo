// qml/components/TicketListDialog.qml (现代风格)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Dialogs
import JinGo 1.0

Dialog {
    id: ticketListDialog

    title: qsTr("Ticket System")
    modal: true
    standardButtons: Dialog.NoButton

    // 移动端检测
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios" ||
                                     (parent ? parent.width < 768 : false)

    // 移动端接近全屏，桌面端保持合理大小
    width: isMobile ? (parent ? parent.width * 0.95 : 350) : Math.min(600, parent ? parent.width * 0.95 : 600)
    height: isMobile ? (parent ? parent.height * 0.9 : 500) : Math.min(700, parent ? parent.height * 0.9 : 700)

    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    // ticketManager 从外部传入或使用全局对象
    property var ticketMgr: null
    property bool isLoading: false
    property string errorMessage: ""
    property var ticketList: []

    // 当前页面状态: "list", "new", "detail"
    property string currentView: "list"
    property var currentTicket: null

    background: Rectangle {
        color: Theme.colors.background
        radius: Theme.radius.lg
        border.width: 1
        border.color: Theme.colors.border
    }

    header: Rectangle {
        height: 56
        color: Theme.colors.background
        radius: Theme.radius.lg

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

            // 返回按钮 - 仅在非列表页显示
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.sm
                color: backArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"
                visible: currentView !== "list"

                Label {
                    text: "←"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: Theme.colors.textPrimary
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentView = "list"
                        currentTicket = null
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Label {
                text: {
                    if (currentView === "new") return qsTr("New Ticket")
                    if (currentView === "detail") return currentTicket ? currentTicket.subject : qsTr("Ticket Detail")
                    return qsTr("Ticket System")
                }
                font.pixelSize: Theme.typography.body1
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
                Layout.fillWidth: true
                Layout.maximumWidth: 300
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // 新建工单按钮 - 仅在列表页显示
            Rectangle {
                Layout.preferredWidth: newTicketRow.width + 20
                Layout.preferredHeight: 36
                radius: Theme.radius.md
                color: newTicketArea.containsMouse ? Theme.alpha(Theme.colors.primary, 0.08) : "transparent"
                border.width: 1
                border.color: newTicketArea.containsMouse ? Theme.colors.primary : Theme.colors.border
                visible: currentView === "list"

                RowLayout {
                    id: newTicketRow
                    anchors.centerIn: parent
                    spacing: 6

                    Label {
                        text: "+"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.colors.primary
                    }

                    Label {
                        text: qsTr("New Ticket")
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.primary
                    }
                }

                MouseArea {
                    id: newTicketArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentView = "new"
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }

            // 状态标签 - 仅在详情页显示
            Rectangle {
                Layout.preferredWidth: statusLabel.width + 20
                Layout.preferredHeight: 28
                radius: 14
                color: Theme.alpha(getStatusColor(currentTicket ? currentTicket.status : 0), 0.12)
                visible: currentView === "detail" && currentTicket

                Label {
                    id: statusLabel
                    text: getStatusText(currentTicket ? currentTicket.status : 0)
                    font.pixelSize: Theme.typography.small
                    font.weight: Theme.typography.weightMedium
                    color: getStatusColor(currentTicket ? currentTicket.status : 0)
                    anchors.centerIn: parent
                }
            }

            // 关闭按钮
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.sm
                color: closeArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"

                Label {
                    text: "×"
                    font.pixelSize: 20
                    color: Theme.colors.textSecondary
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ticketListDialog.close()
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    onOpened: {
        currentView = "list"
        currentTicket = null
        loadTickets()
    }

    onClosed: {
        currentView = "list"
        currentTicket = null
        newTicketForm.reset()
        detailView.reset()
    }

    function loadTickets() {
        if (ticketMgr) {
            isLoading = true
            errorMessage = ""
            ticketMgr.fetchTickets(1, 50)
        }
    }

    function getStatusText(status) {
        // XBoard API - status是工单状态: 0=待处理, 1=已关闭, 2=处理中
        switch (status) {
            case 0: return qsTr("Pending")
            case 1: return qsTr("Closed")
            case 2: return qsTr("Processing")
            default: return qsTr("Unknown")
        }
    }

    function getStatusColor(status) {
        // XBoard API - status是工单状态: 0=待处理, 1=已关闭, 2=处理中
        switch (status) {
            case 0: return Theme.colors.warning
            case 1: return Theme.colors.textTertiary
            case 2: return Theme.colors.primary
            default: return Theme.colors.textSecondary
        }
    }

    function getLevelText(level) {
        switch (level) {
            case 0: return qsTr("Low")
            case 1: return qsTr("Medium")
            case 2: return qsTr("High")
            default: return qsTr("Medium")
        }
    }

    function getLevelColor(level) {
        switch (level) {
            case 0: return Theme.colors.success
            case 1: return Theme.colors.warning
            case 2: return Theme.colors.error
            default: return Theme.colors.warning
        }
    }

    function formatDate(timestamp) {
        if (!timestamp) return "--"
        var date = new Date(timestamp * 1000)
        return date.toLocaleDateString() + " " + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
    }

    contentItem: Item {
        // ========== 列表视图 ==========
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            visible: currentView === "list"

            // 加载中状态 - 骨架屏
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: isLoading

                Column {
                    width: parent.width
                    spacing: Theme.spacing.sm
                    topPadding: Theme.spacing.sm

                    Repeater {
                        model: 4

                        Rectangle {
                            width: parent.width - Theme.spacing.md * 2
                            x: Theme.spacing.md
                            height: 90
                            radius: Theme.radius.md
                            color: Theme.colors.surface
                            border.width: 1
                            border.color: Theme.colors.border

                            Column {
                                anchors.fill: parent
                                anchors.margins: Theme.spacing.md
                                spacing: Theme.spacing.xs

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacing.sm

                                    Rectangle {
                                        width: 50
                                        height: 22
                                        radius: 11
                                        color: Theme.colors.surfaceElevated
                                        SequentialAnimation on opacity {
                                            running: isLoading; loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 800 }
                                            NumberAnimation { to: 1; duration: 800 }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width * 0.4
                                        height: 18
                                        radius: Theme.radius.sm
                                        color: Theme.colors.surfaceElevated
                                        SequentialAnimation on opacity {
                                            running: isLoading; loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 800 }
                                            NumberAnimation { to: 1; duration: 800 }
                                        }
                                    }

                                    Item { width: 1; height: 1 }

                                    Rectangle {
                                        width: 60
                                        height: 24
                                        radius: 12
                                        color: Theme.colors.surfaceElevated
                                        SequentialAnimation on opacity {
                                            running: isLoading; loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 800 }
                                            NumberAnimation { to: 1; duration: 800 }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width * 0.7
                                    height: 14
                                    radius: Theme.radius.sm
                                    color: Theme.colors.surfaceElevated
                                    SequentialAnimation on opacity {
                                        running: isLoading; loops: Animation.Infinite
                                        NumberAnimation { to: 0.5; duration: 800 }
                                        NumberAnimation { to: 1; duration: 800 }
                                    }
                                }

                                Rectangle {
                                    width: 100
                                    height: 12
                                    radius: Theme.radius.sm
                                    color: Theme.colors.surfaceElevated
                                    SequentialAnimation on opacity {
                                        running: isLoading; loops: Animation.Infinite
                                        NumberAnimation { to: 0.5; duration: 800 }
                                        NumberAnimation { to: 1; duration: 800 }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 错误提示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.margins: Theme.spacing.md
                radius: Theme.radius.md
                color: Theme.alpha(Theme.colors.error, 0.08)
                border.width: 1
                border.color: Theme.alpha(Theme.colors.error, 0.3)
                visible: errorMessage !== "" && !isLoading

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

                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 30
                        radius: Theme.radius.sm
                        color: retryArea.containsMouse ? Qt.darker(Theme.colors.error, 1.1) : Theme.colors.error

                        Label {
                            text: qsTr("Retry")
                            font.pixelSize: Theme.typography.caption
                            color: "white"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: retryArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loadTickets()
                        }
                    }
                }
            }

            // 空状态
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                visible: !isLoading && errorMessage === "" && ticketList.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacing.md

                    IconSymbol {
                        icon: "edit"
                        size: 64
                        color: Theme.colors.textTertiary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: qsTr("No tickets yet")
                        font.pixelSize: Theme.typography.body1
                        font.weight: Theme.typography.weightBold
                        color: Theme.colors.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: qsTr("Click 'New Ticket' to submit your question")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 工单列表
            ListView {
                id: ticketListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                visible: !isLoading && errorMessage === "" && ticketList.length > 0
                clip: true
                spacing: Theme.spacing.sm
                model: ticketList

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: ticketListView.width
                    height: 100
                    radius: Theme.radius.md
                    color: delegateArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface
                    border.width: 1
                    border.color: delegateArea.containsMouse ? Theme.colors.primary : Theme.colors.border

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.md
                        spacing: Theme.spacing.xs

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.sm

                            // 优先级标签
                            Rectangle {
                                Layout.preferredWidth: lvlLabel.width + 16
                                Layout.preferredHeight: 22
                                radius: 11
                                color: Theme.alpha(getLevelColor(modelData.level), 0.12)

                                Label {
                                    id: lvlLabel
                                    text: getLevelText(modelData.level)
                                    font.pixelSize: Theme.typography.small
                                    font.weight: Theme.typography.weightMedium
                                    color: getLevelColor(modelData.level)
                                    anchors.centerIn: parent
                                }
                            }

                            Label {
                                text: modelData.subject || qsTr("No Subject")
                                font.pixelSize: Theme.typography.body2
                                font.weight: Theme.typography.weightBold
                                color: Theme.colors.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // 状态标签
                            Rectangle {
                                Layout.preferredWidth: stsLabel.width + 16
                                Layout.preferredHeight: 24
                                radius: 12
                                color: Theme.alpha(getStatusColor(modelData.status), 0.12)

                                Label {
                                    id: stsLabel
                                    text: getStatusText(modelData.status)
                                    font.pixelSize: Theme.typography.small
                                    font.weight: Theme.typography.weightMedium
                                    color: getStatusColor(modelData.status)
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        Label {
                            text: modelData.message || ""
                            font.pixelSize: Theme.typography.caption
                            color: Theme.colors.textSecondary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.md

                            Label {
                                text: formatDate(modelData.created_at)
                                font.pixelSize: Theme.typography.small
                                color: Theme.colors.textTertiary
                            }

                            Item { Layout.fillWidth: true }

                            // 有回复标识
                            Rectangle {
                                Layout.preferredWidth: replyLabel.width + 12
                                Layout.preferredHeight: 20
                                radius: 10
                                color: Theme.alpha(Theme.colors.primary, 0.1)
                                visible: modelData.reply_status === 1

                                Label {
                                    id: replyLabel
                                    text: qsTr("Has Reply")
                                    font.pixelSize: Theme.typography.tiny
                                    color: Theme.colors.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Label {
                                text: "→"
                                font.pixelSize: 14
                                color: Theme.colors.textTertiary
                            }
                        }
                    }

                    MouseArea {
                        id: delegateArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTicket = modelData
                            currentView = "detail"
                            detailView.loadDetail()
                        }
                    }
                }
            }
        }

        // ========== 新建工单视图 ==========
        NewTicketForm {
            id: newTicketForm
            anchors.fill: parent
            visible: currentView === "new"
            ticketManager: ticketListDialog.ticketMgr

            onTicketCreated: {
                currentView = "list"
                loadTickets()
            }
        }

        // ========== 工单详情视图 ==========
        TicketDetailView {
            id: detailView
            anchors.fill: parent
            visible: currentView === "detail"
            ticketManager: ticketListDialog.ticketMgr
            ticketData: currentTicket

            onTicketUpdated: {
                loadTickets()
            }

            onTicketClosed: {
                currentView = "list"
                loadTickets()
            }
        }
    }

    // 连接 TicketManager 信号
    Connections {
        target: ticketMgr

        function onTicketsLoaded(tickets) {
            isLoading = false
            errorMessage = ""
            // 创建新数组并重新赋值，以触发QML视图更新
            var newList = []
            for (var i = 0; i < tickets.length; i++) {
                newList.push(tickets[i])
            }
            ticketList = newList
        }

        function onTicketsFailed(error) {
            isLoading = false
            errorMessage = error
        }
    }

    // ========== 内嵌组件：新建工单表单 ==========
    component NewTicketForm: Item {
        property var ticketManager: null
        property bool isProcessing: false
        property string errorMessage: ""
        property string subjectText: ""
        property string messageText: ""
        property int selectedLevel: 1
        property string attachmentPath: ""
        property string attachmentName: ""
        property real uploadProgress: 0

        signal ticketCreated()

        function reset() {
            subjectText = ""
            messageText = ""
            selectedLevel = 1
            errorMessage = ""
            isProcessing = false
            attachmentPath = ""
            attachmentName = ""
            uploadProgress = 0
        }

        function selectFile() {
            newTicketFileDialog.open()
        }

        function removeAttachment() {
            attachmentPath = ""
            attachmentName = ""
        }

        function submit() {
            if (!subjectText.trim()) {
                errorMessage = qsTr("Please enter ticket subject")
                return
            }
            if (!messageText.trim()) {
                errorMessage = qsTr("Please enter ticket content")
                return
            }
            if (messageText.trim().length < 10) {
                errorMessage = qsTr("Ticket content must be at least 10 characters")
                return
            }
            if (!ticketManager) {
                errorMessage = qsTr("System error")
                return
            }

            errorMessage = ""
            isProcessing = true
            uploadProgress = 0
            ticketManager.createTicket(subjectText.trim(), messageText.trim(), selectedLevel, attachmentPath)
        }

        FileDialog {
            id: newTicketFileDialog
            title: qsTr("Select Attachment")
            nameFilters: [qsTr("Images") + " (*.png *.jpg *.jpeg *.gif *.bmp)", qsTr("Documents") + " (*.pdf *.doc *.docx *.txt)", qsTr("All Files") + " (*)"]
            onAccepted: {
                var path = selectedFile.toString()
                if (path.startsWith("file://")) {
                    path = path.substring(7)
                }
                attachmentPath = path
                var parts = path.split("/")
                attachmentName = parts[parts.length - 1]
            }
        }

        Connections {
            target: ticketManager

            function onUploadProgress(bytesSent, bytesTotal) {
                if (bytesTotal > 0 && isProcessing) {
                    uploadProgress = bytesSent / bytesTotal
                }
            }
        }

        Connections {
            target: ticketManager

            function onTicketCreated(ticket) {
                isProcessing = false
                reset()
                ticketCreated()
            }

            function onTicketFailed(error) {
                isProcessing = false
                errorMessage = error
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            spacing: Theme.spacing.md

            // 错误提示 - 30秒后自动关闭
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: Theme.radius.md
                color: Theme.alpha(Theme.colors.error, 0.08)
                border.width: 1
                border.color: Theme.alpha(Theme.colors.error, 0.3)
                visible: errorMessage !== ""

                Timer {
                    id: errorTimer
                    interval: 30000
                    repeat: false
                    onTriggered: errorMessage = ""
                }

                onVisibleChanged: {
                    if (visible) {
                        errorTimer.restart()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.sm
                    spacing: Theme.spacing.sm

                    Label {
                        text: "⚠"
                        font.pixelSize: 16
                        color: Theme.colors.error
                    }

                    Label {
                        text: errorMessage
                        font.pixelSize: Theme.typography.caption
                        color: Theme.colors.error
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // 关闭按钮
                    Label {
                        text: "×"
                        font.pixelSize: 16
                        color: Theme.colors.error

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: errorMessage = ""
                        }
                    }
                }
            }

            // 主题输入
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("Subject") + " *"
                    font.pixelSize: Theme.typography.caption
                    color: Theme.colors.textSecondary
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Theme.radius.sm
                    color: Theme.colors.inputBackground
                    border.width: 1
                    border.color: subjectInput.activeFocus ? Theme.colors.primary : Theme.colors.inputBorder

                    TextField {
                        id: subjectInput
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        placeholderText: qsTr("Brief description of your issue")
                        text: subjectText
                        onTextChanged: {
                            subjectText = text
                            errorMessage = ""
                        }
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textPrimary
                        verticalAlignment: Text.AlignVCenter
                        background: Rectangle { color: "transparent" }
                    }
                }
            }

            // 优先级选择
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.xs

                Label {
                    text: qsTr("Priority")
                    font.pixelSize: Theme.typography.caption
                    color: Theme.colors.textSecondary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.sm

                    Repeater {
                        model: [
                            { level: 0, text: qsTr("Low"), color: Theme.colors.success },
                            { level: 1, text: qsTr("Medium"), color: Theme.colors.warning },
                            { level: 2, text: qsTr("High"), color: Theme.colors.error }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: Theme.radius.md
                            color: selectedLevel === modelData.level ? Theme.alpha(modelData.color, 0.12) : Theme.colors.surface
                            border.width: selectedLevel === modelData.level ? 2 : 1
                            border.color: selectedLevel === modelData.level ? modelData.color : Theme.colors.border

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: modelData.color
                                }

                                Label {
                                    text: modelData.text
                                    font.pixelSize: Theme.typography.caption
                                    font.weight: selectedLevel === modelData.level ? Font.Bold : Font.Normal
                                    color: selectedLevel === modelData.level ? modelData.color : Theme.colors.textSecondary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectedLevel = modelData.level
                            }
                        }
                    }
                }
            }

            // 内容输入
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Label {
                    text: qsTr("Content") + " *"
                    font.pixelSize: Theme.typography.caption
                    color: Theme.colors.textSecondary
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radius.sm
                    color: Theme.colors.inputBackground
                    border.width: 1
                    border.color: messageInput.activeFocus ? Theme.colors.primary : Theme.colors.inputBorder

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 4

                        TextArea {
                            id: messageInput
                            placeholderText: qsTr("Please describe your issue in detail...")
                            text: messageText
                            onTextChanged: {
                                messageText = text
                                errorMessage = ""
                            }
                            font.pixelSize: Theme.typography.body2
                            color: Theme.colors.textPrimary
                            wrapMode: TextArea.Wrap
                            leftPadding: 4
                            rightPadding: 4
                            topPadding: 1
                            bottomPadding: 1
                            background: Rectangle { color: "transparent" }
                        }
                    }
                }

                Label {
                    text: qsTr("Minimum 10 characters") + " (" + messageText.length + "/10)"
                    font.pixelSize: Theme.typography.small
                    color: messageText.length >= 10 ? Theme.colors.success : Theme.colors.textTertiary
                    Layout.alignment: Qt.AlignRight
                }
            }

            // 附件区域
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.xs

                Label {
                    text: qsTr("Attachment") + " (" + qsTr("Optional") + ")"
                    font.pixelSize: Theme.typography.caption
                    color: Theme.colors.textSecondary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.sm

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Theme.radius.md
                        color: attachBtn.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface
                        border.width: 1
                        border.color: Theme.colors.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacing.sm
                            spacing: Theme.spacing.sm

                            Label {
                                text: "+"
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: Theme.colors.primary
                                Layout.preferredWidth: 24
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                text: attachmentName ? attachmentName : qsTr("Click to select file")
                                font.pixelSize: Theme.typography.body2
                                color: attachmentName ? Theme.colors.textPrimary : Theme.colors.textTertiary
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            id: attachBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: selectFile()
                        }
                    }

                    // 移除附件按钮
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: Theme.radius.sm
                        color: removeBtn.containsMouse ? Theme.alpha(Theme.colors.error, 0.12) : "transparent"
                        visible: attachmentPath !== ""

                        Label {
                            text: "×"
                            font.pixelSize: 18
                            color: Theme.colors.error
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: removeBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: removeAttachment()
                        }
                    }
                }

                // 上传进度条
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: Theme.colors.border
                    visible: isProcessing && attachmentPath && uploadProgress < 1

                    Rectangle {
                        width: parent.width * uploadProgress
                        height: parent.height
                        radius: 2
                        color: Theme.colors.primary
                    }
                }
            }

            // 提交按钮
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: Theme.radius.md
                color: {
                    if (!subjectText.trim() || messageText.trim().length < 10 || isProcessing) {
                        return Theme.alpha(Theme.colors.primary, 0.4)
                    }
                    return submitArea.containsMouse ? Qt.darker(Theme.colors.primary, 1.1) : Theme.colors.primary
                }

                Label {
                    text: isProcessing ? qsTr("Submitting...") : qsTr("Submit Ticket")
                    font.pixelSize: Theme.typography.body2
                    font.weight: Font.Bold
                    color: (!subjectText.trim() || messageText.trim().length < 10 || isProcessing) ? Qt.rgba(1, 1, 1, 0.6) : "white"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: submitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: subjectText.trim() && messageText.trim().length >= 10 && !isProcessing
                    onClicked: submit()
                }
            }
        }
    }

    // ========== 内嵌组件：工单详情视图 ==========
    component TicketDetailView: Item {
        property var ticketManager: null
        property var ticketData: null
        property var loadedDetail: null  // 从API加载的详细数据
        property var messageList: []
        property bool isLoading: false
        property bool isSending: false
        property string errorMessage: ""
        property string replyText: ""
        property string replyAttachmentPath: ""
        property string replyAttachmentName: ""
        property real replyUploadProgress: 0

        // 合并的工单数据 - 优先使用loadedDetail，否则使用ticketData
        property var mergedData: {
            if (loadedDetail && loadedDetail.id === (ticketData ? ticketData.id : -1)) {
                return loadedDetail
            }
            return ticketData
        }

        signal ticketUpdated()
        signal ticketClosed()

        function reset() {
            replyText = ""
            errorMessage = ""
            messageList = []
            loadedDetail = null
            isLoading = false
            isSending = false
            replyAttachmentPath = ""
            replyAttachmentName = ""
            replyUploadProgress = 0
        }

        function loadDetail() {
            if (ticketManager && ticketData && ticketData.id > 0) {
                isLoading = true
                errorMessage = ""
                messageList = []  // 清空之前的消息列表
                loadedDetail = null  // 清空之前的详情
                ticketManager.getTicketDetail(ticketData.id)
            }
        }

        function selectReplyFile() {
            replyFileDialog.open()
        }

        function removeReplyAttachment() {
            replyAttachmentPath = ""
            replyAttachmentName = ""
        }

        function sendReply() {
            if (!ticketManager || !replyText.trim() || !ticketData) return
            isSending = true
            errorMessage = ""
            replyUploadProgress = 0
            ticketManager.replyTicket(ticketData.id, replyText.trim(), replyAttachmentPath)
        }

        function closeTicket() {
            if (!ticketManager || !ticketData) return
            isSending = true
            ticketManager.closeTicket(ticketData.id)
        }

        FileDialog {
            id: replyFileDialog
            title: qsTr("Select Attachment")
            nameFilters: [qsTr("Images") + " (*.png *.jpg *.jpeg *.gif *.bmp)", qsTr("Documents") + " (*.pdf *.doc *.docx *.txt)", qsTr("All Files") + " (*)"]
            onAccepted: {
                var path = selectedFile.toString()
                if (path.startsWith("file://")) {
                    path = path.substring(7)
                }
                replyAttachmentPath = path
                var parts = path.split("/")
                replyAttachmentName = parts[parts.length - 1]
            }
        }

        Connections {
            target: ticketManager

            function onTicketDetailLoaded(ticket) {
                isLoading = false
                // 更新详情数据 - 存到loadedDetail而不是覆盖ticketData
                if (ticket) {
                    loadedDetail = {
                        id: ticket.id || 0,
                        subject: ticket.subject || "",
                        level: ticket.level !== undefined ? ticket.level : 0,
                        status: ticket.status !== undefined ? ticket.status : 0,
                        reply_status: ticket.reply_status !== undefined ? ticket.reply_status : 0,
                        created_at: ticket.created_at || 0,
                        updated_at: ticket.updated_at || 0
                    }
                }

                // 更新消息列表 - API返回的是 "message" 数组，不是 "message_list"
                var msgArray = ticket ? ticket.message : null
                if (msgArray && Array.isArray(msgArray)) {
                    // 创建新数组并重新赋值，以触发QML视图更新
                    var newList = []
                    for (var i = 0; i < msgArray.length; i++) {
                        newList.push(msgArray[i])
                    }
                    messageList = newList
                } else {
                    messageList = []
                }
            }

            function onTicketDetailFailed(error) {
                isLoading = false
                errorMessage = error
            }

            function onTicketReplied(id) {
                if (ticketData && id === ticketData.id) {
                    isSending = false
                    replyText = ""
                    replyAttachmentPath = ""
                    replyAttachmentName = ""
                    replyUploadProgress = 0
                    loadDetail()
                    ticketUpdated()
                }
            }

            function onUploadProgress(bytesSent, bytesTotal) {
                if (bytesTotal > 0 && isSending) {
                    replyUploadProgress = bytesSent / bytesTotal
                }
            }

            function onTicketReplyFailed(error) {
                isSending = false
                errorMessage = error
            }

            function onTicketClosed(id) {
                if (ticketData && id === ticketData.id) {
                    isSending = false
                    ticketClosed()
                }
            }

            function onTicketCloseFailed(error) {
                isSending = false
                errorMessage = error
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 加载中
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                visible: isLoading

                BusyIndicator {
                    anchors.centerIn: parent
                    running: isLoading
                }
            }

            // 错误提示 - 30秒后自动关闭
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.margins: Theme.spacing.sm
                radius: Theme.radius.md
                color: Theme.alpha(Theme.colors.error, 0.08)
                border.width: 1
                border.color: Theme.alpha(Theme.colors.error, 0.3)
                visible: errorMessage !== "" && !isLoading

                Timer {
                    id: detailErrorTimer
                    interval: 30000
                    repeat: false
                    onTriggered: errorMessage = ""
                }

                onVisibleChanged: {
                    if (visible) {
                        detailErrorTimer.restart()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.sm
                    spacing: Theme.spacing.sm

                    Label {
                        text: "⚠"
                        font.pixelSize: 16
                        color: Theme.colors.error
                    }

                    Label {
                        text: errorMessage
                        font.pixelSize: Theme.typography.caption
                        color: Theme.colors.error
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                    }

                    Label {
                        text: "×"
                        font.pixelSize: 16
                        color: Theme.colors.error

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: errorMessage = ""
                        }
                    }
                }
            }

            // 消息列表
            ListView {
                id: msgListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 0
                visible: !isLoading
                clip: true
                spacing: Theme.spacing.md
                model: messageList

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                header: Rectangle {
                    width: msgListView.width
                    height: origContent.height + Theme.spacing.lg
                    color: "transparent"

                    ColumnLayout {
                        id: origContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Theme.spacing.sm

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: origCol.height + Theme.spacing.md * 2
                            radius: Theme.radius.md
                            color: Theme.colors.surface
                            border.width: 1
                            border.color: Theme.colors.border

                            ColumnLayout {
                                id: origCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.spacing.md
                                spacing: Theme.spacing.sm

                                // 工单标题
                                Label {
                                    text: mergedData ? (mergedData.subject || "") : ""
                                    font.pixelSize: Theme.typography.body1
                                    font.weight: Theme.typography.weightBold
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: mergedData && mergedData.subject
                                }

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 4
                                        height: 14
                                        radius: 2
                                        color: Theme.colors.primary
                                    }
                                    Label {
                                        text: qsTr("Original Message")
                                        font.pixelSize: Theme.typography.caption
                                        font.weight: Font.Bold
                                        color: Theme.colors.textSecondary
                                    }
                                }

                                Label {
                                    // 原始消息：优先从message_list第一条获取，否则从ticketData.message获取
                                    text: {
                                        // 先检查message_list是否有内容
                                        if (messageList && messageList.length > 0 && messageList[0].message) {
                                            return messageList[0].message
                                        }
                                        // 再检查ticketData.message
                                        if (ticketData && ticketData.message) {
                                            return ticketData.message
                                        }
                                        return qsTr("No content")
                                    }
                                    font.pixelSize: Theme.typography.body2
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    // 创建时间：优先从message_list第一条获取
                                    text: {
                                        var timestamp = 0
                                        if (messageList && messageList.length > 0 && messageList[0].created_at) {
                                            timestamp = messageList[0].created_at
                                        } else if (mergedData && mergedData.created_at) {
                                            timestamp = mergedData.created_at
                                        }
                                        return formatDate(timestamp)
                                    }
                                    font.pixelSize: Theme.typography.small
                                    color: Theme.colors.textTertiary
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.colors.border
                            visible: messageList.length > 0
                        }

                        RowLayout {
                            spacing: 8
                            visible: messageList.length > 1  // 只有当有回复消息时才显示

                            Rectangle {
                                width: 4
                                height: 14
                                radius: 2
                                color: Theme.colors.info
                            }

                            Label {
                                text: qsTr("Conversation")
                                font.pixelSize: Theme.typography.caption
                                font.weight: Font.Bold
                                color: Theme.colors.textSecondary
                            }
                        }
                    }
                }

                delegate: Rectangle {
                    // 跳过第一条消息（已在原始消息区域显示）
                    visible: index > 0
                    width: msgListView.width
                    height: index > 0 ? (msgColInner.height + Theme.spacing.md * 2) : 0
                    radius: Theme.radius.md
                    color: modelData.is_me ? Theme.alpha(Theme.colors.primary, 0.06) : Theme.colors.surfaceElevated
                    border.width: index > 0 ? 1 : 0
                    border.color: modelData.is_me ? Theme.alpha(Theme.colors.primary, 0.2) : Theme.colors.border

                    ColumnLayout {
                        id: msgColInner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spacing.md
                        spacing: Theme.spacing.xs

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: modelData.is_me ? "●" : "◆"
                                font.pixelSize: 14
                                color: modelData.is_me ? Theme.colors.primary : Theme.colors.success
                            }

                            Label {
                                text: modelData.is_me ? qsTr("You") : qsTr("Support")
                                font.pixelSize: Theme.typography.caption
                                font.weight: Font.Bold
                                color: modelData.is_me ? Theme.colors.primary : Theme.colors.success
                                Layout.leftMargin: 6
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: formatDate(modelData.created_at)
                                font.pixelSize: Theme.typography.small
                                color: Theme.colors.textTertiary
                            }
                        }

                        Label {
                            text: modelData.message || ""
                            font.pixelSize: Theme.typography.body2
                            color: Theme.colors.textPrimary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // 回复区域
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                color: Theme.colors.surface
                border.width: 1
                border.color: Theme.colors.border
                visible: !isLoading && mergedData && mergedData.status !== 1

                ColumnLayout {
                    id: replyCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacing.md
                    spacing: Theme.spacing.sm

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: Theme.radius.md
                        color: Theme.colors.inputBackground
                        border.width: 1
                        border.color: replyInput.activeFocus ? Theme.colors.primary : Theme.colors.inputBorder

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: Theme.spacing.sm

                            TextArea {
                                id: replyInput
                                placeholderText: qsTr("Enter your reply...")
                                text: replyText
                                onTextChanged: replyText = text
                                font.pixelSize: Theme.typography.body2
                                color: Theme.colors.textPrimary
                                wrapMode: TextArea.Wrap
                                background: Rectangle { color: "transparent" }
                            }
                        }
                    }

                    // 回复附件区域
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.sm

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Theme.radius.sm
                            color: replyAttachBtn.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface
                            border.width: 1
                            border.color: Theme.colors.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.spacing.xs
                                spacing: Theme.spacing.xs

                                Label {
                                    text: "+"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: Theme.colors.primary
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Label {
                                    text: replyAttachmentName ? replyAttachmentName : qsTr("Add attachment")
                                    font.pixelSize: Theme.typography.caption
                                    color: replyAttachmentName ? Theme.colors.textPrimary : Theme.colors.textTertiary
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }
                            }

                            MouseArea {
                                id: replyAttachBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectReplyFile()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: Theme.radius.sm
                            color: replyRemoveBtn.containsMouse ? Theme.alpha(Theme.colors.error, 0.12) : "transparent"
                            visible: replyAttachmentPath !== ""

                            Label {
                                text: "×"
                                font.pixelSize: 14
                                color: Theme.colors.error
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: replyRemoveBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: removeReplyAttachment()
                            }
                        }
                    }

                    // 上传进度条
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: Theme.colors.border
                        visible: isSending && replyAttachmentPath && replyUploadProgress < 1

                        Rectangle {
                            width: parent.width * replyUploadProgress
                            height: parent.height
                            radius: 2
                            color: Theme.colors.primary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.sm

                        Rectangle {
                            Layout.preferredWidth: closeTicketLabel.width + 24
                            Layout.preferredHeight: 40
                            radius: Theme.radius.md
                            color: closeBtn.containsMouse ? Theme.alpha(Theme.colors.error, 0.12) : "transparent"
                            border.width: 1
                            border.color: Theme.colors.error

                            Label {
                                id: closeTicketLabel
                                text: qsTr("Close Ticket")
                                font.pixelSize: Theme.typography.caption
                                color: Theme.colors.error
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: closeBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !isSending
                                onClicked: closeTicket()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 40
                            radius: Theme.radius.md
                            color: {
                                if (!replyText.trim() || isSending) {
                                    return Theme.alpha(Theme.colors.primary, 0.4)
                                }
                                return sendBtn.containsMouse ? Qt.darker(Theme.colors.primary, 1.1) : Theme.colors.primary
                            }

                            Label {
                                text: isSending ? qsTr("Sending...") : qsTr("Send")
                                font.pixelSize: Theme.typography.body2
                                font.weight: Font.Bold
                                color: (!replyText.trim() || isSending) ? Qt.rgba(1, 1, 1, 0.6) : "white"
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: sendBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: replyText.trim() && !isSending
                                onClicked: sendReply()
                            }
                        }
                    }
                }
            }

            // 已关闭提示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: Theme.colors.surfaceElevated
                visible: !isLoading && mergedData && mergedData.status === 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: "✓"
                        font.pixelSize: 18
                        color: Theme.colors.textTertiary
                    }

                    Label {
                        text: qsTr("This ticket has been closed")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }
                }
            }
        }
    }
}
