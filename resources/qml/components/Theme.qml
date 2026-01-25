pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme

    property var _sourceHanSansSC: FontLoader {
        source: "qrc:/fonts/SourceHanSansSC-Regular.otf"
        onStatusChanged: {
            if (status === FontLoader.Ready) {
            } else if (status === FontLoader.Error) {
            }
        }
    }

    property var _notoSansCJKSC: FontLoader {
        source: "qrc:/fonts/NotoSansCJKSC-Regular.otf"
        onStatusChanged: {
            if (status === FontLoader.Ready) {
            } else if (status === FontLoader.Error) {
            }
        }
    }

    property var jingoTheme: ({
        "name": "JinGO",
        "displayName": "JinGO",
        "light": {
            "background": "#FFF9E8",
            "surface": "#FFFEF7",
            "surfaceElevated": "#FFFAEB",
            "surfaceHover": "#FFF4D6",
            "textPrimary": "#2C2416",
            "textSecondary": "#6B5D42",
            "textTertiary": "#9A8866",
            "textDisabled": "#C4B894",
            "border": "#F0E4C3",
            "divider": "#F5EDDB",
            "overlay": "#00000030",
            "inputBackground": "#FFFEF7",
            "inputBorder": "#F0E4C3",
            "inputPlaceholder": "#9A8866",
            "sidebarBackground": "#FFFDF4",
            "statusBarBackground": "#FFF9E8",
            "statusBarContent": "#2C2416",
            "navigationBarBackground": "#FFF9E8",
            "navigationBarContent": "#2C2416",
            "bottomNavBackground": "#FFFEF7",
            "bottomNavIconDefault": "#9A8866",
            "bottomNavIconActive": "#FFB74D",
            "bottomNavTextDefault": "#9A8866",
            "bottomNavTextActive": "#F57C00",
            "pageBackground": "#FFF9E8",
            "cardHover": "#FFF4D6",
            "cardPressed": "#FFEDD1",
            "cardActive": "#FFE4A8",
            "accentPrimary": "#FFB74D",
            "accentSecondary": "#F57C00",
            "accentGold": "#FFD700",
            "serverSelected": "#E6A93D",
            "serverSelectedBorder": "#DAA520",
            "serverSelectedAccent": "#C89216",
            "serverBackground": "#FFFEF7",
            "serverHover": "#FFF4D6",
            "protocolBadge": "#F57C00",
            "titleBarBackground": "#FFE8A3",
            "titleBarText": "#2C2416",
            "navButtonBackground": "#FFE8A3",
            "navButtonText": "#2C2416"
        },
        "dark": {
            "background": "#1A1610",
            "surface": "#262218",
            "surfaceElevated": "#322D22",
            "surfaceHover": "#3D372C",
            "textPrimary": "#FFF9E8",
            "textSecondary": "#E0D5BD",
            "textTertiary": "#B5A88A",
            "textDisabled": "#7A6F5A",
            "border": "#3D372C",
            "divider": "#4A4238",
            "overlay": "#00000080",
            "inputBackground": "#262218",
            "inputBorder": "#3D372C",
            "inputPlaceholder": "#B5A88A",
            "sidebarBackground": "#262218",
            "statusBarBackground": "#1A1610",
            "statusBarContent": "#FFF9E8",
            "navigationBarBackground": "#1A1610",
            "navigationBarContent": "#FFF9E8",
            "bottomNavBackground": "#262218",
            "bottomNavIconDefault": "#B5A88A",
            "bottomNavIconActive": "#FFB74D",
            "bottomNavTextDefault": "#B5A88A",
            "bottomNavTextActive": "#FFA726",
            "pageBackground": "#1A1610",
            "cardHover": "#3D372C",
            "cardPressed": "#4A4238",
            "cardActive": "#554D3E",
            "accentPrimary": "#FFB74D",
            "accentSecondary": "#FFA726",
            "accentGold": "#FFD700",
            "serverSelected": "#E6A93D",
            "serverSelectedBorder": "#DAA520",
            "serverSelectedAccent": "#C89216",
            "serverBackground": "#262218",
            "serverHover": "#3D372C",
            "protocolBadge": "#FFA726",
            "titleBarBackground": "#C89216",
            "titleBarText": "#FFF9E8",
            "navButtonBackground": "#FFE8A3",
            "navButtonText": "#FFF9E8"
        }
    })

    property var starDustTheme: ({
        "name": "StarDust",
        "displayName": "StarDust",
        "light": {
            "background": "#F7F8FA",
            "surface": "#FFFFFF",
            "surfaceElevated": "#FAFBFC",
            "surfaceHover": "#F1F3F5",
            "textPrimary": "#212529",
            "textSecondary": "#6C757D",
            "textTertiary": "#ADB5BD",
            "textDisabled": "#CED4DA",
            "border": "#DEE2E6",
            "divider": "#E9ECEF",
            "overlay": "#00000018",
            "inputBackground": "#FFFFFF",
            "inputBorder": "#DEE2E6",
            "inputPlaceholder": "#ADB5BD",
            "sidebarBackground": "#FAFBFC",
            "statusBarBackground": "#F7F8FA",
            "statusBarContent": "#212529",
            "navigationBarBackground": "#F7F8FA",
            "navigationBarContent": "#212529",
            "bottomNavBackground": "#FFFFFF",
            "bottomNavIconDefault": "#ADB5BD",
            "bottomNavIconActive": "#007BFF",
            "bottomNavTextDefault": "#6C757D",
            "bottomNavTextActive": "#007BFF",
            "pageBackground": "#F7F8FA",
            "cardHover": "#E9ECEF",
            "cardPressed": "#DEE2E6",
            "cardActive": "#CED4DA",
            "accentPrimary": "#007BFF",
            "accentSecondary": "#0056B3",
            "accentGold": "#FFC107",
            "serverSelected": "#007BFF",
            "serverSelectedBorder": "#0056B3",
            "serverSelectedAccent": "#004085",
            "serverBackground": "#FFFFFF",
            "serverHover": "#E9ECEF",
            "protocolBadge": "#6C757D",
            "titleBarBackground": "#CED4D8",
            "titleBarText": "#212529",
            "navButtonBackground": "#CED4D8",
            "navButtonText": "#212529"
        },
        "dark": {
            "background": "#0A0E14",
            "surface": "#1A1D23",
            "surfaceElevated": "#252A31",
            "surfaceHover": "#2F343C",
            "textPrimary": "#FFFFFF",
            "textSecondary": "#C8CFD8",
            "textTertiary": "#8B95A5",
            "textDisabled": "#5C6570",
            "border": "#2D333E",
            "divider": "#3D4451",
            "overlay": "#00000080",
            "inputBackground": "#1A1D23",
            "inputBorder": "#2D333E",
            "inputPlaceholder": "#8B95A5",
            "sidebarBackground": "#1A1D23",
            "statusBarBackground": "#0A0E14",
            "statusBarContent": "#FFFFFF",
            "navigationBarBackground": "#0A0E14",
            "navigationBarContent": "#FFFFFF",
            "bottomNavBackground": "#1A1D23",
            "bottomNavIconDefault": "#8B95A5",
            "bottomNavIconActive": "#5C9FFF",
            "bottomNavTextDefault": "#8B95A5",
            "bottomNavTextActive": "#5C9FFF",
            "pageBackground": "#0A0E14",
            "cardHover": "#2F343C",
            "cardPressed": "#3D4451",
            "cardActive": "#4A5362",
            "accentPrimary": "#5C9FFF",
            "accentSecondary": "#4A8FEF",
            "accentGold": "#FFD54F",
            "serverSelected": "#5C9FFF",
            "serverSelectedBorder": "#4A8FEF",
            "serverSelectedAccent": "#3A7FDF",
            "serverBackground": "#1A1D23",
            "serverHover": "#2F343C",
            "protocolBadge": "#8B95A5",
            "titleBarBackground": "#CED4D8",
            "titleBarText": "#FFFFFF",
            "navButtonBackground": "#CED4D8",
            "navButtonText": "#212529"
        }
    })

    readonly property var themes: ({
        "JinGO": jingoTheme,
        "StarDust": starDustTheme
    })

    property var currentTheme: jingoTheme

    readonly property int breakpointMobile: 768
    readonly property int breakpointTablet: 1024

    // 使用 property binding 而不是直接访问 topLevelWindow
    // 这样可以避免在 Theme 单例初始化时 Window 还未创建的问题
    // 默认使用浅色模式,Window 创建后会更新这个值
    property bool isDarkMode: false

    // 【重要】直接初始化为浅色主题,避免绑定表达式在初始化时出现问题
    // 这确保了 themeColors 一定有值,防止整个 Theme 对象初始化失败
    property var themeColors: jingoTheme.light

    // 当isDarkMode或currentTheme改变时更新themeColors
    Component.onCompleted: {
        // 初始化完成后建立绑定
        themeColors = Qt.binding(function() {
            return isDarkMode ? currentTheme.dark : currentTheme.light
        })
    }

    onCurrentThemeChanged: {
        themeColors = isDarkMode ? currentTheme.dark : currentTheme.light
    }

    onIsDarkModeChanged: {
        themeColors = isDarkMode ? currentTheme.dark : currentTheme.light
    }

    // 主色调
    readonly property QtObject colors: QtObject {
        // 品牌色
        readonly property color primary: "#007BFF"
        readonly property color secondary: "#6C757D"

        // 状态色
        readonly property color success: "#4CAF50"
        readonly property color warning: "#FF9800"
        readonly property color error: "#F44336"
        readonly property color info: "#2196F3"

        // 背景色 - 使用主题配置
        readonly property color background: themeColors.background
        readonly property color surface: themeColors.surface
        readonly property color surfaceElevated: themeColors.surfaceElevated
        readonly property color surfaceHover: themeColors.surfaceHover

        // 文本色
        readonly property color textPrimary: themeColors.textPrimary
        readonly property color textSecondary: themeColors.textSecondary
        readonly property color textTertiary: themeColors.textTertiary
        readonly property color textDisabled: themeColors.textDisabled

        // 边框色
        readonly property color border: themeColors.border
        readonly property color borderFocus: primary
        readonly property color divider: themeColors.divider

        // 覆盖层
        readonly property color overlay: themeColors.overlay
        readonly property color scrim: "#000000B3"

        // 输入框 - 使用主题配置
        readonly property color inputBackground: themeColors.inputBackground
        readonly property color inputBorder: themeColors.inputBorder
        readonly property color inputBorderFocus: primary
        readonly property color inputPlaceholder: themeColors.inputPlaceholder

        // 卡片 - 使用主题配置
        readonly property color cardBackground: surface
        readonly property color cardBorder: border

        // 侧边栏
        readonly property color sidebarBackground: themeColors.sidebarBackground
        readonly property color sidebarSelected: primary
        readonly property color sidebarHover: surfaceHover

        // 系统栏
        readonly property color statusBarBackground: themeColors.statusBarBackground
        readonly property color statusBarContent: themeColors.statusBarContent
        readonly property color navigationBarBackground: themeColors.navigationBarBackground
        readonly property color navigationBarContent: themeColors.navigationBarContent

        // 底部导航
        readonly property color bottomNavBackground: themeColors.bottomNavBackground
        readonly property color bottomNavIconDefault: themeColors.bottomNavIconDefault
        readonly property color bottomNavIconActive: themeColors.bottomNavIconActive
        readonly property color bottomNavTextDefault: themeColors.bottomNavTextDefault
        readonly property color bottomNavTextActive: themeColors.bottomNavTextActive

        // 主页面
        readonly property color pageBackground: themeColors.pageBackground

        // 卡片状态
        readonly property color cardHover: themeColors.cardHover
        readonly property color cardPressed: themeColors.cardPressed
        readonly property color cardActive: themeColors.cardActive

        // 强调色
        readonly property color accentPrimary: themeColors.accentPrimary
        readonly property color accentSecondary: themeColors.accentSecondary
        readonly property color accentGold: themeColors.accentGold

        // 服务器列表专用颜色
        readonly property color serverSelected: themeColors.serverSelected
        readonly property color serverSelectedBorder: themeColors.serverSelectedBorder
        readonly property color serverSelectedAccent: themeColors.serverSelectedAccent
        readonly property color serverBackground: themeColors.serverBackground
        readonly property color serverHover: themeColors.serverHover
        readonly property color protocolBadge: themeColors.protocolBadge

        // 标题栏
        readonly property color titleBarBackground: themeColors.titleBarBackground
        readonly property color titleBarText: themeColors.titleBarText

        // 导航按钮
        readonly property color navButtonBackground: themeColors.navButtonBackground
        readonly property color navButtonText: themeColors.navButtonText
    }

    // ========== 间距系统 (8pt 网格) ==========
    readonly property QtObject spacing: QtObject {
        readonly property int xxs: 4
        readonly property int xs: 8
        readonly property int sm: 12
        readonly property int md: 16
        readonly property int lg: 24
        readonly property int xl: 32
        readonly property int xxl: 40
        readonly property int xxxl: 48
    }

    // ========== 字体系统 ==========
    readonly property QtObject typography: QtObject {
        // 字体大小
        readonly property int h1: 28
        readonly property int h2: 24
        readonly property int h3: 20
        readonly property int h4: 18
        readonly property int h5: 16
        readonly property int h6: 14
        readonly property int body1: 16
        readonly property int body2: 14
        readonly property int caption: 13
        readonly property int small: 12
        readonly property int tiny: 11

        // 字体家族（针对不同平台优化）
        readonly property string fontFamily: {
            if (Qt.platform.os === "android") {
                // Android上优先使用加载的思源黑体
                if (_sourceHanSansSC.status === FontLoader.Ready && _sourceHanSansSC.name !== "") {
                    return _sourceHanSansSC.name
                } else if (_notoSansCJKSC.status === FontLoader.Ready && _notoSansCJKSC.name !== "") {
                    return _notoSansCJKSC.name
                } else {
                    return "Roboto, sans-serif"
                }
            } else if (Qt.platform.os === "ios") {
                return "PingFang SC, SF Pro, sans-serif"
            } else if (Qt.platform.os === "osx") {
                return "PingFang SC, SF Pro Text, Helvetica Neue, sans-serif"
            } else {
                return "system-ui, -apple-system, sans-serif"
            }
        }

        // 字重 - 移动端使用更细的字重
        readonly property int weightLight: Font.Light
        readonly property int weightRegular: Font.Normal
        readonly property int weightMedium: Font.Medium
        readonly property int weightBold: Font.Bold

        // 移动端专用字重（更细）
        readonly property int mobileWeightNormal: Font.Light
        readonly property int mobileWeightMedium: Font.Normal
        readonly property int mobileWeightBold: Font.Medium

        // 行高
        readonly property real lineHeightTight: 1.2
        readonly property real lineHeightNormal: 1.5
        readonly property real lineHeightRelaxed: 1.7
    }

    // ========== 圆角系统 ==========
    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 20
        readonly property int xxl: 24
        readonly property int full: 9999  // 完全圆形
    }

    // ========== 阴影系统 ==========
    readonly property QtObject shadow: QtObject {
        // 阴影配置 (color, offsetX, offsetY, blur, spread)
        readonly property var sm: {
            "color": isDarkMode ? "#00000040" : "#00000015",
            "offsetY": 1,
            "blur": 2
        }
        readonly property var md: {
            "color": isDarkMode ? "#00000060" : "#00000025",
            "offsetY": 2,
            "blur": 4
        }
        readonly property var lg: {
            "color": isDarkMode ? "#00000080" : "#00000035",
            "offsetY": 4,
            "blur": 8
        }
        readonly property var xl: {
            "color": isDarkMode ? "#000000A0" : "#00000045",
            "offsetY": 8,
            "blur": 16
        }
    }

    // ========== 动画时长 ==========
    readonly property QtObject duration: QtObject {
        readonly property int instant: 0
        readonly property int fast: 100
        readonly property int normal: 150
        readonly property int slow: 250
        readonly property int slower: 350
        readonly property int slowest: 500
    }

    // ========== 动画缓动 ==========
    readonly property QtObject easing: QtObject {
        readonly property int standard: Easing.OutQuad
        readonly property int emphasized: Easing.OutCubic
        readonly property int decelerated: Easing.OutQuart
        readonly property int accelerated: Easing.InQuad
    }

    // ========== Z-index 层级 ==========
    readonly property QtObject zIndex: QtObject {
        readonly property int base: 0
        readonly property int dropdown: 100
        readonly property int sticky: 200
        readonly property int fixed: 300
        readonly property int modalBackdrop: 400
        readonly property int modal: 500
        readonly property int popover: 600
        readonly property int tooltip: 700
    }

    // ========== 组件尺寸 ==========
    readonly property QtObject size: QtObject {
        // 按钮高度
        readonly property QtObject button: QtObject {
            readonly property int sm: 36
            readonly property int md: 44
            readonly property int lg: 56
        }

        // 输入框高度
        readonly property QtObject input: QtObject {
            readonly property int sm: 36
            readonly property int md: 44
            readonly property int lg: 52
        }

        // 图标尺寸
        readonly property QtObject icon: QtObject {
            readonly property int xs: 16
            readonly property int sm: 20
            readonly property int md: 24
            readonly property int lg: 32
            readonly property int xl: 40
        }

        // 最小触摸目标 (遵循 WCAG 无障碍标准)
        readonly property int touchTarget: 44
    }

    // ========== 响应式辅助函数 ==========
    function isMobile(width) {
        return width < breakpointMobile
    }

    function isTablet(width) {
        return width >= breakpointMobile && width < breakpointTablet
    }

    function isDesktop(width) {
        return width >= breakpointTablet
    }

    // 响应式值选择器
    function responsive(windowWidth, mobileValue, tabletValue, desktopValue) {
        if (isMobile(windowWidth)) return mobileValue
        if (isTablet(windowWidth)) return tabletValue !== undefined ? tabletValue : desktopValue
        return desktopValue
    }

    // ========== 颜色工具函数 ==========
    function alpha(color, opacity) {
        var c = Qt.color(color)
        c.a = opacity
        return c
    }

    function lighten(color, factor) {
        return Qt.lighter(color, factor)
    }

    function darken(color, factor) {
        return Qt.darker(color, factor)
    }

    // ========== 调试模式 ==========
    readonly property bool debug: false

    function log(message) {
        if (debug) {
        }
    }
}
