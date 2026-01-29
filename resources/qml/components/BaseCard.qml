import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

// 统一的卡片基础组件
Rectangle {
    id: root

    // 自定义属性
    property int padding: Theme.spacing.md
    property int borderWidth: 0
    property color borderColor: Theme.colors.cardBorder
    property alias contentItem: contentLoader.sourceComponent
    property bool clickable: false
    property bool hoverable: true

    // 阴影级别: "none", "sm", "md", "lg", "xl"
    property string elevation: "none"

    // 交互状态
    property bool hovered: false
    property bool pressed: false

    // 信号
    signal clicked()

    // 样式
    color: Theme.colors.cardBackground
    radius: Theme.radius.md
    border.width: borderWidth
    border.color: borderColor

    // 阴影效果 (通过叠加半透明层模拟)
    Rectangle {
        id: shadowLayer
        anchors.fill: parent
        anchors.margins: -getShadowBlur()
        radius: parent.radius
        color: "transparent"
        border.width: 0
        z: -1
        visible: elevation !== "none"

        // 阴影渐变
        layer.enabled: true
        layer.effect: Item {
            Rectangle {
                anchors.fill: parent
                radius: shadowLayer.radius
                color: getShadowColor()
                opacity: 0.6

                // 模糊效果（简单版本，使用多层半透明矩形）
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius
                    color: parent.color
                    opacity: 0.4
                }
            }
        }
    }

    // 悬停效果
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.colors.surfaceHover
        opacity: (hoverable && hovered && !pressed) ? 0.05 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.duration.fast
                easing.type: Theme.easing.standard
            }
        }
    }

    // 按压效果
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.colors.textPrimary
        opacity: pressed ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.duration.instant
                easing.type: Theme.easing.standard
            }
        }
    }

    // 内容容器
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.padding

        Loader {
            id: contentLoader
            anchors.fill: parent
        }
    }

    // 鼠标区域 (仅在 clickable 时启用)
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: clickable
        hoverEnabled: hoverable || clickable
        cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

        onEntered: {
            if (hoverable) {
                root.hovered = true
            }
        }

        onExited: {
            root.hovered = false
        }

        onPressed: {
            if (clickable) {
                root.pressed = true
            }
        }

        onReleased: {
            root.pressed = false
        }

        onClicked: {
            if (clickable) {
                root.clicked()
            }
        }
    }

    // 缩放动画 (按压时)
    scale: pressed ? 0.98 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.duration.fast
            easing.type: Theme.easing.standard
        }
    }

    // 辅助函数
    function getShadowColor() {
        switch (elevation) {
            case "sm": return Theme.shadow.sm.color
            case "md": return Theme.shadow.md.color
            case "lg": return Theme.shadow.lg.color
            case "xl": return Theme.shadow.xl.color
            default: return "transparent"
        }
    }

    function getShadowBlur() {
        switch (elevation) {
            case "sm": return Theme.shadow.sm.blur
            case "md": return Theme.shadow.md.blur
            case "lg": return Theme.shadow.lg.blur
            case "xl": return Theme.shadow.xl.blur
            default: return 0
        }
    }
}