pragma Singleton
import QtQuick 2.15

/**
 * 字体加载器
 * 在 Android 上加载自定义字体文件
 */
QtObject {
    id: fontLoader

    // 苹方体（如果有授权可以使用）
    property var pingFangSC: FontLoader {
        source: Qt.resolvedUrl("qrc:/fonts/PingFangSC-Regular.ttf")
        onStatusChanged: {
            if (status === FontLoader.Ready) {
            } else if (status === FontLoader.Error) {
            }
        }
    }

    // 思源黑体（开源替代方案，推荐）
    property var sourceHanSansSC: FontLoader {
        source: Qt.resolvedUrl("qrc:/fonts/SourceHanSansSC-Regular.otf")
        onStatusChanged: {
            if (status === FontLoader.Ready) {
            } else if (status === FontLoader.Error) {
            }
        }
    }

    // Noto Sans CJK SC（Google版本的思源黑体）
    property var notoSansCJKSC: FontLoader {
        source: Qt.resolvedUrl("qrc:/fonts/NotoSansCJKSC-Regular.otf")
        onStatusChanged: {
            if (status === FontLoader.Ready) {
            } else if (status === FontLoader.Error) {
            }
        }
    }

    /**
     * 获取加载后的字体名称
     * 优先使用PingFang SC，如果未加载则使用思源黑体
     */
    readonly property string loadedFontFamily: {
        if (Qt.platform.os === "android") {
            // Android上使用自定义字体
            if (pingFangSC.status === FontLoader.Ready && pingFangSC.name !== "") {
                return pingFangSC.name
            } else if (sourceHanSansSC.status === FontLoader.Ready && sourceHanSansSC.name !== "") {
                return sourceHanSansSC.name
            } else if (notoSansCJKSC.status === FontLoader.Ready && notoSansCJKSC.name !== "") {
                return notoSansCJKSC.name
            } else {
                return "Roboto"  // 回退到系统默认字体
            }
        } else {
            return ""  // iOS/macOS使用系统字体
        }
    }

    // 字体加载状态
    readonly property bool isReady: {
        if (Qt.platform.os === "android") {
            return pingFangSC.status === FontLoader.Ready ||
                   sourceHanSansSC.status === FontLoader.Ready ||
                   notoSansCJKSC.status === FontLoader.Ready
        }
        return true
    }
}
