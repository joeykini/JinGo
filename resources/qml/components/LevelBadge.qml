// LevelBadge.qml - 会员等级徽章组件
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import JinGo 1.0

/**
 * 会员等级徽章组件
 *
 * 根据等级显示炫彩商务风格的徽章
 * 等级: 0=免费, 1=标准, 2=高级, 3=专业, 4=旗舰, 5=企业
 */
Rectangle {
    id: levelBadge

    // 等级 (0-5)
    property int level: 0

    // 等级名称 (可选覆盖)
    property string levelName: ""

    // 紧凑模式
    property bool compact: false

    // 大小
    property int size: compact ? 24 : 32

    // 是否是 Android 平台
    readonly property bool isAndroid: Qt.platform.os === "android"

    // 等级配置 - Android 使用简单符号，桌面端使用 Unicode 符号
    readonly property var levelConfigs: [
        { name: qsTr("Free"), icon: isAndroid ? "F" : "◇", colors: ["#9E9E9E", "#757575"], glow: "#BDBDBD" },
        { name: qsTr("Standard"), icon: isAndroid ? "S" : "◆", colors: ["#4CAF50", "#2E7D32"], glow: "#81C784" },
        { name: qsTr("Premium"), icon: isAndroid ? "P" : "★", colors: ["#FF9800", "#F57C00"], glow: "#FFB74D" },
        { name: qsTr("Pro"), icon: isAndroid ? "+" : "✦", colors: ["#2196F3", "#1565C0"], glow: "#64B5F6" },
        { name: qsTr("Elite"), icon: isAndroid ? "E" : "♦", colors: ["#9C27B0", "#6A1B9A"], glow: "#BA68C8" },
        { name: qsTr("Enterprise"), icon: isAndroid ? "V" : "♛", colors: ["#FFD700", "#FF8F00"], glow: "#FFE082" }
    ]

    // 获取当前等级配置
    function getLevelConfig() {
        var idx = Math.max(0, Math.min(level, levelConfigs.length - 1))
        return levelConfigs[idx]
    }

    width: compact ? (badgeRow.implicitWidth + 16) : (badgeRow.implicitWidth + 24)
    height: size
    radius: size / 2

    // 渐变背景
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: getLevelConfig().colors[0] }
        GradientStop { position: 1.0; color: getLevelConfig().colors[1] }
    }

    // 外发光效果
    layer.enabled: !compact
    layer.effect: Item {
        Rectangle {
            anchors.centerIn: parent
            width: levelBadge.width + 4
            height: levelBadge.height + 4
            radius: levelBadge.radius + 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(
                Qt.lighter(getLevelConfig().glow).r,
                Qt.lighter(getLevelConfig().glow).g,
                Qt.lighter(getLevelConfig().glow).b,
                0.3
            )
        }
    }

    // 闪光动画效果
    Rectangle {
        id: shimmer
        width: parent.width * 0.3
        height: parent.height
        radius: parent.radius
        opacity: 0.3
        visible: level >= 2 && !compact

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "white" }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
            loops: Animation.Infinite
            running: level >= 2 && !compact

            NumberAnimation {
                from: -shimmer.width
                to: levelBadge.width
                duration: 2000
                easing.type: Easing.InOutQuad
            }

            PauseAnimation { duration: 1000 }
        }
    }

    // 内容
    RowLayout {
        id: badgeRow
        anchors.centerIn: parent
        spacing: compact ? 4 : 6

        // 等级图标
        Text {
            text: getLevelConfig().icon
            font.pixelSize: compact ? 12 : 16
            font.bold: true
            color: "white"
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.2)
        }

        // 等级名称
        Text {
            text: levelName || getLevelConfig().name
            font.pixelSize: compact ? 10 : 12
            font.bold: true
            font.letterSpacing: 0.5
            color: "white"
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.2)
        }
    }

    // 鼠标悬停效果
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            levelBadge.scale = 1.05
        }

        onExited: {
            levelBadge.scale = 1.0
        }
    }

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }
}
