// qml/components/RegisterForm.qml (优化版 - 使用主题和新组件)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

ColumnLayout {
    id: registerForm

    // 绑定外部 ViewModel（使用 RegisterViewModel）
    property var viewModel: registerViewModel

    // 注册成功状态
    property bool isSuccess: false

    spacing: Theme.spacing.md

    // 监听注册成功信号
    Connections {
        target: viewModel
        function onRegistrationSucceeded() {
            registerForm.isSuccess = true
        }
    }

    // 确保高度能正确传递给父组件
    Layout.fillWidth: true
    implicitHeight: childrenRect.height

    // 邮箱输入框
    BaseInput {
        id: emailField
        Layout.fillWidth: true

        label: qsTr("Email")
        placeholderText: qsTr("Enter email address")
        required: true

        text: viewModel ? viewModel.registerEmail : ""
        onTextChanged: { if (viewModel) viewModel.registerEmail = text }

        // 回车切换到验证码输入
        onAccepted: emailCodeField.focus()
    }

    // 邮箱验证码输入框（带发送按钮）- 仅在后台启用邮箱验证时显示
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.sm
        visible: systemConfigManager.guestConfigLoaded && systemConfigManager.isEmailVerifyEnabled

        BaseInput {
            id: emailCodeField
            Layout.fillWidth: true

            label: qsTr("Email Verification Code")
            placeholderText: qsTr("Enter verification code")
            required: systemConfigManager.isEmailVerifyEnabled

            text: viewModel ? viewModel.emailCode : ""
            onTextChanged: { if (viewModel) viewModel.emailCode = text }

            // 回车切换到密码输入
            onAccepted: passwordField.focus()
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
                    } else if (viewModel.codeCountdown > 0) {
                        return qsTr("Resend (%1s)").arg(viewModel.codeCountdown)
                    }
                }
                return qsTr("Send Code")
            }

            variant: "secondary"
            enabled: viewModel ? (!viewModel.isSendingCode && viewModel.codeCountdown === 0) : false
            opacity: enabled ? 1.0 : 0.6

            onClicked: {
                if (viewModel) {
                    viewModel.sendEmailCode()
                }
            }
        }
    }

    // 密码输入框
    BaseInput {
        id: passwordField
        Layout.fillWidth: true

        label: qsTr("Password")
        placeholderText: qsTr("Enter password (min 6 chars)")
        echoMode: TextInput.Password
        passwordToggleEnabled: true
        required: true

        text: viewModel ? viewModel.registerPassword : ""
        onTextChanged: { if (viewModel) viewModel.registerPassword = text }

        // 回车切换到邀请码输入
        onAccepted: inviteCodeField.focus()
    }

    // 邀请码输入框（根据后台配置决定是否必填）
    BaseInput {
        id: inviteCodeField
        Layout.fillWidth: true

        label: systemConfigManager.isInviteForce ? qsTr("Invite Code") : qsTr("Invite Code (Optional)")
        placeholderText: systemConfigManager.isInviteForce ? qsTr("Enter invite code") : qsTr("Enter invite code if you have one")
        required: systemConfigManager.isInviteForce

        text: viewModel ? viewModel.inviteCode : ""
        onTextChanged: { if (viewModel) viewModel.inviteCode = text }

        // 回车触发注册
        onAccepted: if (registerButton.enabled) registerButton.clicked()
    }

    // 服务条款同意复选框（如果配置了 tosUrl）
    Row {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.xs
        Layout.preferredHeight: 24
        spacing: 8
        visible: systemConfigManager.tosUrl && systemConfigManager.tosUrl.length > 0

        Rectangle {
            id: tosCheckBoxRect
            width: 20
            height: 20
            radius: 4
            border.width: 1
            border.color: tosCheckBox.checked ? Theme.colors.primary : Theme.colors.border
            color: tosCheckBox.checked ? Theme.colors.primary : "transparent"
            y: (parent.height - height) / 2

            property alias checked: tosCheckBox.checked

            Text {
                anchors.centerIn: parent
                text: "✓"
                font.pixelSize: 14
                color: "white"
                visible: tosCheckBox.checked
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tosCheckBox.checked = !tosCheckBox.checked
            }

            CheckBox {
                id: tosCheckBox
                visible: false
                checked: false
            }
        }

        Label {
            text: qsTr("I agree to the")
            font.pixelSize: 13
            color: Theme.colors.textSecondary
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }

        Label {
            text: qsTr("Terms of Service")
            font.pixelSize: 13
            font.underline: true
            color: Theme.colors.primary
            height: parent.height
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(systemConfigManager.tosUrl)
            }
        }
    }

    // reCAPTCHA 验证（如果启用）
    Loader {
        id: recaptchaLoader
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 78 : 0
        visible: systemConfigManager.isRecaptchaEnabled && systemConfigManager.recaptchaSiteKey.length > 0
        active: visible
        sourceComponent: recaptchaComponent
    }

    Component {
        id: recaptchaComponent
        Rectangle {
            color: Theme.colors.inputBackground
            radius: 4
            border.width: 1
            border.color: Theme.colors.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                CheckBox {
                    id: recaptchaCheckBox
                    Layout.alignment: Qt.AlignVCenter
                    padding: 0
                    spacing: 0

                    indicator: Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 4
                        border.width: 2
                        border.color: recaptchaCheckBox.checked ? "#4CAF50" : "#CCCCCC"
                        color: recaptchaCheckBox.checked ? "#4CAF50" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                            visible: recaptchaCheckBox.checked
                        }
                    }

                    contentItem: Item { width: 0; height: 0 }

                    onCheckedChanged: {
                        if (viewModel) {
                            // 简化版：直接设置验证通过（实际应用需要集成真正的 reCAPTCHA）
                            viewModel.recaptchaToken = checked ? "verified" : ""
                        }
                    }
                }

                Label {
                    text: qsTr("I'm not a robot")
                    font.pixelSize: 14
                    color: Theme.colors.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Image {
                    source: "qrc:/images/recaptcha_logo.png"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    fillMode: Image.PreserveAspectFit
                    visible: false  // 如果有 logo 图片可以显示
                }
            }
        }
    }

    // 错误信息显示
    Label {
        visible: viewModel && viewModel.errorMessage !== ""
        text: viewModel ? viewModel.errorMessage : ""
        color: Theme.colors.error
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    // 注册按钮
    CustomButton {
        id: registerButton
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.sm
        Layout.preferredHeight: {
            var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
            return isMobile ? 56 : 48
        }

        text: {
            if (registerForm.isSuccess) {
                return qsTr("Registration Successful")
            } else if (viewModel && viewModel.isProcessing) {
                return qsTr("Signing up...")
            }
            return qsTr("Register")
        }
        variant: "primary"
        buttonColor: registerForm.isSuccess ? Theme.colors.success : "#2E7D32"
        textColor: "white"

        // 检查服务条款是否需要同意
        property bool tosRequired: systemConfigManager.tosUrl && systemConfigManager.tosUrl.length > 0
        property bool tosAgreed: !tosRequired || tosCheckBox.checked

        // 检查 reCAPTCHA 是否需要验证
        property bool recaptchaRequired: systemConfigManager.isRecaptchaEnabled
        property bool recaptchaVerified: !recaptchaRequired || (viewModel && viewModel.recaptchaToken && viewModel.recaptchaToken.length > 0)

        enabled: registerForm.isSuccess ? false : (viewModel ? (!viewModel.isProcessing && tosAgreed && recaptchaVerified) : false)
        opacity: (enabled || registerForm.isSuccess) ? 1.0 : 0.6

        onClicked: {
            if (viewModel) {
                viewModel.registerUser()
            }
        }
    }
}