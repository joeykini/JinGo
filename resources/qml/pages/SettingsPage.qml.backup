// pages/SettingsPage.qml (完整版 - 基于 xray-core 配置)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15
import JinGo 1.0

Rectangle {
    id: settingsPage

    readonly property var mainWindow: Window.window
    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false
    readonly property bool isAuthenticated: mainWindow ? mainWindow.isAuthenticated : false
    readonly property bool isDesktop: mainWindow ? mainWindow.isDesktop : true
    readonly property bool isMobilePlatform: Qt.platform.os === "android" || Qt.platform.os === "ios"


    color: Theme.colors.pageBackground

    // 页面激活时重新加载设置 - 已禁用（导致卡死）
    // StackView.onActivated: {
    //     reloadAllSettings()
    // }

    // 根据国家代码获取国内DNS服务器（用于直连域名）
    function getDomesticDNSByCountry(countryCode) {
        // 返回格式: [DNS1, DNS2]
        switch(countryCode) {
            case "cn":  // 中国
                return ["223.5.5.5", "119.29.29.29"]  // 阿里云DNS, 腾讯DNS
            case "ir":  // 伊朗
                return ["178.22.122.100", "185.51.200.2"]  // Shecan DNS
            case "ru":  // 俄罗斯
                return ["77.88.8.8", "77.88.8.1"]  // Yandex DNS
            case "vn":  // 越南
                return ["203.113.131.1", "203.113.131.2"]  // VNPT DNS
            case "kh":  // 柬埔寨
                return ["203.189.136.148", "203.189.142.131"]  // Cambodia DNS
            case "mm":  // 缅甸
                return ["203.81.64.18", "203.81.64.19"]  // Myanmar DNS
            default:
                return ["223.5.5.5", "119.29.29.29"]  // 默认使用中国DNS
        }
    }

    // 获取国内DNS 1
    function getDomesticDNS1() {
        if (!configManager) return "223.5.5.5"
        var countryCode = configManager.userCountryCode || "cn"
        var dns = getDomesticDNSByCountry(countryCode)
        return dns[0]
    }

    // 获取国内DNS 2
    function getDomesticDNS2() {
        if (!configManager) return "119.29.29.29"
        var countryCode = configManager.userCountryCode || "cn"
        var dns = getDomesticDNSByCountry(countryCode)
        return dns[1]
    }

    // 更新DNS服务器列表
    function updateDNSServers() {
        if (!configManager) return
        var newServers = []
        if (dns1Field && dns1Field.text) newServers.push(dns1Field.text)
        if (dns2Field && dns2Field.text) newServers.push(dns2Field.text)
        if (dns3Field && dns3Field.text) newServers.push(dns3Field.text)
        if (dns4Field && dns4Field.text) newServers.push(dns4Field.text)

        if (newServers.length > 0) {
            configManager.dnsServers = newServers
        }
    }

    // 当国家代码改变时，更新国内DNS服务器（只读字段）
    function onCountryCodeChanged(countryCode) {
        var domesticDNS = getDomesticDNSByCountry(countryCode)

        // 更新国内DNS显示 (servers[0], servers[1]) - 只读字段
        if (dns1Field) {
            dns1Field.text = domesticDNS[0]
        }
        if (dns2Field) {
            dns2Field.text = domesticDNS[1]
        }

        updateDNSServers()
    }

    // 从 ConfigManager 重新加载所有设置
    function reloadAllSettings() {

        // ConfigManager的属性会自动通过property binding同步到UI
        // 只需要重新加载TextField和特殊控件
        if (configManager) {
            // 重新加载DNS服务器
            var servers = configManager.dnsServers
            // DNS 1/2 (国内) - 只读，总是使用国家对应的DNS
            if (dns1Field) {
                dns1Field.text = getDomesticDNS1()
            }
            if (dns2Field) {
                dns2Field.text = getDomesticDNS2()
            }
            // DNS 3/4 (海外) - 可编辑，从配置读取或使用默认值
            if (dns3Field) {
                dns3Field.text = servers.length > 2 ? servers[2] : "8.8.8.8"
            }
            if (dns4Field) {
                dns4Field.text = servers.length > 3 ? servers[3] : "1.1.1.1"
            }

            // 重新加载语言ComboBox（需要手动设置currentIndex）
            if (languageComboBox && configManager) {
                var languageCodes = ["zh_CN", "en_US", "fa_IR", "ru_RU"]
                var lang = configManager.language
                var langIdx = languageCodes.indexOf(lang)
                languageComboBox.currentIndex = langIdx >= 0 ? langIdx : 1  // 默认English
            }

            // 主题状态通过 property binding 自动同步，无需手动触发
        }

    }

    // 设置内容（简化为一层）
    ScrollView {
        anchors.fill: parent
        anchors.leftMargin: isDesktop ? 20 : 16
        anchors.rightMargin: isDesktop ? 20 : 16
        anchors.topMargin: isDesktop ? 20 : 10
        anchors.bottomMargin: isDesktop ? 20 : 10
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: Theme.spacing.lg

                // ========== 通用设置 ==========
                SettingsGroup {
                    title: qsTr("GeneralSettings")
                    description: qsTr("Application Basic Configuration")

                    SettingItem {
                        visible: !isMobilePlatform  // 仅桌面端可见（非iOS/Android）
                        label: qsTr("Start at Login")
                        description: qsTr("Launch at system startup")
                        control: CustomSwitch {
                            id: runOnStartupSwitch
                            checked: configManager ? configManager.autoStart : false
                            onClicked: {
                                if (configManager) configManager.autoStart = checked
                            }
                        }
                    }

                    SettingItem {
                        // iOS显示"按需连接"，其他平台显示"自动连接"
                        label: Qt.platform.os === "ios" ? qsTr("Connect on Demand") : qsTr("Auto-connect on startup")
                        description: Qt.platform.os === "ios" ?
                            qsTr("Automatically connect VPN when network changes") :
                            qsTr("Automatically connect to last used server on startup")
                        control: CustomSwitch {
                            id: autoConnectSwitch
                            checked: configManager ? configManager.autoConnect : false
                            onClicked: {
                                if (configManager) configManager.autoConnect = checked
                            }
                        }
                    }

                    SettingItem {
                        visible: !isMobilePlatform  // 仅桌面端可见（非iOS/Android）
                        label: qsTr("Minimize to System Tray")
                        description: qsTr("Minimize to system tray instead of quit when closing window")
                        control: CustomSwitch {
                            id: minimizeToTraySwitch
                            checked: configManager ? configManager.minimizeToTray : false
                            onClicked: {
                                if (configManager) configManager.minimizeToTray = checked
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Language")
                        description: qsTr("Select app display language")
                        control: ComboBox {
                            id: languageComboBox
                            model: ["简体中文", "English", "فارسی", "Русский"]
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            // 语言切换 - 只在用户交互时触发
                            onActivated: function(index) {
                                var languageCodes = ["zh_CN", "en_US", "fa_IR", "ru_RU"]
                                if (index >= 0 && index < languageCodes.length) {
                                    // 切换语言显示
                                    if (typeof languageManager !== 'undefined') {
                                        languageManager.switchLanguage(languageCodes[index])
                                    } else {
                                    }
                                    // 保存语言设置
                                    if (configManager) {
                                        configManager.language = languageCodes[index]
                                    }
                                }
                            }

                            // 初始化时设置当前索引
                            Component.onCompleted: {
                                var languageCodes = ["zh_CN", "en_US", "fa_IR", "ru_RU"]
                                var lang = typeof languageManager !== 'undefined' ? languageManager.currentLanguage : "en_US"
                                var idx = languageCodes.indexOf(lang)
                                currentIndex = idx >= 0 ? idx : 1  // 默认English
                            }

                            // 响应语言变化
                            Connections {
                                target: typeof languageManager !== 'undefined' ? languageManager : null
                                enabled: typeof languageManager !== 'undefined'
                                function onCurrentLanguageChanged() {
                                    var languageCodes = ["zh_CN", "en_US", "fa_IR", "ru_RU"]
                                    var lang = languageManager.currentLanguage
                                    var idx = languageCodes.indexOf(lang)
                                    languageComboBox.currentIndex = idx >= 0 ? idx : 1
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Theme")
                        description: qsTr("Select app theme style")
                        control: Row {
                            spacing: 15

                            Rectangle {
                                id: jingoThemeButton
                                width: 80
                                height: 32
                                radius: 4
                                color: Theme.currentTheme.name === "JinGO" ? "#E6A93D" : "transparent"
                                border.color: "#E6A93D"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "JinGO"
                                    color: Theme.currentTheme.name === "JinGO" ? "#2C2416" : "#E6A93D"
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                MouseArea {
                                    id: jingoThemeButtonMouseArea
                                    anchors.fill: parent
                                    onClicked: {
                                        if (configManager) {
                                            configManager.theme = "JinGO"
                                        }
                                    }
                                }

                                Binding {
                                    target: jingoThemeButton
                                    property: "color"
                                    value: Theme.currentTheme.name === "JinGO" ? "#E6A93D" : "transparent"
                                    when: configManager !== null
                                }
                            }

                            Rectangle {
                                id: stardustThemeButton
                                width: 90
                                height: 32
                                radius: 4
                                color: Theme.currentTheme.name === "StarDust" ? "#6C757D" : "transparent"
                                border.color: "#6C757D"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "StarDust"
                                    color: Theme.currentTheme.name === "StarDust" ? "#FFFFFF" : "#6C757D"
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                MouseArea {
                                    id: stardustThemeButtonMouseArea
                                    anchors.fill: parent
                                    onClicked: {
                                        if (configManager) {
                                            configManager.theme = "StarDust"
                                        }
                                    }
                                }

                                Binding {
                                    target: stardustThemeButton
                                    property: "color"
                                    value: Theme.currentTheme.name === "StarDust" ? "#6C757D" : "transparent"
                                    when: configManager !== null
                                }
                            }
                        }
                    }
                }

                // ========== 订阅设置 ==========
                SettingsGroup {
                    visible: !bundleConfig || !bundleConfig.hideSubscriptionBlock
                    title: qsTr("Subscription Settings")
                    description: qsTr("Server subscription update settings")

                    SettingItem {
                        label: qsTr("Auto Update Interval")
                        description: qsTr("How often to automatically update server list")

                        control: ComboBox {
                            id: subscriptionIntervalCombo
                            Layout.preferredWidth: 120
                            model: [
                                qsTr("1 Hour"),
                                qsTr("3 Hours"),
                                qsTr("6 Hours"),
                                qsTr("12 Hours"),
                                qsTr("24 Hours")
                            ]

                            // 将小时值映射到索引
                            readonly property var hourValues: [1, 3, 6, 12, 24]

                            Component.onCompleted: {
                                if (configManager) {
                                    var hours = configManager.subscriptionUpdateInterval
                                    var idx = hourValues.indexOf(hours)
                                    currentIndex = idx >= 0 ? idx : 1  // 默认3小时
                                }
                            }

                            Connections {
                                target: configManager
                                function onSubscriptionUpdateIntervalChanged() {
                                    var hours = configManager.subscriptionUpdateInterval
                                    var idx = subscriptionIntervalCombo.hourValues.indexOf(hours)
                                    subscriptionIntervalCombo.currentIndex = idx >= 0 ? idx : 1
                                }
                            }

                            onActivated: {
                                if (configManager) {
                                    configManager.subscriptionUpdateInterval = hourValues[currentIndex]
                                    configManager.save()
                                }
                            }

                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }
                        }
                    }
                }

                // ========== 路由设置 ==========
                SettingsGroup {
                    title: qsTr("Routing Settings")
                    description: qsTr("Control how traffic is routed and split")
                    collapsible: true

                    SettingItem {
                        label: qsTr("Domain Resolution Strategy")
                        description: qsTr("Control how domains are resolved")
                        control: ComboBox {
                            id: domainStrategyCombo
                            model: [
                                "AsIs",
                                "IPIfNonMatch",
                                "IPOnDemand"
                            ]
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                if (configManager) {
                                    var strategy = configManager.domainStrategy || "AsIs"
                                    var idx = model.indexOf(strategy)
                                    currentIndex = idx >= 0 ? idx : 0
                                }
                            }

                            Connections {
                                target: configManager
                                function onDomainStrategyChanged() {
                                    var strategy = configManager.domainStrategy || "AsIs"
                                    var idx = domainStrategyCombo.model.indexOf(strategy)
                                    domainStrategyCombo.currentIndex = idx >= 0 ? idx : 0
                                }
                            }

                            // 只在用户交互时触发
                            onActivated: function(index) {
                                if (configManager && index >= 0 && index < model.length) {
                                    configManager.domainStrategy = model[index]
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Bypass Countries")
                        description: qsTr("Select countries to bypass, their websites will connect directly")
                        control: ComboBox {
                            id: bypassCountryCombo
                            model: [
                                qsTr("China"),
                                qsTr("Russia"),
                                qsTr("Iran"),
                                qsTr("Vietnam"),
                                qsTr("Cambodia"),
                                qsTr("Myanmar")
                            ]
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            function countryCodeToIndex(code) {
                                if (code === "cn") return 0
                                if (code === "ru") return 1
                                if (code === "ir") return 2
                                if (code === "vn") return 3
                                if (code === "kh") return 4
                                if (code === "mm") return 5
                                return 0
                            }

                            Component.onCompleted: {
                                if (configManager) {
                                    var countryCode = configManager.userCountryCode || "cn"
                                    currentIndex = countryCodeToIndex(countryCode)
                                }
                            }

                            Connections {
                                target: configManager
                                function onUserCountryCodeChanged() {
                                    var countryCode = configManager.userCountryCode || "cn"
                                    bypassCountryCombo.currentIndex = bypassCountryCombo.countryCodeToIndex(countryCode)
                                }
                            }

                            // 只在用户交互时触发
                            onActivated: function(index) {
                                // 根据选中的国家更新DNS服务器
                                var countryCode = ""
                                if (index === 0) countryCode = "cn"       // 中国
                                else if (index === 1) countryCode = "ru"  // 俄罗斯
                                else if (index === 2) countryCode = "ir"  // 伊朗
                                else if (index === 3) countryCode = "vn"  // 越南
                                else if (index === 4) countryCode = "kh"  // 柬埔寨
                                else if (index === 5) countryCode = "mm"  // 缅甸

                                // 保存国家代码到ConfigManager
                                if (configManager && countryCode) {
                                    configManager.userCountryCode = countryCode
                                }

                                // 更新国内DNS服务器
                                onCountryCodeChanged(countryCode)
                            }
                        }
                    }

                    SettingItem {
                        visible: !isMobilePlatform  // 仅桌面端可见（非iOS/Android）
                        label: qsTr("Network Interface")
                        description: qsTr("Select the network interface for VPN outbound traffic")
                        control: RowLayout {
                            spacing: 8

                            ComboBox {
                                id: networkInterfaceCombo
                                model: settingsViewModel ? settingsViewModel.availableNetworkInterfaces : []
                                implicitWidth: 180
                                implicitHeight: 32
                                enabled: settingsViewModel ? settingsViewModel.networkInterfaceSelectionEnabled : false

                                function updateCurrentIndex() {
                                    if (!settingsViewModel) {
                                        currentIndex = 0
                                        return
                                    }
                                    var interfaces = settingsViewModel.availableNetworkInterfaces
                                    var selected = settingsViewModel.selectedNetworkInterface
                                    var idx = interfaces.indexOf(selected)
                                    currentIndex = idx >= 0 ? idx : 0
                                }

                                Component.onCompleted: {
                                    updateCurrentIndex()
                                }

                                // 响应接口列表变化
                                Connections {
                                    target: settingsViewModel
                                    function onAvailableNetworkInterfacesChanged() {
                                        networkInterfaceCombo.updateCurrentIndex()
                                    }
                                    function onSelectedNetworkInterfaceChanged() {
                                        networkInterfaceCombo.updateCurrentIndex()
                                    }
                                }

                                onActivated: function(index) {
                                    if (settingsViewModel && index >= 0) {
                                        var interfaces = settingsViewModel.availableNetworkInterfaces
                                        if (index < interfaces.length) {
                                            settingsViewModel.selectedNetworkInterface = interfaces[index]
                                        }
                                    }
                                }
                            }

                            // 刷新按钮
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 4
                                color: refreshMouseArea.containsMouse ? Theme.colors.surfaceHover : "transparent"
                                border.color: Theme.colors.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "↻"
                                    font.pixelSize: 16
                                    color: Theme.colors.textPrimary
                                }

                                MouseArea {
                                    id: refreshMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (settingsViewModel) {
                                            settingsViewModel.refreshNetworkInterfaces()
                                        }
                                    }
                                }
                            }
                        }
                    }

                }

                // ========== 分应用代理设置 (仅Android) ==========
                SettingsGroup {
                    visible: Qt.platform.os === "android"
                    title: qsTr("Per-App Proxy")
                    description: qsTr("Control which apps use VPN") + " (" + qsTr("TUN mode only") + ")"
                    collapsible: true

                    SettingItem {
                        label: qsTr("Per-App Proxy Mode")
                        description: {
                            if (!configManager) return ""
                            switch(configManager.perAppProxyMode) {
                                case 0: return qsTr("Disabled: All apps use VPN")
                                case 1: return qsTr("Allow List: Only selected apps use VPN")
                                case 2: return qsTr("Block List: Selected apps bypass VPN")
                                default: return ""
                            }
                        }

                        control: ComboBox {
                            id: perAppModeCombo
                            model: [
                                qsTr("Disabled"),
                                qsTr("Allow List"),
                                qsTr("Block List")
                            ]
                            implicitWidth: 120
                            implicitHeight: 36

                            Component.onCompleted: {
                                currentIndex = configManager ? configManager.perAppProxyMode : 0
                            }

                            Connections {
                                target: configManager
                                function onPerAppProxyModeChanged() {
                                    perAppModeCombo.currentIndex = configManager.perAppProxyMode
                                }
                            }

                            onActivated: function(index) {
                                if (configManager && index >= 0 && index <= 2) {
                                    configManager.perAppProxyMode = index
                                    configManager.save()
                                }
                            }
                        }
                    }

                    SettingItem {
                        visible: configManager ? configManager.perAppProxyMode !== 0 : false
                        label: qsTr("Selected Apps")
                        description: {
                            if (!configManager) return ""
                            var count = configManager.perAppProxyList.length
                            return qsTr("%1 app(s) selected").arg(count)
                        }
                        control: CustomButton {
                            text: qsTr("Select Apps")
                            variant: "primary"
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: 36
                            onClicked: {
                                // 打开应用选择页面
                                if (mainWindow && mainWindow.stackView) {
                                    mainWindow.stackView.push("AppSelectorPage.qml")
                                }
                            }
                        }
                    }

                    SettingItem {
                        visible: configManager ? configManager.perAppProxyMode !== 0 : false
                        label: qsTr("Clear Selection")
                        description: qsTr("Remove all apps from the list")
                        control: CustomButton {
                            text: qsTr("Clear")
                            variant: "warning"
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: 36
                            onClicked: {
                                if (configManager) {
                                    configManager.perAppProxyList = []
                                    configManager.save()
                                }
                            }
                        }
                    }
                }

                // ========== DNS 设置 ==========
                SettingsGroup {
                    title: qsTr("DNS Settings")
                    description: qsTr("DNS server configuration")
                    collapsible: true

                    SettingItem {
                        label: qsTr("Domestic DNS 1")
                        control: TextField {
                            id: dns1Field
                            text: getDomesticDNS1()
                            implicitWidth: 150
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }
                            readOnly: true
                            enabled: false
                            opacity: 0.7
                        }
                    }

                    SettingItem {
                        label: qsTr("Domestic DNS 2")
                        control: TextField {
                            id: dns2Field
                            text: getDomesticDNS2()
                            implicitWidth: 150
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }
                            readOnly: true
                            enabled: false
                            opacity: 0.7
                        }
                    }

                    SettingItem {
                        label: qsTr("Overseas DNS 1")
                        control: TextField {
                            id: dns3Field
                            implicitWidth: 150
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }
                            placeholderText: "8.8.8.8"

                            Component.onCompleted: {
                                if (configManager) {
                                    var servers = configManager.dnsServers
                                    text = servers.length > 2 ? servers[2] : "8.8.8.8"
                                } else {
                                    text = "8.8.8.8"
                                }
                            }

                            onEditingFinished: {
                                if (configManager && text.length > 0) {
                                    updateDNSServers()
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Overseas DNS 2")
                        control: TextField {
                            id: dns4Field
                            implicitWidth: 150
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }
                            placeholderText: "1.1.1.1"

                            Component.onCompleted: {
                                if (configManager) {
                                    var servers = configManager.dnsServers
                                    text = servers.length > 3 ? servers[3] : "1.1.1.1"
                                } else {
                                    text = "1.1.1.1"
                                }
                            }

                            onEditingFinished: {
                                if (configManager && text.length > 0) {
                                    updateDNSServers()
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("DNS Query Strategy")
                        description: qsTr("IPv4/IPv6 Query Strategy")
                        control: ComboBox {
                            id: dnsQueryStrategyCombo
                            model: ["UseIP", "UseIPv4", "UseIPv6"]
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                if (configManager) {
                                    var strategy = configManager.dnsQueryStrategy || "UseIP"
                                    var idx = model.indexOf(strategy)
                                    currentIndex = idx >= 0 ? idx : 0
                                }
                            }

                            Connections {
                                target: configManager
                                function onDnsQueryStrategyChanged() {
                                    var strategy = configManager.dnsQueryStrategy || "UseIP"
                                    var idx = dnsQueryStrategyCombo.model.indexOf(strategy)
                                    dnsQueryStrategyCombo.currentIndex = idx >= 0 ? idx : 0
                                }
                            }

                            // 只在用户交互时触发
                            onActivated: function(index) {
                                if (configManager && index >= 0 && index < model.length) {
                                    configManager.dnsQueryStrategy = model[index]
                                }
                            }
                        }
                    }
                }

                // ========== 入站设置 ==========
                // iOS 上隐藏 Local Proxy 设置（iOS 沙箱限制，其他应用无法访问本地代理端口）
                SettingsGroup {
                    visible: Qt.platform.os !== "ios"
                    title: qsTr("Local Proxy")
                    description: qsTr("Local SOCKS/HTTP proxy server settings")
                    collapsible: true

                    SettingItem {
                        label: qsTr("SOCKS Proxy Port")
                        description: qsTr("Local SOCKS5 proxy listen port - requires reconnecting after modification")
                        control: SpinBox {
                            id: socksPortSpinBox
                            from: 1024
                            to: 65535
                            editable: true
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                value = configManager ? (configManager.localSocksPort || 10808) : 10808
                            }

                            Connections {
                                target: configManager
                                function onLocalSocksPortChanged() {
                                    socksPortSpinBox.value = configManager.localSocksPort || 10808
                                }
                            }

                            onValueModified: {
                                if (configManager && value >= 1024 && value <= 65535) {
                                    configManager.localSocksPort = value
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("HTTP Proxy Port")
                        description: qsTr("Local HTTP proxy listen port - requires reconnecting after modification")
                        control: SpinBox {
                            id: httpPortSpinBox
                            from: 1024
                            to: 65535
                            editable: true
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                value = configManager ? (configManager.localHttpPort || 10809) : 10809
                            }

                            Connections {
                                target: configManager
                                function onLocalHttpPortChanged() {
                                    httpPortSpinBox.value = configManager.localHttpPort || 10809
                                }
                            }

                            onValueModified: {
                                if (configManager && value >= 1024 && value <= 65535) {
                                    configManager.localHttpPort = value
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Allow LAN Connections")
                        description: qsTr("Allow other devices in LAN to connect to this proxy")
                        control: CustomSwitch {
                            id: allowLanSwitch
                            checked: configManager ? configManager.allowLAN : false
                            onClicked: {
                                if (configManager) {
                                    configManager.allowLAN = checked
                                    // 根据allowLAN自动设置listenAddress
                                    configManager.listenAddress = checked ? "0.0.0.0" : "127.0.0.1"
                                }
                            }
                        }
                    }

                }

                // ========== 传输层设置 ==========
                SettingsGroup {
                    title: qsTr("Transport Layer Settings")
                    description: qsTr("Protocol transport related configuration")
                    collapsible: true

                    SettingItem {
                        label: qsTr("Enable Mux multiplexing")
                        description: qsTr("Transfer multiple data streams through single connection, may reduce latency")
                        control: CustomSwitch {
                            id: muxEnabledSwitch
                            checked: configManager ? configManager.enableMux : false
                            onClicked: {
                                if (configManager) configManager.enableMux = checked
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Mux concurrent connections")
                        description: qsTr("Maximum concurrent multiplexed connections")
                        control: SpinBox {
                            id: muxConcurrencySpinBox
                            from: 1
                            to: 16
                            editable: true
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                value = configManager ? configManager.muxConcurrency : 8
                            }

                            Connections {
                                target: configManager
                                function onMuxConcurrencyChanged() {
                                    muxConcurrencySpinBox.value = configManager.muxConcurrency || 8
                                }
                            }

                            onValueModified: {
                                if (configManager && value >= 1 && value <= 16) {
                                    configManager.muxConcurrency = value
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("TCP Fast Open")
                        description: qsTr("Enable TFO to reduce latency (requires system support)")
                        control: CustomSwitch {
                            id: tcpFastOpenSwitch
                            checked: configManager ? configManager.tcpFastOpen : false
                            onClicked: {
                                if (configManager) {
                                    configManager.tcpFastOpen = checked
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Enable traffic sniffing")
                        description: qsTr("Auto identify traffic type for routing")
                        control: CustomSwitch {
                            id: trafficSniffingSwitch
                            checked: configManager ? configManager.trafficSniffing : true
                            onClicked: {
                                if (configManager) {
                                    configManager.trafficSniffing = checked
                                }
                            }
                        }
                    }
                }

                // ========== 日志设置 ==========
                SettingsGroup {
                    title: qsTr("Log Settings")
                    description: qsTr("Application and core log configuration")
                    collapsible: true

                    SettingItem {
                        label: qsTr("Log Level")
                        description: qsTr("Set log verbosity level")
                        control: ComboBox {
                            id: logLevelCombo
                            model: ["none", "error", "warning", "info", "debug"]
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                currentIndex = configManager ? configManager.logLevel : 2
                            }

                            Connections {
                                target: configManager
                                function onLogLevelChanged() {
                                    logLevelCombo.currentIndex = configManager.logLevel
                                }
                            }

                            onActivated: function(index) {
                                if (configManager) configManager.logLevel = index
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Enable access log")
                        description: qsTr("Log all connection requests")
                        control: CustomSwitch {
                            id: enableAccessLogSwitch
                            checked: configManager ? configManager.enableAccessLog : false
                            onClicked: {
                                if (configManager) {
                                    configManager.enableAccessLog = checked
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Log retention days")
                        description: qsTr("Auto clean old logs")
                        control: SpinBox {
                            id: logRetentionSpinBox
                            from: 1
                            to: 90
                            editable: true
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                value = configManager ? configManager.logRetentionDays : 7
                            }

                            Connections {
                                target: configManager
                                function onLogRetentionDaysChanged() {
                                    logRetentionSpinBox.value = configManager.logRetentionDays || 7
                                }
                            }

                            onValueModified: {
                                if (configManager && value >= 1 && value <= 90) {
                                    configManager.logRetentionDays = value
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Log Size")
                        description: logManager ? qsTr("%1 files").arg(logManager.logFileCount) : ""
                        control: Text {
                            text: logManager ? logManager.totalLogSize : "0 B"
                            color: Theme.colors.textPrimary
                            font.pixelSize: 14
                        }
                    }

                    SettingItem {
                        label: qsTr("Export Logs")
                        description: isMobilePlatform ? qsTr("Save to Downloads folder") : qsTr("Export all logs to a file")
                        control: CustomButton {
                            text: qsTr("Export")
                            variant: "secondary"
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 48
                            }
                            onClicked: {
                                if (logManager) {
                                    if (isMobilePlatform) {
                                        // Mobile: Use dedicated method that saves to Downloads
                                        logManager.exportLogsForMobile()
                                    } else {
                                        // Desktop: Save to Downloads folder
                                        var timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
                                        var fileName = "jingo_logs_" + timestamp + ".dat"
                                        var downloadPath = (Qt.resolvedUrl("file://" + Qt.StandardPaths.writableLocation(Qt.StandardPaths.DownloadLocation) + "/" + fileName)).toString().replace("file://", "")
                                        logManager.exportLogsToZip(downloadPath)
                                    }
                                }
                            }
                        }

                        Connections {
                            target: logManager
                            function onExportCompleted(success, message) {
                                if (success && mainWindow) {
                                    mainWindow.showToast(message)
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Clear Logs")
                        description: qsTr("Delete all logs except current")
                        control: CustomButton {
                            text: qsTr("Clear")
                            variant: "warning"
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 48
                            }
                            onClicked: {
                                if (logManager) {
                                    logManager.clearAllLogs()
                                }
                            }
                        }

                        Connections {
                            target: logManager
                            function onClearCompleted(success, message) {
                                if (logManager) logManager.refresh()
                                if (success && mainWindow) {
                                    mainWindow.showToast(message)
                                }
                            }
                        }
                    }

                    SettingItem {
                        visible: !isMobilePlatform  // 仅桌面端显示查看日志
                        label: qsTr("View Logs")
                        description: qsTr("Open log directory")
                        control: CustomButton {
                            text: qsTr("Open")
                            variant: "secondary"
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: 48
                            onClicked: {
                                // Open log directory
                                if (logManager) {
                                    Qt.openUrlExternally("file://" + logManager.appLogPath())
                                }
                            }
                        }
                    }
                }

                // ========== 高级设置 ==========
                SettingsGroup {
                    title: qsTr("AdvancedSettings")
                    description: qsTr("Advanced user options, modify with caution")
                    collapsible: true
                    collapsed: true

                    SettingItem {
                        label: qsTr("ConnectTimeout")
                        description: qsTr("Connection establishment timeout")
                        control: SpinBox {
                            id: connectTimeoutSpinBox
                            from: 5
                            to: 300
                            editable: true
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                value = configManager ? configManager.connectTimeout : 30
                            }

                            Connections {
                                target: configManager
                                function onConnectTimeoutChanged() {
                                    connectTimeoutSpinBox.value = configManager.connectTimeout || 30
                                }
                            }

                            onValueModified: {
                                if (configManager && value >= 5 && value <= 300) {
                                    configManager.connectTimeout = value
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Test Timeout")
                        description: qsTr("Server latency test timeout duration")
                        control: SpinBox {
                            id: testTimeoutSpinBox
                            from: 1
                            to: 60
                            editable: true
                            implicitWidth: 120
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            Component.onCompleted: {
                                value = configManager ? configManager.testTimeout : 10
                            }

                            Connections {
                                target: configManager
                                function onTestTimeoutChanged() {
                                    testTimeoutSpinBox.value = configManager.testTimeout || 10
                                }
                            }

                            onValueModified: {
                                if (configManager && value >= 1 && value <= 60) {
                                    configManager.testTimeout = value
                                }
                            }
                        }
                    }

                    // GeoIP/GeoSite 自定义功能暂时隐藏，使用内置数据文件
                    // SettingItem {
                    //     label: qsTr("Custom GeoIP Database")
                    //     ...
                    // }
                    // SettingItem {
                    //     label: qsTr("Custom GeoSite Database")
                    //     ...
                    // }
                }

                // ========== 账户操作 ==========
                SettingsGroup {
                    title: qsTr("Account Actions")
                    description: qsTr("Account management and data operations")

                    SettingItem {
                        label: qsTr("Reset all settings")
                        description: qsTr("Restore default settings (does not affect account data)")
                        control: CustomButton {
                            text: qsTr("Reset")
                            buttonColor: Theme.colors.error
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 48
                            }
                            onClicked: {
                                if (configManager) {
                                    configManager.reset()
                                    configManager.save()
                                    if (mainWindow) {
                                        mainWindow.showToast(qsTr("Settings reset to default"))
                                    }
                                }
                            }
                        }
                    }
                }

                // ========== 网络测试 ==========
                SettingsGroup {
                    title: qsTr("Network test")
                    description: ""

                    SettingItem {
                        label: qsTr("Latency Test Method")
                        description: {
                            if (!configManager) return ""
                            switch(configManager.latencyTestMethod) {
                                case 0: return qsTr("TCP ping, fast")
                                case 1: return qsTr("HTTP ping, accurate")
                                default: return ""
                            }
                        }

                        control: RowLayout {
                            spacing: 20

                            CustomRadioButton {
                                id: tcpTestRadio
                                text: qsTr("TCP")
                                onClicked: {
                                    if (configManager) {
                                        configManager.latencyTestMethod = 0
                                    }
                                }

                                Component.onCompleted: {
                                    checked = configManager ? (configManager.latencyTestMethod === 0) : true
                                }

                                Connections {
                                    target: configManager
                                    function onLatencyTestMethodChanged() {
                                        tcpTestRadio.checked = (configManager.latencyTestMethod === 0)
                                    }
                                }
                            }

                            CustomRadioButton {
                                id: httpTestRadio
                                text: qsTr("HTTP")
                                onClicked: {
                                    if (configManager) {
                                        configManager.latencyTestMethod = 1
                                    }
                                }

                                Component.onCompleted: {
                                    checked = configManager ? (configManager.latencyTestMethod === 1) : false
                                }

                                Connections {
                                    target: configManager
                                    function onLatencyTestMethodChanged() {
                                        httpTestRadio.checked = (configManager.latencyTestMethod === 1)
                                    }
                                }
                            }
                        }
                    }

                    // 延时测试间隔（仅桌面平台）
                    SettingItem {
                        visible: Qt.platform.os !== "android" && Qt.platform.os !== "ios"
                        label: qsTr("Latency Test Interval")
                        description: {
                            if (!configManager) return ""
                            var interval = configManager.latencyTestInterval
                            if (interval === 0) {
                                return qsTr("Disabled: No periodic latency testing when connected")
                            }
                            return qsTr("Test latency every %1 seconds when connected").arg(interval)
                        }

                        control: SpinBox {
                            id: latencyIntervalSpinBox
                            from: 0
                            to: 300
                            stepSize: 10
                            editable: true
                            implicitWidth: 100
                            implicitHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 32
                            }

                            textFromValue: function(value, locale) {
                                return value === 0 ? qsTr("Disabled") : value + "s"
                            }

                            valueFromText: function(text, locale) {
                                var num = parseInt(text.replace(/[^0-9]/g, ''))
                                return isNaN(num) ? 0 : num
                            }

                            Component.onCompleted: {
                                value = configManager ? configManager.latencyTestInterval : 60
                            }

                            Connections {
                                target: configManager
                                function onLatencyTestIntervalChanged() {
                                    latencyIntervalSpinBox.value = configManager.latencyTestInterval
                                }
                            }

                            onValueModified: {
                                if (configManager) {
                                    configManager.latencyTestInterval = value
                                    configManager.save()
                                }
                            }
                        }
                    }

                    // 测速文件大小设置
                    SettingItem {
                        label: qsTr("Speed Test File Size")
                        description: {
                            if (!configManager) return ""
                            switch(configManager.speedTestFileSize) {
                                case 10: return qsTr("10MB: Quick test")
                                case 25: return qsTr("25MB: Standard test")
                                default: return ""
                            }
                        }

                        control: RowLayout {
                            spacing: 15

                            CustomRadioButton {
                                id: speedTest10MBRadio
                                text: "10MB"
                                onClicked: {
                                    if (configManager) {
                                        configManager.setSpeedTestFileSize(10)
                                        configManager.save()
                                    }
                                }

                                Component.onCompleted: {
                                    checked = configManager ? (configManager.speedTestFileSize === 10) : true
                                }

                                Connections {
                                    target: configManager
                                    function onSpeedTestFileSizeChanged() {
                                        speedTest10MBRadio.checked = (configManager.speedTestFileSize === 10)
                                    }
                                }
                            }

                            CustomRadioButton {
                                id: speedTest25MBRadio
                                text: "25MB"
                                onClicked: {
                                    if (configManager) {
                                        configManager.setSpeedTestFileSize(25)
                                        configManager.save()
                                    }
                                }

                                Component.onCompleted: {
                                    checked = configManager ? (configManager.speedTestFileSize === 25) : false
                                }

                                Connections {
                                    target: configManager
                                    function onSpeedTestFileSizeChanged() {
                                        speedTest25MBRadio.checked = (configManager.speedTestFileSize === 25)
                                    }
                                }
                            }
                        }
                    }
                }

                // ========== 关于 ==========
                SettingsGroup {
                    title: qsTr("About")

                    SettingItem {
                        label: qsTr("Application Version")
                        description: bundleConfig ? bundleConfig.appName + " v" + Qt.application.version : "JinGo VPN v1.0.0"
                        control: CustomButton {
                            text: qsTr("Check")
                            variant: "secondary"
                            visible: bundleConfig && bundleConfig.updateCheckUrl && bundleConfig.updateCheckUrl.length > 0
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 48
                            }
                            onClicked: {
                                // 打开更新检查页面
                                if (bundleConfig && bundleConfig.updateCheckUrl) {
                                    Qt.openUrlExternally(bundleConfig.updateCheckUrl)
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Core Version")
                        description: vpnManager ? vpnManager.coreVersion : "Unknown"
                        control: Item { width: 1; height: 1 }
                    }

                    SettingItem {
                        label: qsTr("Open Source License")
                        control: CustomButton {
                            text: qsTr("View")
                            variant: "secondary"
                            visible: bundleConfig && bundleConfig.licenseUrl && bundleConfig.licenseUrl.length > 0
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 48
                            }
                            onClicked: {
                                // 打开许可证页面
                                if (bundleConfig && bundleConfig.licenseUrl) {
                                    Qt.openUrlExternally(bundleConfig.licenseUrl)
                                }
                            }
                        }
                    }

                    SettingItem {
                        label: qsTr("Documentation")
                        control: CustomButton {
                            text: qsTr("View")
                            variant: "secondary"
                            visible: bundleConfig && bundleConfig.docsUrl && bundleConfig.docsUrl.length > 0
                            Layout.preferredWidth: 120
                            Layout.maximumWidth: 120
                            Layout.preferredHeight: {
                                var isMobile = Qt.platform.os === "android" || Qt.platform.os === "ios"
                                return isMobile ? 36 : 48
                            }
                            onClicked: {
                                if (bundleConfig && bundleConfig.docsUrl) {
                                    Qt.openUrlExternally(bundleConfig.docsUrl)
                                }
                            }
                        }
                    }
                }

                // ========== 授权信息（已禁用） ==========

            // 底部间距
            Item {
                Layout.preferredHeight: Theme.spacing.xxl
            }
        }
    }
}
