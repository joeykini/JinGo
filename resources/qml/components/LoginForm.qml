// qml/components/LoginForm.qml (优化版 - 使用主题和新组件)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

ColumnLayout {
    id: loginForm

    // 绑定外部 ViewModel，实际登录行为与验证均由其处理
    property var viewModel: loginViewModel

    spacing: Theme.spacing.md

    // 确保高度能正确传递给父组件
    Layout.fillWidth: true
    implicitHeight: childrenRect.height

    // 用户名/邮箱输入框
    BaseInput {
        id: emailField
        Layout.fillWidth: true

        label: qsTr("Email/Username")
        placeholderText: qsTr("Enter email or username")
        required: true

        text: viewModel.email ?? ""
        onTextChanged: if (viewModel) viewModel.setEmail(text)

        // 输入用户名后回车切到密码输入
        onAccepted: passwordField.focus()
    }

    // 密码输入框
    BaseInput {
        id: passwordField
        Layout.fillWidth: true

        label: qsTr("Password")
        placeholderText: qsTr("Enter password")
        echoMode: TextInput.Password
        passwordToggleEnabled: true
        required: true

        text: viewModel.password ?? ""
        onTextChanged: if (viewModel) viewModel.setPassword(text)

        // 显示错误信息
        showError: viewModel && viewModel.errorMessage !== ""
        errorText: viewModel.errorMessage ?? ""

        // 回车触发登录
        onAccepted: if (loginButton.enabled) loginButton.clicked()
    }

    // 记住密码复选框
    Row {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.xs
        Layout.preferredHeight: 24
        spacing: 12

        Rectangle {
            id: rememberCheckBoxRect
            width: 20
            height: 20
            radius: 4
            border.width: 1
            border.color: rememberCheckBox.checked ? Theme.colors.primary : Theme.colors.border
            color: rememberCheckBox.checked ? Theme.colors.primary : "transparent"
            y: (parent.height - height) / 2

            Text {
                anchors.centerIn: parent
                text: "✓"
                font.pixelSize: 14
                color: "white"
                visible: rememberCheckBox.checked
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: rememberCheckBox.checked = !rememberCheckBox.checked
            }

            CheckBox {
                id: rememberCheckBox
                visible: false
                checked: viewModel ? viewModel.rememberPassword : false
                onCheckedChanged: if (viewModel) viewModel.setRememberPassword(checked)
            }
        }

        Label {
            text: qsTr("Remember password")
            font.pixelSize: Theme.typography.body2
            color: Theme.colors.textSecondary
            height: parent.height
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: rememberCheckBox.checked = !rememberCheckBox.checked
            }
        }
    }

    // 登录按钮
    CustomButton {
        id: loginButton
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.sm
        Layout.preferredHeight: {
            var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
            return isMobile ? 56 : 48
        }

        // 登录状态反馈
        text: viewModel && viewModel.isLoggingIn ? qsTr("Logging in...") : qsTr("Login")
        variant: "primary"
        textColor: "white"

        // 正在登录 → 禁用按钮
        enabled: viewModel ? !viewModel.isLoggingIn : false
        opacity: enabled ? 1.0 : 0.6

        // 点击触发登录
        onClicked: if (viewModel) viewModel.login()
    }

    // 登录成功清除错误
    Connections {
        target: viewModel
        function onLoginSucceeded() {
            // 登录成功后隐藏错误文本
            if (viewModel.errorMessage !== "")
                viewModel.clearError()
        }
    }
}