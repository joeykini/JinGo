// qml/components/ChangePasswordDialog.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Dialog {
    id: changePasswordDialog

    title: qsTr("Change Password")
    modal: true
    standardButtons: Dialog.NoButton

    width: Math.min(500, parent ? parent.width * 0.9 : 500)
    height: Math.min(420, parent ? parent.height * 0.8 : 420)

    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    // authManager 直接从全局上下文访问，不再作为属性传递
    property bool isProcessing: false
    property string errorMessage: ""

    background: Rectangle {
        color: Theme.colors.background
        radius: Theme.radius.lg
        border.width: 1
        border.color: Theme.colors.border
    }

    header: Rectangle {
        height: 60
        color: Theme.colors.background
        radius: Theme.radius.lg

        // 只有顶部圆角
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.radius.lg
            color: parent.color
        }

        Label {
            text: changePasswordDialog.title
            font.pixelSize: Theme.typography.body1
            font.weight: Theme.typography.weightBold
            color: Theme.colors.textPrimary
            anchors.centerIn: parent
        }
    }

    onOpened: {
        // 对话框打开时清空输入
        errorMessage = ""
        oldPasswordField.text = ""
        newPasswordField.text = ""
        oldPasswordField.forceActiveFocus()
    }

    onClosed: {
        // 对话框关闭时清空输入
        errorMessage = ""
        isProcessing = false
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing.md

        // 错误提示
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: Theme.radius.md
            color: Theme.alpha(Theme.colors.error, 0.1)
            border.width: 1
            border.color: Theme.colors.error
            visible: errorMessage !== ""

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.md
                spacing: Theme.spacing.sm

                Label {
                    text: "❌"
                    font.pixelSize: 24
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

        // 旧密码输入框
        BaseInput {
            id: oldPasswordField
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            label: qsTr("Current Password")
            placeholderText: qsTr("Enter current password")
            echoMode: TextInput.Password
            passwordToggleEnabled: true
            required: true

            onAccepted: newPasswordField.forceActiveFocus()
        }

        // 新密码输入框
        BaseInput {
            id: newPasswordField
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            label: qsTr("New Password")
            placeholderText: qsTr("Enter new password (min 8 chars)")
            echoMode: TextInput.Password
            passwordToggleEnabled: true
            required: true

            onAccepted: {
                if (changeButton.enabled) {
                    changeButton.clicked()
                }
            }
        }

        // 密码要求提示
        Label {
            text: qsTr("• Password must be at least 8 characters")
            font.pixelSize: Theme.typography.caption
            color: Theme.colors.textSecondary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // 弹性空间，确保内容不被压缩
        Item {
            Layout.fillHeight: true
        }
    }

    footer: Rectangle {
        implicitHeight: 60
        color: Theme.colors.background
        border.width: 1
        border.color: Theme.colors.border

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.colors.divider
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            spacing: Theme.spacing.md

            CustomButton {
                id: cancelButton
                text: qsTr("Cancel")
                variant: "outline"
                enabled: !isProcessing
                Layout.fillWidth: true
                implicitHeight: 44

                onClicked: {
                    changePasswordDialog.reject()
                }
            }

            CustomButton {
                id: changeButton
                text: qsTr("Save")
                variant: "primary"
                enabled: !isProcessing && oldPasswordField.text !== "" && newPasswordField.text !== ""
                Layout.fillWidth: true
                implicitHeight: 44

                onClicked: {
                    var oldPwd = oldPasswordField.text
                    var newPwd = newPasswordField.text

                    // 验证输入
                    if (oldPwd === "") {
                        errorMessage = qsTr("Please enter current password")
                        return
                    }

                    if (newPwd === "") {
                        errorMessage = qsTr("Please enter new password")
                        return
                    }

                    if (newPwd.length < 8) {
                        errorMessage = qsTr("New password must be at least 8 characters")
                        return
                    }

                    // 调用 API
                    if (authManager) {
                        errorMessage = ""
                        isProcessing = true
                        authManager.changePassword(oldPwd, newPwd)
                    } else {
                        errorMessage = qsTr("Internal error: authManager not available")
                    }
                }
            }
        }
    }

    // 连接 AuthManager 信号
    Connections {
        target: authManager

        function onPasswordChangeSucceeded() {
            isProcessing = false
            // 显示成功提示并关闭对话框
            changePasswordDialog.accept()
        }

        function onPasswordChangeFailed(error) {
            isProcessing = false
            errorMessage = error
        }
    }
}
