import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * 授权对话框
 *
 * 用于显示授权相关的提示信息，包括：
 * - 授权过期提示
 * - 设备超限提示
 * - 更新提示
 */
Dialog {
    id: root

    // 对话框类型
    enum DialogType {
        Expired,        // 授权过期
        DeviceLimit,    // 设备超限
        Update,         // 需要更新
        Error           // 一般错误
    }

    property int dialogType: LicenseDialog.DialogType.Error
    property string dialogTitle: qsTr("授权提示")
    property string dialogMessage: ""
    property string actionUrl: ""
    property bool exitOnClose: true

    title: dialogTitle
    modal: true
    closePolicy: exitOnClose ? Popup.NoAutoClose : Popup.CloseOnEscape

    // 居中显示
    anchors.centerIn: parent

    width: Math.min(400, parent.width - 40)

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // 图标
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: getIconSource()
            width: 64
            height: 64
            fillMode: Image.PreserveAspectFit
        }

        // 消息文本
        Label {
            Layout.fillWidth: true
            text: dialogMessage
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
        }

        // 链接（如果有）
        Label {
            Layout.fillWidth: true
            visible: actionUrl.length > 0
            text: "<a href='" + actionUrl + "'>" + actionUrl + "</a>"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 12
            color: "#2196F3"
            onLinkActivated: function(link) {
                Qt.openUrlExternally(link)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(actionUrl)
            }
        }

        // 按钮区域
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Button {
                text: getButtonText()
                highlighted: true
                onClicked: {
                    root.close()
                    if (exitOnClose) {
                        Qt.quit()
                    }
                }
            }

            Button {
                visible: actionUrl.length > 0 && dialogType === LicenseDialog.DialogType.Update
                text: qsTr("稍后提醒")
                onClicked: {
                    root.close()
                }
            }
        }
    }

    function getIconSource() {
        switch (dialogType) {
            case LicenseDialog.DialogType.Expired:
                return "qrc:/icons/warning.svg"
            case LicenseDialog.DialogType.DeviceLimit:
                return "qrc:/icons/devices.svg"
            case LicenseDialog.DialogType.Update:
                return "qrc:/icons/update.svg"
            default:
                return "qrc:/icons/error.svg"
        }
    }

    function getButtonText() {
        switch (dialogType) {
            case LicenseDialog.DialogType.Expired:
                return qsTr("我知道了")
            case LicenseDialog.DialogType.DeviceLimit:
                return qsTr("我知道了")
            case LicenseDialog.DialogType.Update:
                return qsTr("立即更新")
            default:
                return qsTr("确定")
        }
    }

    // 显示授权过期对话框
    function showExpired(message) {
        dialogType = LicenseDialog.DialogType.Expired
        dialogTitle = qsTr("授权过期")
        dialogMessage = message
        actionUrl = ""
        exitOnClose = true
        open()
    }

    // 显示设备超限对话框
    function showDeviceLimit(message) {
        dialogType = LicenseDialog.DialogType.DeviceLimit
        dialogTitle = qsTr("设备超限")
        dialogMessage = message
        actionUrl = ""
        exitOnClose = true
        open()
    }

    // 显示更新提示对话框
    function showUpdate(message, url) {
        dialogType = LicenseDialog.DialogType.Update
        dialogTitle = qsTr("更新提示")
        dialogMessage = message
        actionUrl = url
        exitOnClose = false
        open()
    }

    // 显示一般错误对话框
    function showError(title, message) {
        dialogType = LicenseDialog.DialogType.Error
        dialogTitle = title
        dialogMessage = message
        actionUrl = ""
        exitOnClose = true
        open()
    }
}
