// pages/StorePage.qml (优化版 - 套餐管理)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0
import JinGo 1.0

Rectangle {
    id: storePage
    readonly property var mainWindow: Qt.application.topLevelWindow || null
    color: Theme.colors.pageBackground

    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    // Changed from reactive bindings to simple properties to avoid accessing subscriptionManager during init
    property var subscriptionListModel: null
    property var currentSubscription: null

    // 安全地更新订阅数据
    function updateSubscriptionData() {
        try {
            if (subscriptionManager && typeof subscriptionManager !== 'undefined') {
                subscriptionListModel = (typeof subscriptionManager.subscriptionListModel !== 'undefined') ?
                    subscriptionManager.subscriptionListModel : null
                currentSubscription = (typeof subscriptionManager.currentSubscription !== 'undefined') ?
                    subscriptionManager.currentSubscription : null
            } else {
                subscriptionListModel = null
                currentSubscription = null
            }
        } catch (e) {
            subscriptionListModel = null
            currentSubscription = null
        }
    }

    // 监听订阅管理器变化
    // Note: subscriptionManager signals are handled through authManager cache
    Connections {
        target: subscriptionManager
        enabled: false  // Disabled - using authManager cache instead

        // These signals don't exist in SubscriptionManager
        // function onCurrentSubscriptionChanged() {
        //     updateSubscriptionData()
        // }

        // function onSubscriptionListModelChanged() {
        //     updateSubscriptionData()
        // }
    }

    // 订阅数据状态
    property var subscribeData: null
    property bool isLoadingSubscribe: false
    property string subscribeError: ""

    // 订阅计划数据
    property var plansData: []
    property bool isLoadingPlans: false
    property string plansError: ""

    // 重置安全信息状态
    property bool isResettingSecurity: false

    // 创建计划列表模型
    ListModel {
        id: plansListModel
    }

    // 存储每个套餐的所有周期选项 {planId: [{period, name, price, monthlyPrice}, ...]}
    property var planPeriodOptions: ({})

    // 当计划数据变化时更新列表模型
    onPlansDataChanged: {
        plansListModel.clear()
        planPeriodOptions = {}

        for (var i = 0; i < plansData.length; i++) {
            var plan = plansData[i]

            // 跳过不可用的计划
            if (plan.show === false) {
                continue
            }

            // 收集所有可用的周期选项
            var periodOptions = []

            if (plan.month_price !== undefined && plan.month_price > 0) {
                var monthPrice = (plan.month_price / 100.0).toFixed(2)
                periodOptions.push({
                    period: "month_price",
                    name: qsTr("Monthly"),
                    price: monthPrice,
                    monthlyPrice: monthPrice,
                    description: qsTr("Billed monthly")
                })
            }

            if (plan.quarter_price !== undefined && plan.quarter_price > 0) {
                var quarterPrice = (plan.quarter_price / 100.0).toFixed(2)
                var quarterMonthly = (plan.quarter_price / 100.0 / 3).toFixed(2)
                periodOptions.push({
                    period: "quarter_price",
                    name: qsTr("Quarterly"),
                    price: quarterPrice,
                    monthlyPrice: quarterMonthly,
                    description: qsTr("Billed every 3 months")
                })
            }

            if (plan.half_year_price !== undefined && plan.half_year_price > 0) {
                var halfYearPrice = (plan.half_year_price / 100.0).toFixed(2)
                var halfYearMonthly = (plan.half_year_price / 100.0 / 6).toFixed(2)
                periodOptions.push({
                    period: "half_year_price",
                    name: qsTr("Semi-Annual"),
                    price: halfYearPrice,
                    monthlyPrice: halfYearMonthly,
                    description: qsTr("Billed every 6 months")
                })
            }

            if (plan.year_price !== undefined && plan.year_price > 0) {
                var yearPrice = (plan.year_price / 100.0).toFixed(2)
                var yearMonthly = (plan.year_price / 100.0 / 12).toFixed(2)
                periodOptions.push({
                    period: "year_price",
                    name: qsTr("Yearly"),
                    price: yearPrice,
                    monthlyPrice: yearMonthly,
                    description: qsTr("Billed annually - Best value!")
                })
            }

            if (plan.two_year_price !== undefined && plan.two_year_price > 0) {
                var twoYearPrice = (plan.two_year_price / 100.0).toFixed(2)
                var twoYearMonthly = (plan.two_year_price / 100.0 / 24).toFixed(2)
                periodOptions.push({
                    period: "two_year_price",
                    name: qsTr("2 Years"),
                    price: twoYearPrice,
                    monthlyPrice: twoYearMonthly,
                    description: qsTr("Billed every 2 years")
                })
            }

            if (plan.three_year_price !== undefined && plan.three_year_price > 0) {
                var threeYearPrice = (plan.three_year_price / 100.0).toFixed(2)
                var threeYearMonthly = (plan.three_year_price / 100.0 / 36).toFixed(2)
                periodOptions.push({
                    period: "three_year_price",
                    name: qsTr("3 Years"),
                    price: threeYearPrice,
                    monthlyPrice: threeYearMonthly,
                    description: qsTr("Billed every 3 years")
                })
            }

            if (plan.onetime_price !== undefined && plan.onetime_price > 0) {
                var onetimePrice = (plan.onetime_price / 100.0).toFixed(2)
                periodOptions.push({
                    period: "onetime_price",
                    name: qsTr("One-time"),
                    price: onetimePrice,
                    monthlyPrice: "",
                    description: qsTr("One-time payment, no renewal")
                })
            }

            // 使用第一个可用的周期作为默认显示
            var planPrice = "0"
            var planPeriod = ""

            if (periodOptions.length > 0) {
                planPrice = periodOptions[0].price
                planPeriod = periodOptions[0].name
            }

            // 存储周期选项
            var planId = plan.id || 0
            planPeriodOptions[planId] = periodOptions

            // 解析流量配额
            var dataLimit = plan.transfer_enable || 0

            // 解析特性列表
            var featuresList = []
            if (plan.content) {
                var lines = plan.content.split('\n')
                for (var j = 0; j < lines.length; j++) {
                    var line = lines[j].trim()
                    if (line) {
                        featuresList.push(line)
                    }
                }
            }

            // 添加到列表模型
            plansListModel.append({
                id: planId,
                name: plan.name || qsTr("Unnamed Plan"),
                price: planPrice,
                originalPrice: "",
                currency: "¥",
                duration: planPeriod,
                dataLimit: dataLimit,
                deviceLimit: plan.device_limit || 5,
                speed: plan.speed_limit > 0 ? (plan.speed_limit + " Mbps") : qsTr("Unlimited"),
                features: featuresList,
                isRecommended: plan.is_recommended || false,
                isPopular: plan.is_popular || false,
                isPurchasing: false,
                hasPeriodOptions: periodOptions.length > 1  // 是否有多个周期选项
            })
        }

        // 触发更新
        planPeriodOptions = planPeriodOptions
    }

    // 页面加载时获取订阅信息和计划列表
    Component.onCompleted: {
        updateSubscriptionData()

        // 调试authManager可用性

        // 从authManager读取已缓存的数据
        if (authManager && typeof authManager !== 'undefined') {

            // 读取订阅信息
            if (authManager.subscribeInfo && typeof authManager.subscribeInfo !== 'undefined') {
                var data = authManager.subscribeInfo
                var simplifiedData = {
                    d: data.d || 0,
                    u: data.u || 0,
                    transfer_enable: data.transfer_enable || 0,
                    device_limit: data.device_limit || 0,
                    email: data.email || "",
                    expired_at: data.expired_at || 0,
                    next_reset_at: data.next_reset_at || 0,
                    plan_id: data.plan_id || 0,
                    reset_day: data.reset_day || 0,
                    speed_limit: data.speed_limit || 0,
                    subscribe_url: data.subscribe_url || "",
                    token: data.token || "",
                    uuid: data.uuid || ""
                }
                subscribeData = simplifiedData
                isLoadingSubscribe = false
                subscribeError = ""
            } else {
            }

            // 读取套餐列表
            if (authManager.plans && typeof authManager.plans !== 'undefined') {
                plansData = authManager.plans
                isLoadingPlans = false
                plansError = ""
            } else {
            }
        } else {
        }
    }

    // 监听认证状态变化
    Connections {
        target: authManager

        function onAuthenticationChanged() {
            if (authManager && authManager.isAuthenticated) {
                // 用户登录后，数据由main.qml统一加载，这里只更新订阅数据引用
                updateSubscriptionData()
            } else {
                // 用户登出，清空数据
                subscribeData = null
                plansData = []
            }
        }

        function onSubscribeInfoLoaded(data) {
            // 只提取必要的字段，避免庞大的 plan 对象导致性能问题
            var simplifiedData = {
                d: data.d || 0,
                u: data.u || 0,
                transfer_enable: data.transfer_enable || 0,
                device_limit: data.device_limit || 0,
                email: data.email || "",
                expired_at: data.expired_at || 0,
                next_reset_at: data.next_reset_at || 0,
                plan_id: data.plan_id || 0,
                reset_day: data.reset_day || 0,
                speed_limit: data.speed_limit || 0,
                subscribe_url: data.subscribe_url || "",
                token: data.token || "",
                uuid: data.uuid || ""
            }

            subscribeData = simplifiedData
            isLoadingSubscribe = false
            subscribeError = ""
        }

        function onSubscribeInfoLoadFailed(error) {
            isLoadingSubscribe = false
            subscribeError = error
        }

        function onPlansLoaded(plans) {
            plansData = plans
            isLoadingPlans = false
            plansError = ""
        }

        function onPlansLoadFailed(error) {
            isLoadingPlans = false
            plansError = error
        }

        // 监听从数据库加载的数据变化
        function onSubscribeInfoChanged() {
            if (authManager && authManager.subscribeInfo) {
                var data = authManager.subscribeInfo
                var simplifiedData = {
                    d: data.d || 0,
                    u: data.u || 0,
                    transfer_enable: data.transfer_enable || 0,
                    device_limit: data.device_limit || 0,
                    email: data.email || "",
                    expired_at: data.expired_at || 0,
                    next_reset_at: data.next_reset_at || 0,
                    plan_id: data.plan_id || 0,
                    reset_day: data.reset_day || 0,
                    speed_limit: data.speed_limit || 0,
                    subscribe_url: data.subscribe_url || "",
                    token: data.token || "",
                    uuid: data.uuid || ""
                }
                subscribeData = simplifiedData
                isLoadingSubscribe = false
                subscribeError = ""
            }
        }

        function onPlansChanged() {
            if (authManager && authManager.plans) {
                plansData = authManager.plans
                isLoadingPlans = false
                plansError = ""
            }
        }

        function onResetSecuritySucceeded() {
            isResettingSecurity = false
            showResetSuccessMessage()
            // 重新加载订阅信息以获取新的链接
            loadSubscribeInfo()
        }

        function onResetSecurityFailed(error) {
            isResettingSecurity = false
            subscribeError = error
        }
    }

    // 监听后台数据更新完成
    Connections {
        target: typeof backgroundDataUpdater !== 'undefined' ? backgroundDataUpdater : null
        enabled: typeof backgroundDataUpdater !== 'undefined' && backgroundDataUpdater !== null

        function onSubscriptionInfoUpdated() {
            // 订阅信息更新完成，更新订阅数据
            if (!backgroundDataUpdater.isUpdating) {
                updateSubscriptionData()
            }
        }

        function onPlansUpdated() {
            // 套餐列表更新完成，刷新套餐数据
            // 数据已经通过 authManager.onPlansLoaded 信号更新
        }

        function onDataUpdateCompleted() {
            // 所有数据更新完成，刷新页面
            if (!backgroundDataUpdater.isUpdating) {
                updateSubscriptionData()
            }
        }
    }

    // 加载订阅信息的函数
    function loadSubscribeInfo() {
        if (!authManager || !authManager.isAuthenticated) {
            return
        }

        isLoadingSubscribe = true
        subscribeError = ""
        authManager.getUserSubscribe()
    }

    // 加载订阅计划的函数
    function loadPlans() {
        if (!authManager || !authManager.isAuthenticated) {
            return
        }

        isLoadingPlans = true
        plansError = ""
        authManager.fetchPlans()
    }

    // 手动更新订阅（从订阅地址重新获取服务器）
    function updateSubscriptionServers() {
        if (!subscribeData || !subscribeData.subscribe_url) {
            return
        }

        // 调用 SubscriptionManager 更新所有订阅
        // 这会重新从订阅地址下载服务器列表
        if (typeof subscriptionManager !== 'undefined' && subscriptionManager) {
            subscriptionManager.updateAllSubscriptions()
        }
    }

    ScrollView {
        id: mainScrollView
        anchors.fill: parent
        anchors.leftMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 16
        anchors.rightMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 16
        anchors.topMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 10
        anchors.bottomMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 10
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: mainScrollView.width

        ColumnLayout {
            width: mainScrollView.width
            spacing: Theme.spacing.lg

        // 当前订阅状态卡片
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: {
                if (!authManager || !authManager.isAuthenticated) return 0
                if (subscribeData) return 140
                if (isLoadingSubscribe) return 100
                return 120
            }
            radius: Theme.radius.md
            color: Theme.colors.surface
            border.width: 1
            border.color: Theme.colors.border
            visible: authManager && authManager.isAuthenticated
            opacity: visible ? 1 : 0

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            // 加载状态
            RowLayout {
                anchors.centerIn: parent
                spacing: Theme.spacing.sm
                visible: isLoadingSubscribe

                BusyIndicator {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    running: isLoadingSubscribe
                }

                Label {
                    text: qsTr("Loading subscription information...")
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.textSecondary
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.lg
                spacing: Theme.spacing.md
                visible: !isLoadingSubscribe

                // 订阅图标 - 纯字体图标
                Label {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    text: subscribeData ? "◆" : "○"
                    font.pixelSize: 32
                    color: subscribeData ? Theme.colors.primary : Theme.colors.textTertiary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // 订阅信息
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacing.xs

                    Label {
                        text: qsTr("Current Subscription")
                        font.pixelSize: Theme.typography.caption
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: subscribeData ?
                              getPlanName(subscribeData.plan_id) :
                              qsTr("NoneSubscription")
                        font.pixelSize: Theme.typography.h4
                        font.weight: Theme.typography.weightBold
                        color: subscribeData ? Theme.colors.textPrimary : Theme.colors.textSecondary
                    }

                    // 无订阅时的提示
                    Label {
                        visible: !subscribeData
                        text: qsTr("Select a plan below to get started")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textTertiary
                    }

                    // 订阅详情（到期时间和剩余流量）
                    RowLayout {
                        spacing: Theme.spacing.md
                        visible: subscribeData !== null

                        // 到期时间
                        RowLayout {
                            visible: subscribeData && subscribeData.expired_at
                            spacing: Theme.spacing.xs

                            IconSymbol {
                                icon: "clock"
                                size: 14
                                color: isExpiringSoon(subscribeData ? subscribeData.expired_at : 0) ? Theme.colors.warning : Theme.colors.textSecondary
                            }

                            Label {
                                text: subscribeData ?
                                      qsTr("Exp: %1").arg(formatExpireDate(subscribeData.expired_at)) :
                                      ""
                                font.pixelSize: Theme.typography.body2
                                color: isExpiringSoon(subscribeData ? subscribeData.expired_at : 0) ?
                                       Theme.colors.warning : Theme.colors.textSecondary
                            }
                        }

                        // 剩余流量
                        RowLayout {
                            visible: subscribeData && subscribeData.transfer_enable
                            spacing: Theme.spacing.xs

                            IconSymbol {
                                icon: "traffic"
                                size: 14
                                color: getTrafficPercentage() < 20 ? Theme.colors.error : Theme.colors.textSecondary
                            }

                            Label {
                                text: subscribeData ?
                                      qsTr("Rem: %1").arg(formatBytes(getRemainingTraffic())) :
                                      ""
                                font.pixelSize: Theme.typography.body2
                                color: getTrafficPercentage() < 20 ?
                                       Theme.colors.error : Theme.colors.textSecondary
                            }
                        }
                    }

                    // 流量使用进度条（显示已使用的百分比）
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Theme.colors.divider
                        visible: subscribeData && subscribeData.transfer_enable

                        Rectangle {
                            // ⭐ 修改：使用已使用百分比（100 - 剩余百分比）
                            width: parent.width * ((100 - getTrafficPercentage()) / 100)
                            height: parent.height
                            radius: parent.radius
                            color: {
                                // ⭐ 修改：颜色根据使用量显示
                                var usedPercent = 100 - getTrafficPercentage()
                                if (usedPercent > 80) return Theme.colors.error      // 使用超过80%：红色
                                if (usedPercent > 50) return Theme.colors.warning    // 使用超过50%：黄色
                                return Theme.colors.success                          // 使用少于50%：绿色
                            }
                        }
                    }
                }

            }
        }

        // 更新与订阅区域（可通过bundle_config.json隐藏）
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: subscribeInfoColumn.implicitHeight + Theme.spacing.lg * 2
            radius: Theme.radius.md
            color: Theme.colors.surface
            border.width: 1
            border.color: Theme.colors.border
            visible: authManager && authManager.isAuthenticated && (!bundleConfig || !bundleConfig.hideSubscriptionBlock)

            ColumnLayout {
                id: subscribeInfoColumn
                width: parent.width - Theme.spacing.lg * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacing.lg
                spacing: Theme.spacing.md

                // 区域标题和刷新按钮
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.md

                    Label {
                        text: qsTr("Update & Subscriptions")
                        font.pixelSize: Theme.typography.h4
                        font.weight: Theme.typography.weightBold
                        color: Theme.colors.textPrimary
                    }

                    Item { Layout.fillWidth: true }
                }

                // 订阅链接部分
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.sm
                    visible: subscribeData && subscribeData.subscribe_url

                    Label {
                        text: qsTr("Subscription link")
                        font.pixelSize: Theme.typography.caption
                        color: Theme.colors.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Theme.radius.xs
                        color: Theme.alpha(Theme.colors.primary, 0.05)
                        border.width: 1
                        border.color: Theme.alpha(Theme.colors.primary, 0.2)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacing.sm
                            anchors.rightMargin: Theme.spacing.sm
                            spacing: Theme.spacing.sm

                            Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter  // ⭐ 垂直居中
                                text: subscribeData ? (subscribeData.subscribe_url || "") : ""
                                font.pixelSize: Theme.typography.body2
                                font.family: "monospace"
                                color: Theme.colors.textPrimary
                                elide: Text.ElideMiddle
                            }

                            // 复制按钮 - 现代风格
                            Rectangle {
                                id: copyButton
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                radius: Theme.radius.sm
                                color: copyMouseArea.containsMouse ? Theme.alpha(Theme.colors.primary, 0.1) : "transparent"

                                IconSymbol {
                                    anchors.centerIn: parent
                                    icon: "copy"
                                    size: 16
                                    color: Theme.colors.primary
                                }

                                MouseArea {
                                    id: copyMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (subscribeData && subscribeData.subscribe_url) {
                                            copyToClipboard(subscribeData.subscribe_url)
                                            showCopyMessage()
                                        }
                                    }
                                }

                                ToolTip {
                                    visible: copyMouseArea.containsMouse
                                    text: qsTr("Copy subscription link")
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            // 更新按钮 - 现代风格
                            Rectangle {
                                id: updateButton
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                radius: Theme.radius.sm
                                color: updateMouseArea.containsMouse ? Theme.alpha(Theme.colors.success, 0.1) : "transparent"

                                IconSymbol {
                                    id: updateIcon
                                    anchors.centerIn: parent
                                    icon: "refresh"
                                    size: 16
                                    color: isResettingSecurity ? Theme.colors.textTertiary : Theme.colors.success

                                    // 更新中时的旋转动画
                                    RotationAnimator on rotation {
                                        from: 0
                                        to: 360
                                        duration: 1000
                                        running: isResettingSecurity
                                        loops: Animation.Infinite
                                    }
                                }

                                MouseArea {
                                    id: updateMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !isResettingSecurity
                                    hoverEnabled: true
                                    onClicked: {
                                        // 显示确认对话框
                                        resetSecurityConfirmDialog.open()
                                    }
                                }

                                ToolTip {
                                    visible: updateMouseArea.containsMouse
                                    text: isResettingSecurity ? qsTr("Updating...") : qsTr("Update subscription link")
                                }

                                opacity: isResettingSecurity ? 0.6 : 1.0
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                        }
                    }
                }

                // 流量重置日期
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.sm
                    visible: subscribeData && (subscribeData.next_reset_at || subscribeData.reset_day)

                    Label {
                        text: qsTr("Traffic Reset Date:")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: {
                            if (!subscribeData) return ""
                            // 优先显示下次重置的具体日期
                            if (subscribeData.next_reset_at && subscribeData.next_reset_at > 0) {
                                var date = new Date(subscribeData.next_reset_at * 1000)
                                return date.getFullYear() + "-" +
                                       String(date.getMonth() + 1).padStart(2, '0') + "-" +
                                       String(date.getDate()).padStart(2, '0')
                            }
                            // 回退到每月几号
                            if (subscribeData.reset_day) {
                                return qsTr("Day %1 of each month").arg(subscribeData.reset_day)
                            }
                            return ""
                        }
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                    }
                }

                // 设备限制
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.sm
                    visible: subscribeData && subscribeData.device_limit

                    Label {
                        text: qsTr("Device Limit:")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: subscribeData ? qsTr("%1 devices").arg(subscribeData.device_limit) : ""
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                    }
                }

                // 速度限制
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.sm
                    visible: subscribeData && subscribeData.speed_limit

                    Label {
                        text: qsTr("Speed Limit:")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: subscribeData ? qsTr("%1 Mbps").arg(subscribeData.speed_limit) : ""
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                    }
                }

                // 错误提示
                Label {
                    Layout.fillWidth: true
                    text: subscribeError
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.error
                    wrapMode: Text.WordWrap
                    visible: subscribeError !== ""
                }

                // 未登录提示
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Please login first to view subscription information")
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    visible: !authManager || !authManager.isAuthenticated
                }

                // 加载中提示
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: Theme.spacing.sm
                    visible: isLoadingSubscribe

                    BusyIndicator {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        running: isLoadingSubscribe
                    }

                    Label {
                        text: qsTr("Loading subscription information...")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }
                }
            }
        }

        // 套餐列表标题
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.md
            Layout.leftMargin: Theme.spacing.lg
            Layout.rightMargin: Theme.spacing.lg

            Label {
                text: qsTr("Select Plan")
                font.pixelSize: Theme.typography.h4
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
            }

            Item { Layout.fillWidth: true }
        }

        // 套餐网格 - 使用Grid布局展示套餐卡片，响应式适配
        GridLayout {
            id: plansGrid
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.xs

            // 根据设备类型和宽度动态计算列数
            columns: {
                // 优先使用宽度判断，更可靠
                var width = mainScrollView.width

                // 小屏手机（小于500px）：1列
                if (width < 500) {
                    return 1
                }
                // 手机端和中等屏幕（500-1000px）：2列
                else if (width < 1000) {
                    return 2
                }
                // 大屏幕（1000px+）：3列
                else {
                    return 3
                }
            }

            // 列间距和行间距 - 根据屏幕宽度调整
            columnSpacing: mainScrollView.width < 500 ? 0 : (mainScrollView.width < 600 ? Theme.spacing.xs : Theme.spacing.sm)
            rowSpacing: mainScrollView.width < 500 ? Theme.spacing.sm : Theme.spacing.md

            // 套餐卡片
            Repeater {
                model: plansListModel

                SubscriptionCard {
                    // 动态计算宽度
                    Layout.fillWidth: true
                    Layout.preferredWidth: {
                        var availableWidth = mainScrollView.width
                        var cols = plansGrid.columns
                        if (cols === 1) {
                            // 手机端：占满宽度
                            return availableWidth
                        } else {
                            // 平板和桌面：根据列数计算
                            var totalSpacing = (cols - 1) * plansGrid.columnSpacing
                            return (availableWidth - totalSpacing) / cols
                        }
                    }

                    // 根据设备和列数调整高度
                    height: {
                        var cols = plansGrid.columns
                        if (cols === 1) {
                            // 单列布局：紧凑高度
                            return 320
                        } else if (mainWindow && mainWindow.isMobile) {
                            return 360
                        } else {
                            return 380
                        }
                    }

                    // 套餐数据绑定
                    planId: model.id || ""
                    planName: model.name || qsTr("Unnamed Plan")
                    price: model.price || "0"
                    currency: model.currency || "¥"
                    duration: model.duration || qsTr("Month")
                    originalPrice: model.originalPrice || ""
                    dataLimit: model.dataLimit || 0
                    deviceLimit: model.deviceLimit || 5
                    speed: model.speed || ""
                    features: model.features || []
                    isRecommended: model.isRecommended || false
                    isPopular: model.isPopular || false
                    isPurchasing: model.isPurchasing || false
                    isPurchased: (subscribeData && subscribeData.plan_id === model.id) || false

                    onPurchaseClicked: {
                        // 开始购买流程
                        startPurchase(planId, model.name, model.price, model.currency)
                    }
                }
            }
        }  // Close GridLayout

        // ⭐ 已删除"续费订阅"按钮 - 每个套餐卡片上都有续费按钮

        // 空状态提示 - 纯字体图标
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.md
            visible: plansListModel.count === 0 && !isLoadingPlans

            Label {
                text: "○"
                font.pixelSize: 64
                color: Theme.colors.textTertiary
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: plansError ? plansError : qsTr("NoneAvailablePlans")
                font.pixelSize: Theme.typography.h4
                color: plansError ? Theme.colors.error : Theme.colors.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // 加载中提示
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.md
            visible: isLoadingPlans

            BusyIndicator {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter
                running: isLoadingPlans
            }

            Label {
                text: qsTr("LoadingPlans...")
                font.pixelSize: Theme.typography.body1
                color: Theme.colors.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
        }
        }  // Close ColumnLayout
    }  // Close mainScrollView

    // 复制成功消息提示
    Rectangle {
        id: copyToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: 200
        height: 48
        radius: Theme.radius.md
        color: Theme.colors.success
        opacity: 0
        visible: opacity > 0

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Label {
                text: "✓"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: "white"
            }

            Label {
                text: qsTr("Copied to clipboard")
                color: "white"
                font.pixelSize: Theme.typography.body2
                font.weight: Theme.typography.weightMedium
            }
        }

        NumberAnimation on opacity {
            id: copyToastAnimation
            running: false
            from: 1
            to: 0
            duration: 2000
            easing.type: Easing.InOutQuad
        }
    }

    // 重置成功消息提示
    Rectangle {
        id: resetToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 140
        width: 220
        height: 48
        radius: Theme.radius.md
        color: Theme.colors.success
        opacity: 0
        visible: opacity > 0

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Label {
                text: "✓"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: "white"
            }

            Label {
                text: qsTr("Subscription link updated")
                color: "white"
                font.pixelSize: Theme.typography.body2
                font.weight: Theme.typography.weightMedium
            }
        }

        NumberAnimation on opacity {
            id: resetToastAnimation
            running: false
            from: 1
            to: 0
            duration: 2000
            easing.type: Easing.InOutQuad
        }
    }

    // 辅助函数
    function formatDate(dateTime) {
        if (!dateTime) return ""
        // 简单的日期格式化
        var date = new Date(dateTime)
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    function formatExpireDate(timestamp) {
        if (!timestamp) return ""
        // XBoard 使用秒级时间戳
        var date = new Date(timestamp * 1000)
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    function getPlanName(planId) {
        if (!planId) return qsTr("UnknownPlans")

        // 从计划列表中查找对应的计划名称
        for (var i = 0; i < plansListModel.count; i++) {
            var plan = plansListModel.get(i)
            if (plan.id === planId) {
                return plan.name
            }
        }

        return qsTr("Plans #") + planId
    }

    function getRemainingTraffic() {
        if (!subscribeData) return 0

        var total = subscribeData.transfer_enable || 0
        var upload = subscribeData.u || 0
        var download = subscribeData.d || 0
        var used = upload + download

        return Math.max(0, total - used)
    }

    function getTrafficPercentage() {
        if (!subscribeData || !subscribeData.transfer_enable) return 0

        var total = subscribeData.transfer_enable
        var remaining = getRemainingTraffic()

        return Math.round((remaining / total) * 100)
    }

    function isExpiringSoon(timestamp) {
        if (!timestamp) return false

        // 检查是否7天内到期
        var expireDate = new Date(timestamp * 1000)
        var now = new Date()
        var daysDiff = Math.floor((expireDate - now) / (1000 * 60 * 60 * 24))

        return daysDiff <= 7 && daysDiff >= 0
    }

    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        if (bytes < 0) return qsTr("Unlimited")

        var k = 1024
        var sizes = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))
        var value = (bytes / Math.pow(k, i)).toFixed(2)

        return value + " " + sizes[i]
    }

    // 复制到剪贴板
    function copyToClipboard(text) {
        if (!text) return

        // 使用 ClipboardHelper
        if (typeof clipboardHelper !== 'undefined') {
            clipboardHelper.setText(text)
        }
    }

    // 显示复制成功消息
    function showCopyMessage() {
        copyToast.opacity = 1
        copyToastAnimation.restart()
    }

    // 显示重置成功消息
    function showResetSuccessMessage() {
        resetToast.opacity = 1
        resetToastAnimation.restart()
    }

    // ========================================================================
    // 购买支付流程
    // ========================================================================

    // 当前购买状态
    property int purchasingPlanId: 0
    property string currentOrderId: ""
    property var availablePaymentMethods: []
    property bool isLoadingPaymentMethods: false
    property bool isCreatingOrder: false
    property bool isProcessingPayment: false

    // 周期选择对话框
    PeriodSelectDialog {
        id: periodSelectDialog
        parent: Overlay.overlay

        onPeriodConfirmed: function(planId, period, periodName, price) {
            // 保存选择的周期
            selectedPeriod = period
            paymentDialog.planPrice = price
            paymentDialog.currency = "¥"

            // 创建订单（带周期）
            createOrder(planId, period)
        }

        onRejected: {
            purchasingPlanId = 0
        }
    }

    // 当前选择的周期
    property string selectedPeriod: ""

    // 支付方式选择对话框
    PaymentDialog {
        id: paymentDialog
        parent: Overlay.overlay

        paymentMethods: availablePaymentMethods
        isProcessing: isProcessingPayment

        onPaymentConfirmed: function(planId, paymentMethod) {
            processPayment(paymentMethod)
        }

        onRejected: {
            // 取消支付，清空状态
            purchasingPlanId = 0
            currentOrderId = ""
            selectedPeriod = ""
        }
    }

    // 订单管理器信号连接
    Connections {
        target: typeof orderManager !== 'undefined' ? orderManager : null
        enabled: typeof orderManager !== 'undefined'

        function onOrderCreated(order) {
            isCreatingOrder = false
            // 保存订单ID
            currentOrderId = order.trade_no || ""
            // 加载支付方式
            loadPaymentMethods()
        }

        function onOrderFailed(error) {
            isCreatingOrder = false
            showErrorMessage(error)
            purchasingPlanId = 0
        }
    }

    // 支付相关信号连接（使用 orderManager）
    Connections {
        target: typeof orderManager !== 'undefined' ? orderManager : null
        enabled: typeof orderManager !== 'undefined'

        function onPaymentMethodsLoaded(methods) {
            isLoadingPaymentMethods = false
            // 先构建临时数组，然后一次性赋值（QML 需要整体赋值才能触发属性变更）
            var tempMethods = []
            if (methods) {
                for (var i = 0; i < methods.length; i++) {
                    tempMethods.push(methods[i])
                }
            }
            // 一次性赋值触发属性变更通知
            availablePaymentMethods = tempMethods
            // 显示支付对话框
            if (availablePaymentMethods.length > 0) {
                paymentDialog.open()
            } else {
                showErrorMessage(qsTr("No payment methods available"))
                purchasingPlanId = 0
                currentOrderId = ""
            }
        }

        function onPaymentMethodsFailed(error) {
            isLoadingPaymentMethods = false
            showErrorMessage(error)
            purchasingPlanId = 0
            currentOrderId = ""
        }

        function onPaymentUrlReady(url, type) {
            isProcessingPayment = false
            paymentDialog.close()

            // 显示支付成功
            showSuccessMessage(qsTr("Payment initiated successfully"))

            // 打开浏览器支付
            if (url) {
                Qt.openUrlExternally(url)
            }

            // 延迟刷新订阅信息
            refreshSubscriptionTimer.restart()

            // 清空状态
            purchasingPlanId = 0
            currentOrderId = ""
        }

        function onPaymentFailed(error) {
            isProcessingPayment = false
            showErrorMessage(error)
        }
    }

    // 刷新订阅信息定时器（支付成功后延迟刷新）
    Timer {
        id: refreshSubscriptionTimer
        interval: 3000
        repeat: false
        onTriggered: {
            // 刷新订阅信息
            if (authManager) {
                authManager.getUserSubscribe()
            }
        }
    }

    // 开始购买流程
    function startPurchase(planId, planName, price, currency) {
        if (!authManager || !authManager.isAuthenticated) {
            showErrorMessage(qsTr("Please login first"))
            return
        }

        purchasingPlanId = planId
        paymentDialog.planId = planId
        paymentDialog.planName = planName
        paymentDialog.planPrice = price
        paymentDialog.currency = currency

        // 检查是否有多个周期选项
        var periodOptions = planPeriodOptions[planId] || []

        if (periodOptions.length > 1) {
            // 显示周期选择对话框
            periodSelectDialog.planId = planId
            periodSelectDialog.planName = planName
            periodSelectDialog.periodOptions = periodOptions
            periodSelectDialog.currency = currency
            periodSelectDialog.open()
        } else if (periodOptions.length === 1) {
            // 只有一个选项，直接使用
            selectedPeriod = periodOptions[0].period
            paymentDialog.planPrice = periodOptions[0].price
            createOrder(planId, periodOptions[0].period)
        } else {
            // 没有周期选项，使用默认
            selectedPeriod = ""
            createOrder(planId, "")
        }
    }

    // 创建订单
    function createOrder(planId, period) {
        if (!orderManager) {
            showErrorMessage(qsTr("Order manager not available"))
            return
        }

        isCreatingOrder = true
        // 创建订单：planId, period (可选), couponCode (可选)
        orderManager.createOrder(planId, period || "", "")
    }

    // 加载支付方式
    function loadPaymentMethods() {
        if (!orderManager) {
            showErrorMessage(qsTr("Order manager not available"))
            return
        }
        isLoadingPaymentMethods = true
        orderManager.fetchPaymentMethods()
    }

    // 处理支付
    function processPayment(paymentMethod) {
        if (!orderManager || !currentOrderId) {
            showErrorMessage(qsTr("Invalid order"))
            return
        }
        isProcessingPayment = true
        orderManager.getPaymentUrl(currentOrderId, paymentMethod.toString())
    }

    // 错误提示Toast
    Rectangle {
        id: errorToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: Math.min(300, parent.width * 0.8)
        height: 60
        radius: Theme.radius.md
        color: Theme.colors.error
        opacity: 0
        visible: opacity > 0

        Label {
            anchors.centerIn: parent
            anchors.margins: Theme.spacing.sm
            text: errorToast.errorText
            color: "white"
            font.pixelSize: Theme.typography.body2
            font.weight: Theme.typography.weightMedium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - Theme.spacing.lg
        }

        property string errorText: ""

        NumberAnimation on opacity {
            id: errorToastAnimation
            running: false
            from: 1
            to: 0
            duration: 3000
            easing.type: Easing.InOutQuad
        }
    }

    // 成功提示Toast
    Rectangle {
        id: successToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 150
        width: Math.min(300, parent.width * 0.8)
        height: 60
        radius: Theme.radius.md
        color: Theme.colors.success
        opacity: 0
        visible: opacity > 0

        Label {
            anchors.centerIn: parent
            anchors.margins: Theme.spacing.sm
            text: successToast.successText
            color: "white"
            font.pixelSize: Theme.typography.body2
            font.weight: Theme.typography.weightMedium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - Theme.spacing.lg
        }

        property string successText: ""

        NumberAnimation on opacity {
            id: successToastAnimation
            running: false
            from: 1
            to: 0
            duration: 3000
            easing.type: Easing.InOutQuad
        }
    }

    // 显示错误消息
    function showErrorMessage(message) {
        errorToast.errorText = message
        errorToast.opacity = 1
        errorToastAnimation.restart()
    }

    // 显示成功消息
    function showSuccessMessage(message) {
        successToast.successText = message
        successToast.opacity = 1
        successToastAnimation.restart()
    }

    // 更新订阅链接确认对话框 - 现代风格
    Dialog {
        id: resetSecurityConfirmDialog
        modal: true
        standardButtons: Dialog.NoButton
        closePolicy: Popup.CloseOnEscape

        width: Math.min(420, parent ? parent.width * 0.9 : 420)
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        background: Rectangle {
            color: Theme.colors.background
            radius: Theme.radius.xl
            border.width: 1
            border.color: Theme.colors.border
        }

        // 半透明遮罩层
        Overlay.modal: Rectangle {
            color: Theme.alpha("#000000", 0.5)
        }

        header: Item { height: 0 }  // 隐藏默认标题栏
        padding: 0

        contentItem: ColumnLayout {
            spacing: 0

            // 顶部警告图标区域（无圆角，纯色背景）
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: Theme.alpha(Theme.colors.warning, 0.1)

                // 警告图标
                Rectangle {
                    width: 60
                    height: 60
                    radius: 30
                    color: Theme.alpha(Theme.colors.warning, 0.2)
                    anchors.centerIn: parent

                    Label {
                        text: "⚠"
                        font.pixelSize: 32
                        color: Theme.colors.warning
                        anchors.centerIn: parent
                    }
                }
            }

            // 内容区域
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacing.lg
                spacing: Theme.spacing.md

                Label {
                    text: qsTr("Update Subscription Link?")
                    font.pixelSize: Theme.typography.h4
                    font.weight: Theme.typography.weightBold
                    color: Theme.colors.textPrimary
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: warningContent.height + Theme.spacing.md * 2
                    radius: Theme.radius.md
                    color: Theme.alpha(Theme.colors.error, 0.08)
                    border.width: 1
                    border.color: Theme.alpha(Theme.colors.error, 0.2)

                    ColumnLayout {
                        id: warningContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacing.md
                        spacing: Theme.spacing.xs

                        Label {
                            text: qsTr("Warning: This action cannot be undone!")
                            font.pixelSize: Theme.typography.body2
                            font.weight: Theme.typography.weightBold
                            color: Theme.colors.error
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Label {
                            text: qsTr("The old subscription URL will become invalid immediately.")
                            font.pixelSize: Theme.typography.caption
                            color: Theme.colors.error
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Label {
                    text: qsTr("You will need to re-import the new subscription link on all your devices after updating.")
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.textSecondary
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                }
            }

            // 按钮区域
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacing.lg
                Layout.topMargin: 0
                spacing: Theme.spacing.md

                // 取消按钮
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: Theme.radius.md
                    color: cancelBtnArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface
                    border.width: 1
                    border.color: Theme.colors.border

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                    }

                    MouseArea {
                        id: cancelBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: resetSecurityConfirmDialog.reject()
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // 确认按钮
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: Theme.radius.md
                    color: confirmBtnArea.containsMouse ? Qt.darker(Theme.colors.warning, 1.1) : Theme.colors.warning

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Update")
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightBold
                        color: "white"
                    }

                    MouseArea {
                        id: confirmBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            resetSecurityConfirmDialog.accept()
                        }
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        onAccepted: {
            isResettingSecurity = true
            authManager.resetSecurity()
        }
    }
}
