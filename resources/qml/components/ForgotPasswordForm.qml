// qml/components/ForgotPasswordForm.qml (xboard 兼容版 - 使用邮箱验证码重置密码)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

ColumnLayout {
    id: forgotPasswordForm

    // 绑定外部 ViewModel
    property var viewModel: loginViewModel

    // 重置成功状态
    property bool isSuccess: false

    spacing: Theme.spacing.md

    // 监听重置密码成功信号
    Connections {
        target: viewModel
        function onPasswordResetSucceeded() {
            forgotPasswordForm.isSuccess = true
        }
    }

    // 确保高度能正确传递给父组件
    Layout.fillWidth: true
    implicitHeight: childrenRect.height

    // 提示文字
    Label {
        text: qsTr("Enter your email to receive a verification code, then set a new password.")
        font.pixelSize: 13
        color: Theme.colors.textSecondary
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        Layout.bottomMargin: Theme.spacing.sm
    }

    // 邮箱输入框
    BaseInput {
        id: emailField
        Layout.fillWidth: true

        label: qsTr("Email")
        placeholderText: qsTr("Enter registered email")
        required: true

        text: viewModel ? viewModel.forgotEmail : ""
        onTextChanged: { if (viewModel) viewModel.forgotEmail = text }

        // 回车切换到验证码输入
        onAccepted: emailCodeField.focus()
    }

    // 邮箱验证码输入框（带发送按钮）
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.sm

        BaseInput {
            id: emailCodeField
            Layout.fillWidth: true

            label: qsTr("Verification Code")
            placeholderText: qsTr("Enter verification code")
            required: true

            text: viewModel ? viewModel.forgotEmailCode : ""
            onTextChanged: { if (viewModel) viewModel.forgotEmailCode = text }

            // 回车切换到密码输入
            onAccepted: newPasswordField.focus()
        }

        // 发送验证码按钮
        CustomButton {
            id: sendCodeButton
            Layout.preferredWidth: {
                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                return isMobile ? 140 : 180
            }
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignBottom

            text: {
                if (viewModel) {
                    if (viewModel.isSendingCode) {
                        return qsTr("Sending...")
                    } else if (viewModel.forgotCodeCountdown > 0) {
                        return qsTr("Resend (%1s)").arg(viewModel.forgotCodeCountdown)
                    }
                }
                return qsTr("Send Code")
            }

            variant: "secondary"
            enabled: viewModel ? (!viewModel.isSendingCode && viewModel.forgotCodeCountdown === 0) : false
            opacity: enabled ? 1.0 : 0.6

            onClicked: {
                if (viewModel) {
                    viewModel.sendForgotEmailCode()
                }
            }
        }
    }

    // 新密码输入框
    BaseInput {
        id: newPasswordField
        Layout.fillWidth: true

        label: qsTr("New Password")
        placeholderText: qsTr("Enter new password (min 6 chars)")
        echoMode: TextInput.Password
        passwordToggleEnabled: true
        required: true

        text: viewModel ? viewModel.forgotNewPassword : ""
        onTextChanged: { if (viewModel) viewModel.forgotNewPassword = text }

        // 回车触发重置
        onAccepted: if (resetButton.enabled) resetButton.clicked()
    }

    // 错误信息显示
    Label {
        visible: viewModel && viewModel.errorMessage !== "" && !forgotPasswordForm.isSuccess
        text: viewModel ? viewModel.errorMessage : ""
        color: Theme.colors.error
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    // 重置密码按钮
    CustomButton {
        id: resetButton
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.sm
        Layout.preferredHeight: {
            var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
            return isMobile ? 56 : 48
        }

        text: {
            if (forgotPasswordForm.isSuccess) {
                return qsTr("Reset Successful")
            } else if (viewModel && viewModel.isProcessing) {
                return qsTr("Resetting...")
            }
            return qsTr("Reset Password")
        }
        variant: "primary"
        buttonColor: forgotPasswordForm.isSuccess ? Theme.colors.success : Theme.colors.warning
        textColor: "white"

        enabled: forgotPasswordForm.isSuccess ? false : (viewModel ? !viewModel.isProcessing : false)
        opacity: (enabled || forgotPasswordForm.isSuccess) ? 1.0 : 0.6

        onClicked: {
            if (viewModel) {
                viewModel.resetPasswordWithCode()
            }
        }
    }
}
