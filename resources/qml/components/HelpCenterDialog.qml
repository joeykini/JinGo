// qml/components/HelpCenterDialog.qml - 知识库/帮助中心 (现代风格)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Dialog {
    id: helpCenterDialog

    title: qsTr("Help Center")
    modal: true
    standardButtons: Dialog.NoButton

    // 移动端检测
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios" ||
                                     (parent ? parent.width < 768 : false)

    // 响应式尺寸
    width: isMobile ? (parent ? parent.width * 0.95 : 350) : Math.min(650, parent ? parent.width * 0.9 : 650)
    height: isMobile ? (parent ? parent.height * 0.9 : 500) : Math.min(650, parent ? parent.height * 0.85 : 650)

    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    property var sysConfigMgr: null  // 重命名避免与全局上下文属性冲突
    property bool isLoading: false
    property string errorMessage: ""
    property var articleList: []

    // 当前页面状态: "list", "detail"
    property string currentView: "list"
    property var currentArticle: null

    // 搜索
    property string searchText: ""

    background: Rectangle {
        color: Theme.colors.background
        radius: isMobile ? Theme.radius.md : Theme.radius.lg
        border.width: 1
        border.color: Theme.colors.border
    }

    header: Rectangle {
        height: isMobile ? 52 : 56
        color: Theme.colors.background
        radius: isMobile ? Theme.radius.md : Theme.radius.lg

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.radius.lg
            color: parent.color
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.colors.divider
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.lg
            anchors.rightMargin: Theme.spacing.lg
            spacing: Theme.spacing.md

            // 返回按钮 - 仅在详情页显示
            Rectangle {
                Layout.preferredWidth: isMobile ? 40 : 32
                Layout.preferredHeight: isMobile ? 40 : 32
                Layout.minimumWidth: Theme.size.touchTarget
                Layout.minimumHeight: Theme.size.touchTarget
                radius: Theme.radius.sm
                color: backArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"
                visible: currentView === "detail"

                Label {
                    text: "←"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: Theme.colors.textPrimary
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentView = "list"
                        currentArticle = null
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Label {
                text: currentView === "detail" && currentArticle ? currentArticle.title : qsTr("Help Center")
                font.pixelSize: Theme.typography.body1
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // 刷新按钮 - 仅在列表页显示
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radius.sm
                color: refreshArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"
                visible: currentView === "list"

                IconSymbol {
                    id: refreshIcon
                    icon: "refresh"
                    size: 18
                    color: isLoading ? Theme.colors.primary : Theme.colors.textSecondary
                    anchors.centerIn: parent

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: isLoading
                    }
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !isLoading
                    onClicked: loadArticles()
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // 关闭按钮
            Rectangle {
                Layout.preferredWidth: isMobile ? 40 : 32
                Layout.preferredHeight: isMobile ? 40 : 32
                Layout.minimumWidth: Theme.size.touchTarget
                Layout.minimumHeight: Theme.size.touchTarget
                radius: Theme.radius.sm
                color: closeArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.08) : "transparent"

                Label {
                    text: "×"
                    font.pixelSize: isMobile ? 24 : 20
                    color: Theme.colors.textSecondary
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: helpCenterDialog.close()
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    onOpened: {
        currentView = "list"
        currentArticle = null
        searchText = ""
        loadArticles()
    }

    onClosed: {
        currentView = "list"
        currentArticle = null
        searchText = ""
    }

    function loadArticles() {
        if (sysConfigMgr) {
            isLoading = true
            errorMessage = ""
            sysConfigMgr.fetchKnowledge()
        } else {
            errorMessage = qsTr("System not ready, please try again later")
        }
    }

    function formatDate(timestamp) {
        if (!timestamp) return "--"
        var date = new Date(timestamp * 1000)
        return date.toLocaleDateString()
    }

    // 过滤文章列表
    function getFilteredArticles() {
        if (!searchText.trim()) return articleList
        var lowerSearch = searchText.toLowerCase()
        var filtered = []
        for (var i = 0; i < articleList.length; i++) {
            var article = articleList[i]
            if ((article.title && article.title.toLowerCase().indexOf(lowerSearch) !== -1) ||
                (article.description && article.description.toLowerCase().indexOf(lowerSearch) !== -1) ||
                (article.category && article.category.toLowerCase().indexOf(lowerSearch) !== -1)) {
                filtered.push(article)
            }
        }
        return filtered
    }

    // 简单的Markdown转HTML（基础支持）
    function markdownToHtml(text) {
        if (!text) return ""

        var html = text

        // 标题
        html = html.replace(/^### (.*$)/gm, '<h3 style="color:' + Theme.colors.textPrimary + ';margin:12px 0 6px 0;">$1</h3>')
        html = html.replace(/^## (.*$)/gm, '<h2 style="color:' + Theme.colors.textPrimary + ';margin:16px 0 8px 0;">$1</h2>')
        html = html.replace(/^# (.*$)/gm, '<h1 style="color:' + Theme.colors.textPrimary + ';margin:20px 0 10px 0;">$1</h1>')

        // 粗体和斜体
        html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<b><i>$1</i></b>')
        html = html.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
        html = html.replace(/\*(.*?)\*/g, '<i>$1</i>')

        // 代码块 - 先保护起来避免被换行处理影响
        var codeBlocks = []
        html = html.replace(/```([\s\S]*?)```/g, function(match, code) {
            var placeholder = '___CODEBLOCK_' + codeBlocks.length + '___'
            codeBlocks.push('<pre style="background:' + Theme.colors.surfaceElevated + ';padding:12px;border-radius:8px;overflow-x:auto;font-family:monospace;font-size:13px;margin:8px 0;">' + code + '</pre>')
            return placeholder
        })

        // 行内代码
        html = html.replace(/`([^`]+)`/g, '<code style="background:' + Theme.colors.surfaceElevated + ';padding:2px 6px;border-radius:4px;font-family:monospace;">$1</code>')

        // 图片 - 必须在链接之前处理，因为语法相似 ![alt](url)
        html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" style="max-width:100%;height:auto;border-radius:8px;margin:8px 0;" />')

        // 链接
        html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color:' + Theme.colors.primary + ';">$1</a>')

        // 无序列表
        html = html.replace(/^\s*[-*+]\s+(.*$)/gm, '<li style="margin:2px 0;">$1</li>')

        // 有序列表
        html = html.replace(/^\s*\d+\.\s+(.*$)/gm, '<li style="margin:2px 0;">$1</li>')

        // 引用
        html = html.replace(/^>\s*(.*$)/gm, '<blockquote style="border-left:4px solid ' + Theme.colors.primary + ';margin:8px 0;padding:4px 12px;background:' + Theme.colors.surfaceElevated + ';">$1</blockquote>')

        // 分割线
        html = html.replace(/^---$/gm, '<hr style="border:none;border-top:1px solid ' + Theme.colors.border + ';margin:12px 0;">')

        // 处理换行：双换行变段落，单换行变空格（Markdown标准行为）
        // 先把连续3个以上换行合并为2个
        html = html.replace(/\n{3,}/g, '\n\n')
        // 双换行变段落分隔
        html = html.replace(/\n\n/g, '</p><p style="margin:8px 0;">')
        // 单换行变空格（除非在列表项后面）
        html = html.replace(/([^>])\n([^<])/g, '$1 $2')
        // 清理剩余的单独换行
        html = html.replace(/\n/g, '')

        // 包装在段落中
        html = '<p style="margin:0;">' + html + '</p>'

        // 恢复代码块
        for (var i = 0; i < codeBlocks.length; i++) {
            html = html.replace('___CODEBLOCK_' + i + '___', codeBlocks[i])
        }

        return html
    }

    contentItem: Item {
        // ========== 列表视图 ==========
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            visible: currentView === "list"

            // 搜索框
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.margins: Theme.spacing.md
                radius: Theme.radius.md
                color: Theme.colors.inputBackground
                border.width: 1
                border.color: searchInput.activeFocus ? Theme.colors.primary : Theme.colors.inputBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.sm
                    spacing: Theme.spacing.sm

                    // 搜索图标 - 纯字体图标
                    Label {
                        text: "⌕"
                        font.pixelSize: 18
                        color: Theme.colors.primary
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignHCenter
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("Search articles...")
                        text: searchText
                        onTextChanged: searchText = text
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textPrimary
                        background: Rectangle { color: "transparent" }
                    }

                    // 清除按钮
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.radius.sm
                        color: clearSearchArea.containsMouse ? Theme.alpha(Theme.colors.textPrimary, 0.1) : "transparent"
                        visible: searchText.length > 0

                        Label {
                            anchors.centerIn: parent
                            text: "×"
                            font.pixelSize: 16
                            color: Theme.colors.textSecondary
                        }

                        MouseArea {
                            id: clearSearchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchText = ""
                                searchInput.text = ""
                            }
                        }
                    }
                }
            }

            // 加载中状态 - 骨架屏
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: isLoading

                Column {
                    width: parent.width
                    spacing: Theme.spacing.sm
                    topPadding: Theme.spacing.xs

                    Repeater {
                        model: 5

                        Rectangle {
                            width: parent.width - Theme.spacing.md * 2
                            x: Theme.spacing.md
                            height: 80
                            radius: Theme.radius.md
                            color: Theme.colors.surface
                            border.width: 1
                            border.color: Theme.colors.border

                            Column {
                                anchors.fill: parent
                                anchors.margins: Theme.spacing.md
                                spacing: Theme.spacing.xs

                                Rectangle {
                                    width: parent.width * 0.6
                                    height: 18
                                    radius: Theme.radius.sm
                                    color: Theme.colors.surfaceElevated
                                    SequentialAnimation on opacity {
                                        running: isLoading; loops: Animation.Infinite
                                        NumberAnimation { to: 0.5; duration: 800 }
                                        NumberAnimation { to: 1; duration: 800 }
                                    }
                                }

                                Rectangle {
                                    width: parent.width * 0.9
                                    height: 14
                                    radius: Theme.radius.sm
                                    color: Theme.colors.surfaceElevated
                                    SequentialAnimation on opacity {
                                        running: isLoading; loops: Animation.Infinite
                                        NumberAnimation { to: 0.5; duration: 800 }
                                        NumberAnimation { to: 1; duration: 800 }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacing.md

                                    Rectangle {
                                        width: 60
                                        height: 20
                                        radius: 10
                                        color: Theme.colors.surfaceElevated
                                        SequentialAnimation on opacity {
                                            running: isLoading; loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 800 }
                                            NumberAnimation { to: 1; duration: 800 }
                                        }
                                    }

                                    Rectangle {
                                        width: 80
                                        height: 12
                                        radius: Theme.radius.sm
                                        color: Theme.colors.surfaceElevated
                                        SequentialAnimation on opacity {
                                            running: isLoading; loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 800 }
                                            NumberAnimation { to: 1; duration: 800 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 错误提示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.margins: Theme.spacing.md
                radius: Theme.radius.md
                color: Theme.alpha(Theme.colors.error, 0.08)
                border.width: 1
                border.color: Theme.alpha(Theme.colors.error, 0.3)
                visible: errorMessage !== "" && !isLoading

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.md
                    spacing: Theme.spacing.sm

                    Label {
                        text: "⚠"
                        font.pixelSize: 18
                        color: Theme.colors.error
                    }

                    Label {
                        text: errorMessage
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.error
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 30
                        radius: Theme.radius.sm
                        color: retryArea.containsMouse ? Qt.darker(Theme.colors.error, 1.1) : Theme.colors.error

                        Label {
                            text: qsTr("Retry")
                            font.pixelSize: Theme.typography.caption
                            color: "white"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: retryArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loadArticles()
                        }
                    }
                }
            }

            // 空状态
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                visible: !isLoading && errorMessage === "" && getFilteredArticles().length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacing.md

                    Label {
                        text: searchText ? "?" : "≡"
                        font.pixelSize: 64
                        color: Theme.colors.textTertiary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: searchText ? qsTr("No matching articles") : qsTr("No articles yet")
                        font.pixelSize: Theme.typography.body1
                        font.weight: Theme.typography.weightBold
                        color: Theme.colors.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: searchText ? qsTr("Try different keywords") : qsTr("Help articles will appear here")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 36
                        radius: Theme.radius.md
                        color: clearFilterArea.containsMouse ? Qt.darker(Theme.colors.primary, 1.1) : Theme.colors.primary
                        visible: searchText !== ""
                        Layout.alignment: Qt.AlignHCenter

                        Label {
                            text: qsTr("Clear Search")
                            font.pixelSize: Theme.typography.caption
                            color: "white"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: clearFilterArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchText = ""
                                searchInput.text = ""
                            }
                        }
                    }
                }
            }

            // 文章列表
            ListView {
                id: articleListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                visible: !isLoading && errorMessage === "" && getFilteredArticles().length > 0
                clip: true
                spacing: Theme.spacing.sm
                model: getFilteredArticles()

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: articleListView.width
                    height: articleCol.height + Theme.spacing.md * 2
                    radius: Theme.radius.md
                    color: delegateArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface
                    border.width: 1
                    border.color: delegateArea.containsMouse ? Theme.colors.primary : Theme.colors.border

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    ColumnLayout {
                        id: articleCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spacing.md
                        spacing: Theme.spacing.xs

                        Label {
                            text: modelData.title || qsTr("Untitled")
                            font.pixelSize: Theme.typography.body2
                            font.weight: Theme.typography.weightBold
                            color: Theme.colors.textPrimary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Label {
                            text: modelData.description || ""
                            font.pixelSize: Theme.typography.caption
                            color: Theme.colors.textSecondary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            visible: modelData.description && modelData.description.length > 0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.md

                            // 分类标签
                            Rectangle {
                                Layout.preferredWidth: catLabel.width + 16
                                Layout.preferredHeight: 22
                                radius: 11
                                color: Theme.alpha(Theme.colors.primary, 0.1)
                                visible: modelData.category && modelData.category.length > 0

                                Label {
                                    id: catLabel
                                    text: modelData.category || ""
                                    font.pixelSize: Theme.typography.small
                                    color: Theme.colors.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Label {
                                text: formatDate(modelData.updated_at || modelData.created_at)
                                font.pixelSize: Theme.typography.small
                                color: Theme.colors.textTertiary
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: "→"
                                font.pixelSize: 14
                                color: Theme.colors.textTertiary
                            }
                        }
                    }

                    MouseArea {
                        id: delegateArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentArticle = modelData
                            currentView = "detail"
                            detailView.loadArticle()
                        }
                    }
                }
            }
        }

        // ========== 文章详情视图 ==========
        ArticleDetailView {
            id: detailView
            anchors.fill: parent
            visible: currentView === "detail"
            sysConfigMgr: helpCenterDialog.sysConfigMgr
            articleData: currentArticle
        }
    }

    // 连接 SystemConfigManager 信号
    Connections {
        target: sysConfigMgr

        function onKnowledgeLoaded(articles) {
            isLoading = false
            errorMessage = ""
            // 创建新数组并重新赋值，以触发QML视图更新
            var newList = []
            for (var i = 0; i < articles.length; i++) {
                newList.push(articles[i])
            }
            articleList = newList
        }

        function onKnowledgeFailed(error) {
            isLoading = false
            errorMessage = error
        }
    }

    // ========== 内嵌组件：文章详情视图 ==========
    component ArticleDetailView: Item {
        property var sysConfigMgr: null
        property var articleData: null
        property var articleDetail: null
        property bool isLoading: false
        property string errorMessage: ""
        property bool feedbackSubmitted: false  // 是否已提交反馈
        property bool feedbackValue: false      // 反馈值 (true=有用, false=无用)
        property bool feedbackLoading: false    // 反馈提交中

        function loadArticle() {
            if (sysConfigMgr && articleData && articleData.id > 0) {
                isLoading = true
                errorMessage = ""
                articleDetail = null
                feedbackSubmitted = false
                feedbackLoading = false
                sysConfigMgr.getKnowledgeArticle(articleData.id)
            }
        }

        function submitFeedback(isHelpful) {
            if (sysConfigMgr && articleData && articleData.id > 0 && !feedbackSubmitted) {
                feedbackLoading = true
                sysConfigMgr.submitKnowledgeFeedback(articleData.id, isHelpful)
            }
        }

        // 将相对路径URL转换为绝对路径（图片和链接）
        function fixRelativeUrls(html, baseUrl) {
            if (!html || !baseUrl) return html

            // 只提取域名部分: https://cp.jingo.cfd
            var match = baseUrl.match(/^(https?:\/\/[^\/]+)/)
            var panelUrl = match ? match[1] : baseUrl

            var result = html

            // 使用函数来判断是否需要转换URL
            function fixUrl(match, attr, quote, url) {
                // 跳过已经是完整URL的（http:// 或 https:// 或 // 开头）
                if (url.indexOf('http://') === 0 || url.indexOf('https://') === 0 || url.indexOf('//') === 0) {
                    return match
                }
                // 跳过锚点链接
                if (url.indexOf('#') === 0) {
                    return match
                }
                // 跳过javascript:
                if (url.indexOf('javascript:') === 0) {
                    return match
                }
                // 跳过mailto:
                if (url.indexOf('mailto:') === 0) {
                    return match
                }
                // 跳过data: URI
                if (url.indexOf('data:') === 0) {
                    return match
                }

                // 相对路径，添加面板URL前缀
                if (url.indexOf('/') === 0) {
                    // 以/开头的绝对路径
                    return attr + '=' + quote + panelUrl + url + quote
                } else {
                    // 不以/开头的相对路径
                    return attr + '=' + quote + panelUrl + '/' + url + quote
                }
            }

            // 修复 src 属性 (双引号和单引号)
            result = result.replace(/(src)="([^"]+)"/g, function(match, attr, url) {
                return fixUrl(match, attr, '"', url)
            })
            result = result.replace(/(src)='([^']+)'/g, function(match, attr, url) {
                return fixUrl(match, attr, "'", url)
            })

            // 修复 href 属性 (双引号和单引号)
            result = result.replace(/(href)="([^"]+)"/g, function(match, attr, url) {
                return fixUrl(match, attr, '"', url)
            })
            result = result.replace(/(href)='([^']+)'/g, function(match, attr, url) {
                return fixUrl(match, attr, "'", url)
            })

            return result
        }

        Connections {
            target: sysConfigMgr

            function onKnowledgeArticleLoaded(article) {
                isLoading = false
                articleDetail = article
            }

            function onKnowledgeArticleFailed(error) {
                isLoading = false
                errorMessage = error
            }

            function onKnowledgeFeedbackSubmitted(articleId, isHelpful) {
                if (articleData && articleData.id === articleId) {
                    feedbackLoading = false
                    feedbackSubmitted = true
                    feedbackValue = isHelpful
                }
            }

            function onKnowledgeFeedbackFailed(error) {
                feedbackLoading = false
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 加载中
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                visible: isLoading

                BusyIndicator {
                    anchors.centerIn: parent
                    running: isLoading
                }
            }

            // 错误提示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.margins: Theme.spacing.md
                radius: Theme.radius.md
                color: Theme.alpha(Theme.colors.error, 0.08)
                border.width: 1
                border.color: Theme.alpha(Theme.colors.error, 0.3)
                visible: errorMessage !== "" && !isLoading

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.md
                    spacing: Theme.spacing.sm

                    Label {
                        text: "⚠"
                        font.pixelSize: 18
                        color: Theme.colors.error
                    }

                    Label {
                        text: errorMessage
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.error
                        Layout.fillWidth: true
                    }
                }
            }

            // 文章内容
            Flickable {
                id: articleFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 0
                visible: !isLoading && errorMessage === ""
                clip: true
                contentWidth: width
                contentHeight: contentColumn.height
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: contentColumn
                    width: articleFlickable.width
                    spacing: Theme.spacing.md

                    // 文章元信息卡片
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: metaCol.height + Theme.spacing.md * 2
                        radius: Theme.radius.md
                        color: Theme.colors.surface
                        border.width: 1
                        border.color: Theme.colors.border

                        ColumnLayout {
                            id: metaCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacing.md
                            spacing: Theme.spacing.sm

                            // 标题
                            Label {
                                text: articleDetail ? articleDetail.title : (articleData ? articleData.title : "")
                                font.pixelSize: Theme.typography.h4
                                font.weight: Theme.typography.weightBold
                                color: Theme.colors.textPrimary
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.colors.divider
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.lg

                                // 分类 - 纯字体图标
                                RowLayout {
                                    spacing: 6
                                    visible: articleDetail && articleDetail.category

                                    Label {
                                        text: "≡"
                                        font.pixelSize: 14
                                        color: Theme.colors.primary
                                    }

                                    Label {
                                        text: articleDetail ? (articleDetail.category || "") : ""
                                        font.pixelSize: Theme.typography.caption
                                        color: Theme.colors.textSecondary
                                    }
                                }

                                // 更新时间 - 纯字体图标
                                RowLayout {
                                    spacing: 6

                                    IconSymbol {
                                        icon: "clock"
                                        size: 14
                                        color: Theme.colors.info
                                    }

                                    Label {
                                        text: formatDate(articleDetail ? (articleDetail.updated_at || articleDetail.created_at) : 0)
                                        font.pixelSize: Theme.typography.caption
                                        color: Theme.colors.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    // 文章正文卡片
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: bodyCol.height + Theme.spacing.lg * 2
                        radius: Theme.radius.md
                        color: Theme.colors.surface
                        border.width: 1
                        border.color: Theme.colors.border

                        ColumnLayout {
                            id: bodyCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacing.lg
                            spacing: Theme.spacing.sm

                            RowLayout {
                                spacing: 8
                                Rectangle {
                                    width: 4
                                    height: 16
                                    radius: 2
                                    color: Theme.colors.primary
                                }
                                Label {
                                    text: qsTr("Article Content")
                                    font.pixelSize: Theme.typography.body2
                                    font.weight: Theme.typography.weightBold
                                    color: Theme.colors.textSecondary
                                }
                            }

                            // 文章内容 - 使用动态组件，支持无限长度和远程图片
                            Item {
                                id: contentContainer
                                Layout.fillWidth: true
                                Layout.preferredHeight: contentCol.height
                                Layout.minimumHeight: 100

                                property var contentSegments: []  // 解析后的内容段落

                                // 解析内容为段落数组（文本和图片分离）
                                function parseContent() {
                                    var content = articleDetail ? articleDetail.body : ""
                                    if (!content) {
                                        contentSegments = []
                                        return
                                    }

                                    var panelUrl = sysConfigMgr ? sysConfigMgr.getPanelDomain() : ""
                                    var segments = []
                                    var lastIndex = 0

                                    // 正则匹配图片: ![alt](url)
                                    var imgRegex = /!\[([^\]]*)\]\(([^)]+)\)/g
                                    var match

                                    while ((match = imgRegex.exec(content)) !== null) {
                                        // 添加图片前的文本
                                        if (match.index > lastIndex) {
                                            var textBefore = content.substring(lastIndex, match.index)
                                            if (textBefore.trim()) {
                                                segments.push({
                                                    type: "text",
                                                    content: textBefore
                                                })
                                            }
                                        }

                                        // 构建完整图片URL
                                        var imgUrl = match[2]
                                        var fullUrl = imgUrl
                                        if (imgUrl.indexOf('http') !== 0 && imgUrl.indexOf('//') !== 0) {
                                            fullUrl = (imgUrl.indexOf('/') === 0) ? (panelUrl + imgUrl) : (panelUrl + '/' + imgUrl)
                                        }

                                        // 添加图片段落
                                        segments.push({
                                            type: "image",
                                            url: fullUrl,
                                            alt: match[1] || qsTr("Image")
                                        })

                                        lastIndex = match.index + match[0].length
                                    }

                                    // 添加最后的文本
                                    if (lastIndex < content.length) {
                                        var remainingText = content.substring(lastIndex)
                                        if (remainingText.trim()) {
                                            segments.push({
                                                type: "text",
                                                content: remainingText
                                            })
                                        }
                                    }
                                    contentSegments = segments
                                }

                                // 将文本转换为HTML
                                function textToHtml(text) {
                                    if (!text) return ""
                                    var html = markdownToHtml(text)
                                    var panelUrl = sysConfigMgr ? sysConfigMgr.getPanelDomain() : ""
                                    html = fixRelativeUrls(html, panelUrl)
                                    return "<div style='color:" + Theme.colors.textPrimary + ";font-size:14px;line-height:1.6;'>" + html + "</div>"
                                }

                                Column {
                                    id: contentCol
                                    width: parent.width
                                    spacing: Theme.spacing.sm

                                    Repeater {
                                        model: contentContainer.contentSegments

                                        Loader {
                                            width: contentCol.width
                                            sourceComponent: modelData.type === "image" ? imageComponent : textComponent
                                            property var segmentData: modelData
                                        }
                                    }
                                }

                                // 文本组件 - 支持选择复制
                                Component {
                                    id: textComponent

                                    TextEdit {
                                        width: parent ? parent.width : 100
                                        height: contentHeight
                                        text: contentContainer.textToHtml(segmentData ? segmentData.content : "")
                                        textFormat: TextEdit.RichText
                                        wrapMode: TextEdit.Wrap
                                        readOnly: true
                                        selectByMouse: true
                                        color: Theme.colors.textPrimary
                                        font.pixelSize: Theme.typography.body2

                                        onLinkActivated: function(link) {
                                            Qt.openUrlExternally(link)
                                        }
                                    }
                                }

                                // 图片组件 - 直接加载远程URL
                                Component {
                                    id: imageComponent

                                    Item {
                                        id: imageItem
                                        width: parent ? parent.width : 100
                                        height: imageLoader.status === Image.Ready ? imageLoader.height : 150

                                        property int retryCount: 0
                                        property int maxRetries: 3
                                        property string imageUrl: segmentData ? segmentData.url : ""

                                        // 重试加载
                                        function retryLoad() {
                                            if (retryCount < maxRetries) {
                                                retryCount++
                                                // 通过添加时间戳参数来强制重新加载
                                                var separator = imageUrl.indexOf('?') >= 0 ? '&' : '?'
                                                imageLoader.source = ""
                                                imageLoader.source = imageUrl + separator + "_retry=" + Date.now()
                                            }
                                        }

                                        // 占位符
                                        Rectangle {
                                            id: placeholderRect
                                            anchors.fill: parent
                                            radius: Theme.radius.md
                                            color: Theme.colors.surfaceElevated
                                            visible: imageLoader.status === Image.Loading || imageLoader.status === Image.Null

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: Theme.spacing.sm

                                                BusyIndicator {
                                                    width: 32
                                                    height: 32
                                                    running: imageLoader.status === Image.Loading
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }

                                                Label {
                                                    text: qsTr("Loading image...")
                                                    font.pixelSize: Theme.typography.caption
                                                    color: Theme.colors.textSecondary
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }

                                                Label {
                                                    text: segmentData ? segmentData.alt : ""
                                                    font.pixelSize: Theme.typography.small
                                                    color: Theme.colors.textTertiary
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    visible: text !== ""
                                                }
                                            }
                                        }

                                        // 实际图片 - 直接使用远程URL
                                        Image {
                                            id: imageLoader
                                            width: parent.width
                                            fillMode: Image.PreserveAspectFit
                                            source: imageItem.imageUrl
                                            asynchronous: true
                                            cache: true

                                            onStatusChanged: {
                                                // 如果加载失败且还有重试次数，自动重试
                                                if (status === Image.Error && imageItem.retryCount < imageItem.maxRetries) {
                                                    retryTimer.start()
                                                }
                                            }

                                            // 延迟重试定时器
                                            Timer {
                                                id: retryTimer
                                                interval: 1000  // 1秒后重试
                                                repeat: false
                                                onTriggered: imageItem.retryLoad()
                                            }

                                            // 加载失败显示错误
                                            Rectangle {
                                                anchors.fill: parent
                                                color: Theme.alpha(Theme.colors.error, 0.1)
                                                radius: Theme.radius.md
                                                visible: imageLoader.status === Image.Error && imageItem.retryCount >= imageItem.maxRetries

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: Theme.spacing.xs

                                                    Label {
                                                        text: "⚠"
                                                        font.pixelSize: 24
                                                        color: Theme.colors.error
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }

                                                    Label {
                                                        text: qsTr("Image load failed")
                                                        font.pixelSize: Theme.typography.caption
                                                        color: Theme.colors.error
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }

                                                    Label {
                                                        text: qsTr("Tap to retry")
                                                        font.pixelSize: Theme.typography.small
                                                        color: Theme.colors.primary
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        imageItem.retryCount = 0
                                                        imageItem.retryLoad()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 监听文章详情变化
                            Connections {
                                target: detailView
                                function onArticleDetailChanged() {
                                    contentContainer.parseContent()
                                }
                            }
                        }
                    }

                    // 反馈卡片 - 点击后隐藏
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        radius: Theme.radius.md
                        color: Theme.colors.surfaceElevated
                        border.width: 1
                        border.color: Theme.colors.border
                        visible: !feedbackSubmitted  // 提交后隐藏整个卡片

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacing.md
                            spacing: Theme.spacing.md

                            Label {
                                text: qsTr("Was this article helpful?")
                                font.pixelSize: Theme.typography.body2
                                color: Theme.colors.textSecondary
                            }

                            Item { Layout.fillWidth: true }

                            // Yes 按钮
                            Rectangle {
                                Layout.preferredWidth: helpfulLabel.width + 32
                                Layout.preferredHeight: 36
                                radius: Theme.radius.md
                                color: helpfulArea.containsMouse ? Theme.alpha(Theme.colors.success, 0.15) : Theme.alpha(Theme.colors.success, 0.08)
                                border.width: 1
                                border.color: Theme.colors.success
                                opacity: feedbackLoading ? 0.5 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Label {
                                        text: "✓"
                                        font.pixelSize: 14
                                        color: Theme.colors.success
                                    }

                                    Label {
                                        id: helpfulLabel
                                        text: qsTr("Yes")
                                        font.pixelSize: Theme.typography.caption
                                        color: Theme.colors.success
                                    }
                                }

                                MouseArea {
                                    id: helpfulArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !feedbackLoading
                                    onClicked: submitFeedback(true)
                                }
                            }

                            // No 按钮
                            Rectangle {
                                Layout.preferredWidth: notHelpfulLabel.width + 32
                                Layout.preferredHeight: 36
                                radius: Theme.radius.md
                                color: notHelpfulArea.containsMouse ? Theme.alpha(Theme.colors.error, 0.15) : Theme.alpha(Theme.colors.error, 0.08)
                                border.width: 1
                                border.color: Theme.colors.error
                                opacity: feedbackLoading ? 0.5 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Label {
                                        text: "×"
                                        font.pixelSize: 14
                                        color: Theme.colors.error
                                    }

                                    Label {
                                        id: notHelpfulLabel
                                        text: qsTr("No")
                                        font.pixelSize: Theme.typography.caption
                                        color: Theme.colors.error
                                    }
                                }

                                MouseArea {
                                    id: notHelpfulArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !feedbackLoading
                                    onClicked: submitFeedback(false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
