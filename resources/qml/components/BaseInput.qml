import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

// 统一的输入框组件
Item {
    id: root

    // 基础属性
    property alias text: textField.text
    property string placeholderText: ""  // 改为普通属性，用于自定义占位文字
    property int echoMode: TextInput.Normal  // 改为普通属性，不直接别名
    property alias validator: textField.validator
    property alias inputMethodHints: textField.inputMethodHints
    property alias readOnly: textField.readOnly
    property alias enabled: textField.enabled

    // 密码切换功能
    property bool passwordToggleEnabled: false
    property bool showPassword: false

    // 样式属性
    property string label: ""
    property string helperText: ""
    property string errorText: ""
    property bool showError: false
    property bool required: false

    // 图标
    property string leftIcon: ""
    property string rightIcon: ""

    // 尺寸: "sm", "md", "lg"
    property string size: "md"

    // 状态
    property bool hasFocus: textField.activeFocus
    property bool hasError: showError && errorText !== ""
    property bool isValid: !hasError && text.length > 0

    // 信号
    signal accepted()
    signal editingFinished()

    // 高度根据尺寸自动计算
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: 280

    // 主布局
    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: Theme.spacing.xs

        // 标签
        Label {
            id: labelText
            text: root.label + (root.required ? " *" : "")
            visible: root.label !== ""
            color: hasError ? Theme.colors.error : Theme.colors.textSecondary
            font.pixelSize: Theme.typography.caption
            font.weight: Theme.typography.weightMedium
            Layout.fillWidth: true

            Behavior on color {
                ColorAnimation {
                    duration: Theme.duration.fast
                }
            }
        }

        // 输入框容器
        Rectangle {
            id: inputContainer
            Layout.fillWidth: true
            Layout.preferredHeight: getInputHeight()

            color: root.enabled ? Theme.colors.inputBackground : Theme.alpha(Theme.colors.inputBackground, 0.5)
            radius: Theme.radius.xs
            border.width: 2
            border.color: getBorderColor()

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.duration.fast
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.sm
                anchors.rightMargin: Theme.spacing.sm
                spacing: Theme.spacing.xs

                // 左侧图标
                Image {
                    source: root.leftIcon
                    visible: root.leftIcon !== ""
                    Layout.preferredWidth: Theme.size.icon.sm
                    Layout.preferredHeight: Theme.size.icon.sm
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                    opacity: root.enabled ? 0.7 : 0.4
                }

                // 输入区域（包含自定义占位文字和文本输入）
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // 自定义占位文字（解决移动端占位文字不隐藏的问题）
                    Label {
                        id: placeholderLabel
                        anchors.fill: parent
                        anchors.leftMargin: 0
                        verticalAlignment: Text.AlignVCenter

                        text: root.placeholderText
                        color: Theme.colors.inputPlaceholder
                        font.pixelSize: getFontSize()

                        // 关键：只在输入框为空且没有焦点时显示
                        visible: textField.text.length === 0 && !textField.activeFocus
                        opacity: visible ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.duration.fast
                            }
                        }

                        // 点击占位文字时聚焦输入框
                        MouseArea {
                            anchors.fill: parent
                            onClicked: textField.forceActiveFocus()
                        }
                    }

                    // 文本输入
                    TextField {
                        id: textField
                        anchors.fill: parent

                        color: Theme.colors.textPrimary
                        selectionColor: Theme.alpha(Theme.colors.primary, 0.3)
                        selectedTextColor: Theme.colors.textPrimary

                        // 不使用内置的 placeholderText，使用上面的自定义占位文字
                        placeholderText: ""

                        // 根据密码切换状态决定显示模式
                        echoMode: {
                            if (root.passwordToggleEnabled && root.echoMode === TextInput.Password) {
                                return root.showPassword ? TextInput.Normal : TextInput.Password
                            }
                            return root.echoMode
                        }

                        font.pixelSize: getFontSize()

                        background: Rectangle {
                            color: "transparent"
                        }

                        // 键盘导航
                        KeyNavigation.tab: nextItemInFocusChain(true)
                        KeyNavigation.backtab: nextItemInFocusChain(false)

                        onAccepted: root.accepted()
                        onEditingFinished: root.editingFinished()
                    }
                }

                // 密码切换按钮或右侧图标
                Item {
                    visible: root.passwordToggleEnabled || root.rightIcon !== ""
                    Layout.preferredWidth: Theme.size.icon.sm
                    Layout.preferredHeight: Theme.size.icon.sm
                    Layout.alignment: Qt.AlignVCenter

                    // 密码切换按钮
                    Image {
                        id: passwordToggleIcon
                        anchors.fill: parent
                        visible: root.passwordToggleEnabled
                        source: root.showPassword ? "qrc:/icons/eye-open.svg" : "qrc:/icons/eye-closed.svg"
                        fillMode: Image.PreserveAspectFit
                        opacity: root.enabled ? 0.7 : 0.4

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showPassword = !root.showPassword
                            }
                        }
                    }

                    // 普通右侧图标
                    Image {
                        anchors.fill: parent
                        visible: !root.passwordToggleEnabled && root.rightIcon !== ""
                        source: root.rightIcon
                        fillMode: Image.PreserveAspectFit
                        opacity: root.enabled ? 0.7 : 0.4
                    }
                }

                // 验证状态图标
                Label {
                    visible: !hasError && isValid && !hasFocus
                    text: "✓"
                    color: Theme.colors.success
                    font.pixelSize: Theme.typography.body1
                    font.weight: Theme.typography.weightBold
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Focus 动画效果
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 0
                opacity: hasFocus ? 0.1 : 0

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 2
                    color: "transparent"
                    border.width: 4
                    border.color: Theme.alpha(Theme.colors.primary, 0.2)
                    visible: hasFocus
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.duration.fast
                    }
                }
            }
        }

        // 帮助文本 / 错误信息
        Label {
            id: helperLabel
            text: hasError ? root.errorText : root.helperText
            visible: text !== ""
            color: hasError ? Theme.colors.error : Theme.colors.textTertiary
            font.pixelSize: Theme.typography.small
            wrapMode: Text.Wrap
            Layout.fillWidth: true

            Behavior on color {
                ColorAnimation {
                    duration: Theme.duration.fast
                }
            }

            // 错误信息抖动动画
            SequentialAnimation {
                id: shakeAnimation
                running: false
                loops: 1

                NumberAnimation {
                    target: helperLabel
                    property: "x"
                    from: 0; to: -8
                    duration: 50
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: helperLabel
                    property: "x"
                    from: -8; to: 8
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: helperLabel
                    property: "x"
                    from: 8; to: 0
                    duration: 50
                    easing.type: Easing.InQuad
                }
            }
        }
    }

    // 辅助函数
    function getBorderColor() {
        if (!root.enabled) {
            return Theme.colors.border
        }
        if (hasError) {
            return Theme.colors.error
        }
        if (hasFocus) {
            return Theme.colors.inputBorderFocus
        }
        return Theme.colors.inputBorder
    }

    function getInputHeight() {
        switch (size) {
            case "sm": return Theme.size.input.sm
            case "lg": return Theme.size.input.lg
            default: return Theme.size.input.md
        }
    }

    function getFontSize() {
        switch (size) {
            case "sm": return Theme.typography.body2
            case "lg": return Theme.typography.body1
            default: return Theme.typography.body2
        }
    }

    // 公共方法
    function focus() {
        textField.forceActiveFocus()
    }

    function clear() {
        textField.clear()
    }

    function selectAll() {
        textField.selectAll()
    }

    // 监听错误状态变化，触发抖动动画
    onHasErrorChanged: {
        if (hasError) {
            shakeAnimation.start()
        }
    }
}