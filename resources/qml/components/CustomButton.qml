import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Button {
    id: control

    // 平台检测
    readonly property bool isMobile: Qt.platform.os === "android" ||
        Qt.platform.os === "ios" ||
        Qt.platform.os === "winrt"
    readonly property bool isDesktop: !isMobile

    // 自定义属性
    property string iconSource: ""
    property color buttonColor: Theme.colors.primary
    property color hoverColor: {
        if (buttonColor === "transparent") {
            return Qt.rgba(0.5, 0.5, 0.5, 0.1)
        }
        return Theme.lighten(buttonColor, 1.1)
    }
    property color pressedColor: {
        if (buttonColor === "transparent") {
            return Qt.rgba(0.5, 0.5, 0.5, 0.2)
        }
        return Theme.darken(buttonColor, 1.1)
    }
    property bool isCircular: false
    property color textColor: "white"  // 自定义文字颜色

    // 按钮变体: "primary", "secondary", "success", "warning", "error"
    property string variant: "primary"

    // ⭐ 设置默认大小（可以被 Layout.preferredWidth/Height 覆盖）
    implicitWidth: 100
    implicitHeight: isMobile ? 36 : 32

    // 桌面端启用悬停
    hoverEnabled: isDesktop

    // 根据变体自动设置颜色（仅在未显式设置 buttonColor 时）
    Component.onCompleted: {
        // 如果 buttonColor 已经被显式设置（不等于默认值），则不覆盖
        if (buttonColor === Theme.colors.primary) {
            switch (variant) {
                case "secondary":
                    buttonColor = Theme.colors.secondary
                    break
                case "success":
                    buttonColor = Theme.colors.success
                    break
                case "warning":
                    buttonColor = Theme.colors.warning
                    break
                case "error":
                    buttonColor = Theme.colors.error
                    break
                default:
                    buttonColor = Theme.colors.primary
            }
        }

        // 更新 hover 和 pressed 颜色
        if (buttonColor !== "transparent") {
            hoverColor = Theme.lighten(buttonColor, 1.1)
            pressedColor = Theme.darken(buttonColor, 1.1)
        }
        // 对于透明背景，hoverColor 和 pressedColor 已经在属性绑定中定义了
    }

    // 背景
    background: Rectangle {
        implicitWidth: 100
        implicitHeight: isMobile ? 36 : 32
        radius: isCircular ? Math.min(control.width, control.height) / 2 :
                (isMobile ? Theme.radius.md : Theme.radius.sm)

        // 根据状态改变颜色
        color: {
            if (!control.enabled) {
                // 禁用时使用浅灰色背景
                return Theme.alpha(control.buttonColor, 0.4)
            }
            if (control.pressed || control.down) {
                return control.pressedColor
            }
            if (isDesktop && control.hovered) {
                return control.hoverColor
            }
            return control.buttonColor
        }

        // 平滑颜色过渡
        Behavior on color {
            ColorAnimation {
                duration: isMobile ? Theme.duration.fast : Theme.duration.normal
                easing.type: Theme.easing.standard
            }
        }
    }

    // 内容项 - 完美居中
    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        RowLayout {
            id: contentRow
            spacing: isMobile ? Theme.spacing.sm : Theme.spacing.xs
            anchors.centerIn: parent

            // 图标
            Image {
                source: control.iconSource
                width: {
                    if (control.isCircular) {
                        return control.width / 3
                    }
                    return isMobile ? Theme.size.icon.lg : Theme.size.icon.md
                }
                height: {
                    if (control.isCircular) {
                        return control.height / 3
                    }
                    return isMobile ? Theme.size.icon.lg : Theme.size.icon.md
                }
                visible: control.iconSource !== ""
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
                smooth: true
                antialiasing: true
            }

            // 文本
            Label {
                text: control.text
                visible: !control.isCircular && control.text !== ""
                color: {
                    if (!control.enabled) {
                        // 禁用时文字半透明
                        return Qt.rgba(control.textColor.r, control.textColor.g, control.textColor.b, 0.6)
                    }
                    // 使用自定义文字颜色
                    return control.textColor
                }
                font.pixelSize: isMobile ? Theme.typography.body1 : Theme.typography.body2
                font.weight: Theme.typography.weightBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // 鼠标光标样式（仅桌面端）
    MouseArea {
        anchors.fill: parent
        cursorShape: isDesktop && control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: isDesktop

        onPressed: function(mouse) {
            mouse.accepted = false  // 不拦截点击事件，让Button处理
        }
    }

    // 移动端触摸反馈：按下缩小
    scale: (isMobile && control.pressed) ? 0.96 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Theme.duration.fast
            easing.type: Theme.easing.standard
        }
    }
}