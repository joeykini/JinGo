// FlagIcon.qml - 国旗图标组件
import QtQuick 2.15
import QtQuick.Controls 2.15

/**
 * 国旗图标组件
 *
 * 使用 SVG 国旗图片实现跨平台国旗显示
 * 如果没有对应国家的图片，则显示带有国家代码的圆形徽章
 */
Item {
    id: flagIcon

    // 国家代码（ISO 3166-1 alpha-2，如 "US", "CN"）
    property string countryCode: ""

    // 显示大小
    property int size: 24

    // 是否使用圆形
    property bool rounded: true

    width: size
    height: size

    // 支持的国旗列表
    readonly property var supportedFlags: [
        "ad", "ae", "af", "al", "am", "ar", "at", "au", "az", "ba",
        "bd", "be", "bg", "bh", "bn", "br", "by", "ca", "ch", "cl",
        "cn", "co", "cy", "cz", "de", "dk", "ee", "eg", "es", "fi",
        "fr", "gb", "ge", "gr", "hk", "hr", "hu", "id", "ie", "il",
        "in", "iq", "ir", "is", "it", "jo", "jp", "kg", "kh", "kr",
        "kw", "kz", "la", "lb", "li", "lk", "lt", "lu", "lv", "mc",
        "md", "me", "mk", "mm", "mt", "mx", "my", "ng", "nl", "no",
        "np", "nz", "om", "pe", "ph", "pk", "pl", "ps", "pt", "qa",
        "ro", "rs", "ru", "sa", "se", "sg", "si", "sk", "sm", "sy",
        "th", "tj", "tm", "tr", "tw", "ua", "us", "uz", "ve", "vn",
        "xk", "ye", "za"
    ]

    // 检查是否有对应国旗图片
    function hasFlag(code) {
        if (!code || code.length < 2) return false
        return supportedFlags.indexOf(code.toLowerCase().substring(0, 2)) !== -1
    }

    // 获取国旗图片路径
    function getFlagPath(code) {
        if (!code || code.length < 2) return ""
        return "qrc:/flags/" + code.toLowerCase().substring(0, 2) + ".svg"
    }

    // 根据国家代码生成背景色（用于fallback）
    function getBackgroundColor(code) {
        if (!code || code.length < 2) {
            return "#808080"
        }

        var colors = {
            "A": "#FF6B6B", "B": "#4ECDC4", "C": "#45B7D1", "D": "#96CEB4",
            "E": "#FFEAA7", "F": "#DDA0DD", "G": "#98D8C8", "H": "#F7DC6F",
            "I": "#BB8FCE", "J": "#85C1E9", "K": "#F8B500", "L": "#58D68D",
            "M": "#EC7063", "N": "#5DADE2", "O": "#F39C12", "P": "#9B59B6",
            "Q": "#1ABC9C", "R": "#E74C3C", "S": "#3498DB", "T": "#2ECC71",
            "U": "#E67E22", "V": "#9C88FF", "W": "#FDA7DF", "X": "#7DCEA0",
            "Y": "#F5B041", "Z": "#AED6F1"
        }

        var firstChar = code.charAt(0).toUpperCase()
        return colors[firstChar] || "#808080"
    }

    // 国旗图片容器（圆形裁剪）
    Rectangle {
        id: flagContainer
        anchors.fill: parent
        radius: rounded ? size / 2 : 4
        color: "transparent"
        clip: true
        visible: hasFlag(countryCode)

        Image {
            id: flagImage
            anchors.centerIn: parent
            width: parent.width * 1.4  // 稍微放大以填满圆形
            height: parent.height * 1.4
            source: hasFlag(countryCode) ? getFlagPath(countryCode) : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
        }

        // 圆形边框
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.1)
        }
    }

    // Fallback: 国家代码徽章（当没有国旗图片时显示）
    Rectangle {
        id: fallbackBadge
        anchors.fill: parent
        radius: rounded ? size / 2 : 4
        color: getBackgroundColor(countryCode)
        visible: !hasFlag(countryCode)

        Text {
            id: codeText
            anchors.centerIn: parent
            text: {
                if (!countryCode || countryCode.length < 2) {
                    return "?"
                }
                return countryCode.substring(0, 2).toUpperCase()
            }
            font.pixelSize: size * 0.45
            font.bold: true
            font.family: "Arial"
            color: "white"
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.3)
        }
    }
}
