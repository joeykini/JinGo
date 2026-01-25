// components/ServerSelectDialog.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15

Dialog {
    id: serverSelectDialog
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    dim: true
    opacity: 1.0

    property bool isDarkMode: false
    property var selectedServer: null
    property bool isLoading: false
    property bool hasCheckedCache: false

    // 使用 ListModel 作为中介，避免直接绑定到 C++ QList
    ListModel {
        id: serversModel
    }

    // 安全地从 C++ 加载服务器列表到 ListModel
    function loadServersToModel() {
        try {
            serversModel.clear()
            if (!serverListViewModel) {
                return
            }

            // 检查 ViewModel 是否正在加载
            if (serverListViewModel.isLoading) {
                return
            }

            var servers = serverListViewModel.servers
            if (!servers || typeof servers.length === 'undefined') {
                return
            }

            var validCount = 0
            for (var i = 0; i < servers.length; i++) {
                var server = servers[i]
                // ⭐ 严格的对象有效性检查
                if (!server) {
                    continue
                }

                try {
                    // 先测试访问 ID，如果对象已删除会抛出异常
                    var testId = server.id
                    if (!testId || testId === "") {
                        continue
                    }

                    // 只存储数据的副本，不存储 C++ 对象指针
                    serversModel.append({
                        "serverId": server.id || "",
                        "serverName": server.name || "Unknown",
                        "serverFlag": server.countryFlag || "🌍",
                        "serverCountryCode": server.countryCode || "",
                        "serverProtocol": server.protocol || "",
                        "serverLatency": server.latency || -1,
                        "serverLocation": server.location || ""
                    })
                    validCount++
                } catch (e) {
                    continue
                }
            }
        } catch (e) {
        }
    }

    // 根据 ID 安全地从 C++ 获取服务器对象
    function getServerById(serverId) {
        if (!serverId || serverId === "") {
            return null
        }

        try {
            if (!serverListViewModel) {
                return null
            }

            // 检查 ViewModel 是否正在加载
            if (serverListViewModel.isLoading) {
                return null
            }

            var servers = serverListViewModel.servers
            if (!servers || typeof servers.length === 'undefined') {
                return null
            }

            for (var i = 0; i < servers.length; i++) {
                var server = servers[i]
                if (!server) {
                    continue
                }

                try {
                    // ⭐ 先测试访问对象，如果已删除会抛出异常
                    var testId = server.id
                    if (testId === serverId) {
                        // 再次检查对象是否有效
                        var testName = server.name
                        return server
                    }
                } catch (e) {
                    continue
                }
            }
        } catch (e) {
        }
        return null
    }

    // 信号：用户选择了服务器
    signal serverSelected(var server)

    // 标题
    title: qsTr("Select Server")

    // 对话框大小
    width: Math.min(600, parent ? parent.width * 0.9 : 600)
    height: Math.min(500, parent ? parent.height * 0.8 : 500)

    // 背景
    background: Rectangle {
        color: Theme.colors.surface  // 暗黑模式：浅灰色，浅色模式：浅黄色
        opacity: 1.0
        radius: 12
        border.color: isDarkMode ? "#3A3A3A" : "#F0E5C8"
        border.width: 1
    }

    // 标题栏
    header: Rectangle {
        height: 60
        color: Theme.colors.surfaceElevated  // 与对话框背景协调
        radius: 12

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Label {
                text: qsTr("Select Server")
                font.pixelSize: 18
                font.bold: true
                color: Theme.colors.textPrimary
                Layout.fillWidth: true
            }

            // 关闭按钮
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: closeMouseArea.containsMouse ? (isDarkMode ? "#3A3A3A" : "#E8E8E8") : "transparent"

                Label {
                    text: "✕"
                    font.pixelSize: 18
                    color: isDarkMode ? "#AAAAAA" : "#666666"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: serverSelectDialog.reject()
                }
            }
        }
    }

    // 内容区域
    contentItem: ColumnLayout {
        spacing: 12

        // 搜索框
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 8
            color: Theme.colors.surface
            border.color: searchField.activeFocus ? Theme.colors.primary : Theme.colors.border
            border.width: searchField.activeFocus ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label {
                    text: "🔍"
                    font.pixelSize: 16
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search servers...")
                    color: Theme.colors.textPrimary
                    placeholderTextColor: isDarkMode ? "#666666" : "#999999"
                    font.pixelSize: 14
                    background: Item {}
                    selectByMouse: true

                    onTextChanged: {
                        if (serverListViewModel) {
                            serverListViewModel.filterText = text
                        }
                    }
                }

                // 清除按钮
                Rectangle {
                    visible: searchField.text.length > 0
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: clearMouseArea.containsMouse ? (isDarkMode ? "#3A3A3A" : "#E0E0E0") : "transparent"

                    Label {
                        text: "✕"
                        font.pixelSize: 12
                        color: isDarkMode ? "#AAAAAA" : "#666666"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchField.text = ""
                    }
                }
            }
        }

        // 服务器列表
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            background: Rectangle {
                color: Theme.colors.surface  // 与对话框背景一致
            }

            ListView {
                id: serverListView
                model: serversModel
                spacing: 1

                delegate: Rectangle {
                    width: serverListView.width
                    height: 72
                    radius: 4
                    color: {
                        if (model.serverId === (selectedServer ? selectedServer.id : ""))
                            return Theme.colors.cardActive
                        if (serverMouseArea.containsMouse)
                            return Theme.colors.surfaceElevated
                        return Theme.colors.surface
                    }
                    border.color: {
                        if (model.serverId === (selectedServer ? selectedServer.id : ""))
                            return isDarkMode ? "#007BFF" : "#D4A017"
                        return isDarkMode ? "#3A3A3A" : "#E8D5A8"
                    }
                    border.width: (model.serverId === (selectedServer ? selectedServer.id : "")) ? 2 : 1

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        FlagIcon {
                            size: 40
                            countryCode: model.serverCountryCode || ""
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Label {
                                text: model.serverName || "Unknown"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.colors.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                visible: model.serverLocation !== ""
                                text: model.serverLocation || ""
                                font.pixelSize: 12
                                color: isDarkMode ? "#AAAAAA" : "#666666"
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            visible: model.serverProtocol !== ""
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 70
                            Layout.alignment: Qt.AlignVCenter
                            radius: 4
                            color: isDarkMode ? "#3A3A3A" : "#E8E8E8"

                            Label {
                                text: model.serverProtocol ? model.serverProtocol.toUpperCase() : ""
                                font.pixelSize: 10
                                font.bold: true
                                color: isDarkMode ? "#AAAAAA" : "#666666"
                                anchors.centerIn: parent
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 80
                            spacing: 2

                            Label {
                                text: {
                                    if (model.serverLatency < 0) return "⚡"
                                    if (model.serverLatency === 0) return qsTr("Timeout")
                                    return model.serverLatency + " ms"
                                }
                                font.pixelSize: 14
                                font.bold: true
                                color: {
                                    if (model.serverLatency < 0) return isDarkMode ? "#AAAAAA" : "#666666"
                                    if (model.serverLatency === 0) return Theme.colors.error
                                    if (model.serverLatency < 100) return "#4CAF50"
                                    if (model.serverLatency < 200) return Theme.colors.warning
                                    return "#FF5722"
                                }
                                Layout.alignment: Qt.AlignRight
                            }

                            Label {
                                visible: model.serverLatency >= 0
                                text: qsTr("Latency")
                                font.pixelSize: 10
                                color: isDarkMode ? "#666666" : "#999999"
                                Layout.alignment: Qt.AlignRight
                            }
                        }

                        Label {
                            visible: model.serverId === (selectedServer ? selectedServer.id : "")
                            text: "✓"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#007BFF"
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: serverMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // 只从 model 获取 ID，然后通过 ID 查找 C++ 对象
                            var serverId = model.serverId
                            if (!serverId) {
                                return
                            }

                            // 安全地从 C++ 获取服务器对象
                            var serverObj = getServerById(serverId)
                            if (!serverObj) {
                                return
                            }

                            selectedServer = serverObj
                            serverSelected(serverObj)

                            Qt.callLater(function() {
                                serverSelectDialog.accept()
                            })
                        }
                    }
                }

                // 空状态
                ColumnLayout {
                    visible: serverListView.count === 0
                    anchors.centerIn: parent
                    spacing: 16

                    Label {
                        text: {
                            if (isLoading) return qsTr("Loading servers...")
                            if (searchField.text.length > 0) return qsTr("No matching servers found")
                            return qsTr("No Servers")
                        }
                        color: isDarkMode ? "#666666" : "#999999"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // 加载指示器
                    Rectangle {
                        visible: isLoading
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignHCenter
                        radius: 20
                        color: "transparent"
                        border.color: "#007BFF"
                        border.width: 3

                        RotationAnimation on rotation {
                            running: isLoading
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    // 刷新按钮（仅在非搜索且非加载时显示）
                    Button {
                        visible: !isLoading && searchField.text.length === 0 && serverListView.count === 0
                        text: qsTr("Refresh List")
                        Layout.alignment: Qt.AlignHCenter

                        background: Rectangle {
                            radius: 8
                            color: parent.hovered ? "#007BFF" : "#0056b3"
                        }

                        contentItem: Label {
                            text: parent.text
                            font.pixelSize: 14
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if (serverListViewModel) {
                                isLoading = true
                                serverListViewModel.refreshServers()
                            }
                        }
                    }
                }
            }
        }
    }

    // 底部按钮区域
    footer: Rectangle {
        height: 60
        color: Theme.colors.surfaceElevated  // 与对话框背景协调
        radius: 12

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Label {
                text: qsTr("Total %1 servers").arg(serversModel.count)
                font.pixelSize: 12
                color: isDarkMode ? "#AAAAAA" : "#666666"
                Layout.fillWidth: true
            }

            // 取消按钮
            Button {
                text: qsTr("Cancel")
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36

                background: Rectangle {
                    radius: 8
                    color: parent.hovered ? (isDarkMode ? "#3A3A3A" : "#FFE5A3") : (isDarkMode ? "#2A2A2A" : "#FFFFFF")
                    border.color: isDarkMode ? "#3A3A3A" : "#E8D5A8"
                    border.width: 1
                }

                contentItem: Label {
                    text: parent.text
                    font.pixelSize: 14
                    color: isDarkMode ? "#AAAAAA" : "#666666"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: serverSelectDialog.reject()
            }
        }
    }

    // 监听服务器列表变化
    Connections {
        target: serverListViewModel

        function onServersChanged() {
            isLoading = false
            loadServersToModel()
        }
    }

    // 打开时加载内存中的服务器列表
    onOpened: {
        searchField.text = ""
        searchField.forceActiveFocus()

        // 加载服务器到 ListModel
        loadServersToModel()
        hasCheckedCache = true
    }

    // 关闭时清除搜索和模型
    onClosed: {
        if (serverListViewModel) {
            serverListViewModel.filterText = ""
        }
        serversModel.clear()
        isLoading = false
    }
}
