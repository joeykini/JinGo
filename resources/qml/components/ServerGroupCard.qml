// resources/qml/components/ServerGroupCard.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

Rectangle {
    id: groupCard
    
    property string groupName: "推荐服务器"
    property string groupDescription: ""
    property string groupIcon: "🌐"
    property bool isExpanded: true
    property bool isDarkMode: false
    property var serverList: []
    property var selectedServer: null
    
    signal serverSelected(var server)
    
    width: parent.width
    height: headerSection.height + (isExpanded ? serverListColumn.height + 20 : 0)
    radius: 16
    color: Theme.colors.surface
    border.color: isDarkMode ? "#3A3A3A" : "#E0E0E0"
    border.width: 1
    
    // 展开/折叠动画
    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // 分组头部
        Rectangle {
            id: headerSection
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: groupCard.isExpanded = !groupCard.isExpanded
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 15
                    
                    // 图标
                    Label {
                        text: groupIcon
                        font.pixelSize: 24
                    }
                    
                    // 分组信息
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: groupName
                            font.pixelSize: 18
                            font.bold: true
                            color: Theme.colors.textPrimary
                        }
                        
                        Label {
                            text: groupDescription !== "" ? groupDescription : 
                                  qsTr("%1 Servers").arg(serverList.length)
                            font.pixelSize: 12
                            color: isDarkMode ? "#AAAAAA" : "#666666"
                            visible: text !== ""
                        }
                    }
                    
                    // 服务器数量徽章
                    Rectangle {
                        Layout.preferredWidth: 35
                        Layout.preferredHeight: 25
                        radius: 12
                        color: isDarkMode ? "#3A3A3A" : "#F0F0F0"
                        
                        Label {
                            anchors.centerIn: parent
                            text: serverList.length.toString()
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.colors.textPrimary
                        }
                    }
                    
                    // 展开/折叠箭头
                    Label {
                        text: isExpanded ? "▼" : "▶"
                        font.pixelSize: 14
                        color: isDarkMode ? "#666666" : "#CCCCCC"
                        
                        Behavior on rotation {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }
            }
        }
        
        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            height: 1
            color: isDarkMode ? "#3A3A3A" : "#EEEEEE"
            visible: isExpanded && serverList.length > 0
        }
        
        // 服务器列表
        ColumnLayout {
            id: serverListColumn
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            spacing: 8
            visible: isExpanded
            
            Repeater {
                model: serverList
                
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 15
                    Layout.rightMargin: 15
                    Layout.preferredHeight: 70
                    radius: 12
                    color: {
                        if (selectedServer && modelData && modelData.id === selectedServer.id) {
                            return Theme.colors.serverSelected
                        }
                        return serverMouseArea.containsMouse ?
                            Theme.colors.serverHover :
                            Theme.colors.serverBackground
                    }
                    border.color: selectedServer && modelData && modelData.id === selectedServer.id ?
                        Theme.colors.serverSelectedBorder : Theme.colors.border
                    border.width: 1
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    MouseArea {
                        id: serverMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: groupCard.serverSelected(modelData)
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 12

                            // 国旗图标 - 垂直居中
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter
                                radius: 20
                                color: isDarkMode ? "#3A3A3A" : "#F0F0F0"

                                Label {
                                    anchors.centerIn: parent
                                    text: (modelData && modelData.countryCode) ? modelData.countryCode : "🌍"
                                    font.pixelSize: 20
                                }
                            }

                            // 服务器信息 - 左对齐，垂直居中
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                Label {
                                    text: (modelData && modelData.name) ? modelData.name : qsTr("UnknownServers")
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: selectedServer && modelData && modelData.id === selectedServer.id ?
                                        "#FFFFFF" : (Theme.colors.textPrimary)
                                }

                                Label {
                                    text: (modelData && modelData.location) ? modelData.location : ""
                                    font.pixelSize: 12
                                    color: selectedServer && modelData && modelData.id === selectedServer.id ?
                                        "#EEEEEE" : (isDarkMode ? "#AAAAAA" : "#666666")
                                }
                            }

                            // 延迟显示 - 右对齐，垂直居中
                            Rectangle {
                                Layout.preferredWidth: 70
                                Layout.preferredHeight: 30
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                radius: 15
                                color: {
                                    if (selectedServer && modelData && modelData.id === selectedServer.id) {
                                        return Theme.colors.serverSelectedAccent
                                    }
                                    var latency = (modelData && modelData.latency) ? modelData.latency : 0
                                    if (latency <= 0) return Theme.colors.surfaceElevated
                                    if (latency < 50) return Theme.colors.success
                                    if (latency < 100) return Theme.colors.warning
                                    return Theme.colors.error
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Label {
                                        text: "●"
                                        font.pixelSize: 10
                                        color: "white"
                                    }

                                    Label {
                                        text: {
                                            var latency = (modelData && modelData.latency) ? modelData.latency : 0
                                            return latency > 0 ? latency + "ms" : "--"
                                        }
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "white"
                                    }
                                }
                            }

                            // 选中指示器 - 垂直居中
                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignVCenter
                                radius: 10
                                border.color: selectedServer && modelData && modelData.id === selectedServer.id ?
                                    "#FFFFFF" : (isDarkMode ? "#666666" : "#CCCCCC")
                                border.width: 2
                                color: selectedServer && modelData && modelData.id === selectedServer.id ?
                                    "#FFFFFF" : "transparent"
                            }
                        }
                    }
                }
            }
        }
    }
}
