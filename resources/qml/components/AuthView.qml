// qml/components/AuthView.qml (FIXED)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

ColumnLayout {
    id: authView

    // 当前显示的表单类型：login(登录) / register(注册) / forgot(找回密码)
    property string currentForm: "login"

    Layout.fillWidth: true

    // 切换表单时动态替换 StackView 内容，避免多余节点堆积
    onCurrentFormChanged: {
        if (currentForm === "login") {
            formStack.replace("qrc:/qml/components/LoginForm.qml")
        } else if (currentForm === "register") {
            formStack.replace("qrc:/qml/components/RegisterForm.qml")
        } else if (currentForm === "forgot") {
            formStack.replace("qrc:/qml/components/ForgotPasswordForm.qml")
        }
    }

    // 表单容器：根据 currentForm 显示不同组件
    StackView {
        id: formStack
        Layout.fillWidth: true
        Layout.preferredHeight: currentItem ? currentItem.implicitHeight : 300
        initialItem: "qrc:/qml/components/LoginForm.qml" // 默认进入登录页面

        // 平滑的高度过渡动画
        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    // 界面底部的切换入口
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.leftMargin: 20   // 整体左边距
        Layout.rightMargin: 20  // 整体右边距
        spacing: 10

        // 注册入口：仅在登录页面显示，且后台允许注册时才显示
        Label {
            text: qsTr("Sign Up")
            color: "#007BFF" // 链接风格
            Layout.alignment: Qt.AlignLeft
            visible: currentForm === "login" && systemConfigManager.registerEnabled
            MouseArea {
                anchors.fill: parent
                onClicked: authView.currentForm = "register"
            }
        }

        Item { Layout.fillWidth: true } // 弹性占位用于推开左右内容

        // 忘记密码入口：仅在登录页面显示
        Label {
            text: qsTr("Forgot Password?")
            color: Theme.colors.warning
            Layout.alignment: Qt.AlignRight
            visible: currentForm === "login"
            MouseArea {
                anchors.fill: parent
                onClicked: authView.currentForm = "forgot"
            }
        }

        // 返回登录入口：当处于注册/找回界面时显示
        Label {
            text: qsTr("Back to Login")
            color: "#007BFF"
            Layout.alignment: Qt.AlignHCenter
            visible: currentForm !== "login"
            MouseArea {
                anchors.fill: parent
                onClicked: authView.currentForm = "login"
            }
        }
    }

    // 延迟跳转定时器
    Timer {
        id: redirectTimer
        interval: 3000
        repeat: false
        onTriggered: {
            authView.currentForm = "login"
        }
    }

    // 监听注册成功信号，3秒后自动切换到登录页面
    Connections {
        target: registerViewModel
        function onRegistrationSucceeded() {
            redirectTimer.start()
        }
    }

    // 监听重置密码成功信号，3秒后自动切换到登录页面
    Connections {
        target: loginViewModel
        function onPasswordResetSucceeded() {
            redirectTimer.start()
        }
    }

    Component.onCompleted: {
        // 初始化时强制加载登录表单，确保 StackView 状态一致
        formStack.replace("qrc:/qml/components/LoginForm.qml")
    }
}
