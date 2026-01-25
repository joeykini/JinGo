import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0

/**
 * 跨平台图标组件
 * - Android 上使用 SVG 图标
 * - 桌面端使用 Unicode 符号
 */
Item {
    id: root

    // 图标名称，对应 SVG 文件名和 Unicode 符号
    property string icon: ""

    // 图标大小
    property int size: 20

    // 图标颜色
    property color color: Theme.colors.textPrimary

    implicitWidth: size
    implicitHeight: size

    // 图标映射表：icon name -> { svg: "path", unicode: "symbol" }
    readonly property var iconMap: ({
        "traffic": { svg: "qrc:/icons/traffic.svg", unicode: "↕" },
        "clock": { svg: "qrc:/icons/clock.svg", unicode: "◷" },
        "order": { svg: "qrc:/icons/order.svg", unicode: "◫" },
        "edit": { svg: "qrc:/icons/edit.svg", unicode: "✎" },
        "key": { svg: "qrc:/icons/key.svg", unicode: "⚿" },
        "timer": { svg: "qrc:/icons/timer.svg", unicode: "⏱" },
        "refresh": { svg: "qrc:/icons/refresh.svg", unicode: "↻" },
        "device": { svg: "qrc:/icons/device.svg", unicode: "⬡" },
        "speed": { svg: "qrc:/icons/speed.svg", unicode: "⚡" },
        "copy": { svg: "qrc:/icons/copy.svg", unicode: "⧉" },
        "subscription": { svg: "qrc:/icons/subscription.svg", unicode: "★" },
        "calendar": { svg: "qrc:/icons/calendar.svg", unicode: "📅" },
        "help": { svg: "qrc:/icons/help.svg", unicode: "?" },
        "chevron": { svg: "", unicode: "»" }
    })

    // 是否使用 SVG（Android 平台）
    readonly property bool useSvg: Qt.platform.os === "android" &&
                                   iconMap[icon] && iconMap[icon].svg !== ""

    // SVG 图标（Android）
    Image {
        id: svgIcon
        visible: useSvg
        anchors.centerIn: parent
        width: root.size
        height: root.size
        source: useSvg && iconMap[icon] ? iconMap[icon].svg : ""
        sourceSize: Qt.size(root.size, root.size)
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
    }

    // Unicode 符号（桌面端）
    Label {
        id: unicodeLabel
        visible: !useSvg
        anchors.centerIn: parent
        text: iconMap[icon] ? iconMap[icon].unicode : icon
        font.pixelSize: root.size
        color: root.color
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
