// pages/AppSelectorPage.qml
// Android 分应用代理 - 应用选择页面
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import JinGo 1.0

Rectangle {
    id: appSelectorPage

    readonly property var mainWindow: Window.window
    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    color: Theme.colors.pageBackground

    // 当前选中的应用包名列表
    property var selectedApps: configManager ? configManager.perAppProxyList : []

    // 搜索过滤
    property string searchFilter: ""

    // 返回上一页
    function goBack() {
        if (mainWindow && mainWindow.stackView && mainWindow.stackView.depth > 1) {
            mainWindow.stackView.pop()
        }
    }

    // 保存选择
    function saveSelection() {
        if (configManager) {
            configManager.perAppProxyList = selectedApps
            configManager.save()
        }
        goBack()
    }

    // 切换应用选中状态
    function toggleApp(packageName) {
        var idx = selectedApps.indexOf(packageName)
        if (idx >= 0) {
            selectedApps.splice(idx, 1)
        } else {
            selectedApps.push(packageName)
        }
        // 触发更新
        selectedApps = selectedApps.slice()
    }

    // 检查应用是否被选中
    function isAppSelected(packageName) {
        return selectedApps.indexOf(packageName) >= 0
    }

    // 全选
    function selectAll() {
        var all = []
        for (var i = 0; i < appListModel.count; i++) {
            all.push(appListModel.get(i).packageName)
        }
        selectedApps = all
    }

    // 全不选
    function deselectAll() {
        selectedApps = []
    }

    // 延迟加载应用列表的定时器（必须放在页面级别，不能放在ListModel内）
    Timer {
        id: loadTimer
        interval: 100
        repeat: false
        onTriggered: {
            // 从 Android 获取已安装应用列表
            if (Qt.platform.os === "android" && typeof platformInterface !== 'undefined' && platformInterface) {
                var apps = platformInterface.getInstalledApps()
                if (apps && apps.length > 0) {
                    for (var i = 0; i < apps.length; i++) {
                        appListModel.append(apps[i])
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 顶部栏：返回按钮和标题
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // 返回按钮
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: backMouseArea.containsMouse ? Theme.colors.surfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "<"
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.colors.textPrimary
                }

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: goBack()
                }
            }

            // 标题
            Text {
                text: qsTr("Select Apps")
                font.pixelSize: 20
                font.bold: true
                color: Theme.colors.textPrimary
            }

            Item { Layout.fillWidth: true }

            // 已选数量
            Text {
                text: qsTr("%1 selected").arg(selectedApps.length)
                font.pixelSize: 14
                color: Theme.colors.textSecondary
            }
        }

        // 搜索框
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 8
            color: Theme.colors.surface
            border.color: Theme.colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    text: "🔍"
                    font.pixelSize: 16
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search apps...")
                    background: null
                    color: Theme.colors.textPrimary
                    onTextChanged: searchFilter = text.toLowerCase()
                }

                // 清除搜索
                Rectangle {
                    visible: searchField.text.length > 0
                    width: 24
                    height: 24
                    radius: 12
                    color: clearMouseArea.containsMouse ? Theme.colors.surfaceHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 16
                        color: Theme.colors.textSecondary
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

        // 快速操作按钮
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            CustomButton {
                text: qsTr("Select All")
                variant: "secondary"
                Layout.fillWidth: true
                onClicked: selectAll()
            }

            CustomButton {
                text: qsTr("Deselect All")
                variant: "secondary"
                Layout.fillWidth: true
                onClicked: deselectAll()
            }
        }

        // 应用列表
        ListView {
            id: appListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: ListModel {
                id: appListModel

                Component.onCompleted: {
                    // 延迟加载应用列表，确保 platformInterface 已初始化
                    loadTimer.start()
                }
            }

            delegate: Rectangle {
                width: appListView.width
                height: visible ? 60 : 0
                visible: {
                    if (searchFilter.length === 0) return true
                    return model.appName.toLowerCase().indexOf(searchFilter) >= 0 ||
                           model.packageName.toLowerCase().indexOf(searchFilter) >= 0
                }
                radius: 8
                color: itemMouseArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // 复选框
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        color: isAppSelected(model.packageName) ? Theme.colors.primary : "transparent"
                        border.color: isAppSelected(model.packageName) ? Theme.colors.primary : Theme.colors.border
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                            visible: isAppSelected(model.packageName)
                        }
                    }

                    // 应用信息
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: model.appName
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.colors.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.packageName
                            font.pixelSize: 12
                            color: Theme.colors.textSecondary
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    // 系统应用标签
                    Rectangle {
                        visible: model.isSystemApp
                        width: systemLabel.width + 12
                        height: 20
                        radius: 4
                        color: Theme.colors.warning
                        opacity: 0.3

                        Text {
                            id: systemLabel
                            anchors.centerIn: parent
                            text: qsTr("System")
                            font.pixelSize: 10
                            color: Theme.colors.warning
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleApp(model.packageName)
                }
            }

            // 无结果提示
            Text {
                anchors.centerIn: parent
                visible: appListView.count === 0 || (searchFilter.length > 0 && !hasVisibleItems())
                text: qsTr("No apps found")
                font.pixelSize: 16
                color: Theme.colors.textSecondary

                function hasVisibleItems() {
                    for (var i = 0; i < appListModel.count; i++) {
                        var item = appListModel.get(i)
                        if (item.appName.toLowerCase().indexOf(searchFilter) >= 0 ||
                            item.packageName.toLowerCase().indexOf(searchFilter) >= 0) {
                            return true
                        }
                    }
                    return false
                }
            }
        }

        // 底部保存按钮
        CustomButton {
            Layout.fillWidth: true
            text: qsTr("Save Selection")
            variant: "primary"
            onClicked: saveSelection()
        }
    }
}
