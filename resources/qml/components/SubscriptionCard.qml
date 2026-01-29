// components/SubscriptionCard.qml (套餐卡片组件 - 现代风格)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

BaseCard {
    id: subscriptionCard

    // 获取主窗口引用以判断移动端
    readonly property var mainWindow: Qt.application.topLevelWindow || null
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios" ||
                                     (mainWindow ? mainWindow.width < 768 : false)

    // 套餐属性
    property string planName: ""
    property string planId: ""
    property string price: ""
    property string currency: "¥"
    property string duration: ""
    property string originalPrice: ""  // 原价（用于显示折扣）
    property var features: []  // 特性列表
    property int dataLimit: 0  // 流量限制 (GB)，0表示无限
    property int deviceLimit: 5  // 设备数限制
    property string speed: ""  // 速度描述
    property bool isRecommended: false  // 是否推荐
    property bool isPopular: false  // 是否热门
    property bool isPurchasing: false  // 购买中状态
    property bool isPurchased: false  // 已购买

    // 信号
    signal purchaseClicked()

    // 样式
    padding: 0
    elevation: "md"
    hoverable: true

    // 推荐/热门/已购买套餐添加边框高亮
    borderWidth: (isRecommended || isPopular || isPurchased) ? 2 : 1
    borderColor: isPurchased ? Theme.colors.success :
                 ((isRecommended || isPopular) ? Theme.colors.primary : Theme.colors.border)

    contentItem: ColumnLayout {
        spacing: 0

        // 顶部标签（推荐/热门/已购买）
        Rectangle {
            visible: isRecommended || isPopular || isPurchased
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: isPurchased ? Theme.colors.success :
                   (isRecommended ? Theme.colors.primary : Theme.colors.warning)
            radius: Theme.radius.md

            // 只有顶部圆角
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.radius.md
                color: parent.color
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                // 现代风格图标（使用简洁的Unicode符号）
                Text {
                    text: isPurchased ? "✓" : (isRecommended ? "★" : "●")
                    font.pixelSize: isPurchased ? 14 : 12
                    font.weight: Font.Bold
                    color: "white"
                }

                Label {
                    text: isPurchased ? qsTr("Purchased") :
                          (isRecommended ? qsTr("Recommended") : qsTr("Popular"))
                    font.pixelSize: Theme.typography.caption
                    font.weight: Theme.typography.weightBold
                    color: "white"
                }
            }
        }

        // 卡片主体内容
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.sm
            Layout.rightMargin: Theme.spacing.sm
            Layout.topMargin: Theme.spacing.sm
            Layout.bottomMargin: Theme.spacing.sm
            spacing: 8

            // 套餐名称
            Label {
                text: subscriptionCard.planName
                font.pixelSize: Theme.typography.body1
                font.weight: Theme.typography.weightBold
                color: Theme.colors.textPrimary
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            // 价格区域
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.topMargin: 4

                // 原价（如果有折扣）
                Label {
                    visible: subscriptionCard.originalPrice !== ""
                    text: subscriptionCard.currency + subscriptionCard.originalPrice
                    font.pixelSize: Theme.typography.caption
                    color: Theme.colors.textTertiary
                    font.strikeout: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // 当前价格
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    Label {
                        text: subscriptionCard.currency
                        font.pixelSize: 18
                        font.weight: Theme.typography.weightBold
                        color: Theme.colors.primary
                    }

                    Label {
                        text: subscriptionCard.price
                        font.pixelSize: 32
                        font.weight: Theme.typography.weightBold
                        color: Theme.colors.primary
                    }

                    Label {
                        text: " / " + subscriptionCard.duration
                        font.pixelSize: 12
                        color: Theme.colors.textSecondary
                        Layout.alignment: Qt.AlignBaseline
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                height: 1
                color: Theme.colors.divider
            }

            // 特性列表 - 纯字体图标风格（带标签说明）
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                // 流量
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    IconSymbol {
                        icon: "traffic"
                        size: 14
                        color: Theme.colors.info
                        Layout.preferredWidth: 18
                    }

                    Label {
                        text: qsTr("Traffic:")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: subscriptionCard.dataLimit > 0 ?
                              qsTr("%1 GB").arg(subscriptionCard.dataLimit) :
                              qsTr("Unlimited")
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                        Layout.fillWidth: true
                    }
                }

                // 设备数
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    IconSymbol {
                        icon: "device"
                        size: 14
                        color: Theme.colors.success
                        Layout.preferredWidth: 18
                    }

                    Label {
                        text: qsTr("Devices:")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: qsTr("%1 online").arg(subscriptionCard.deviceLimit)
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                    }
                }

                // 速度
                RowLayout {
                    visible: subscriptionCard.speed !== ""
                    Layout.fillWidth: true
                    spacing: 8

                    IconSymbol {
                        icon: "speed"
                        size: 16
                        color: Theme.colors.warning
                        Layout.preferredWidth: 18
                    }

                    Label {
                        text: qsTr("Speed:")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }

                    Label {
                        text: subscriptionCard.speed
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.textPrimary
                    }
                }

                // 其他特性（限制显示前2个）
                Repeater {
                    model: {
                        if (!subscriptionCard.features || subscriptionCard.features.length === 0) {
                            return []
                        }
                        var featuresArray = []
                        for (var i = 0; i < subscriptionCard.features.length; i++) {
                            featuresArray.push(subscriptionCard.features[i])
                        }
                        var validFeatures = []
                        for (var j = 0; j < featuresArray.length; j++) {
                            var f = featuresArray[j]
                            if (f !== undefined && f !== null && f !== "") {
                                validFeatures.push(f)
                            }
                        }
                        return validFeatures.length > 2 ? validFeatures.slice(0, 2) : validFeatures
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "✓"
                            font.pixelSize: 14
                            color: Theme.colors.primary
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Label {
                            text: modelData || ""
                            font.pixelSize: Theme.typography.body2
                            color: Theme.colors.textPrimary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // 占位符
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 8
            }

            // 购买/续费按钮 - 现代风格
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: isMobile ? 44 : 40
                Layout.minimumHeight: Theme.size.touchTarget
                radius: Theme.radius.md

                // 渐变背景
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: subscriptionCard.isPurchasing ? Theme.colors.textTertiary :
                               (subscriptionCard.isRecommended ? Theme.colors.primary : Theme.colors.warning)
                    }
                    GradientStop {
                        position: 1.0
                        color: subscriptionCard.isPurchasing ? Theme.colors.textDisabled :
                               (subscriptionCard.isRecommended ? Qt.darker(Theme.colors.primary, 1.1) : Qt.darker(Theme.colors.warning, 1.1))
                    }
                }

                opacity: subscriptionCard.isPurchasing ? 0.6 : (buttonArea.containsMouse ? 0.9 : 1.0)
                scale: buttonArea.pressed ? 0.98 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Label {
                    anchors.centerIn: parent
                    text: {
                        if (subscriptionCard.isPurchased) return qsTr("Renew")
                        if (subscriptionCard.isPurchasing) return qsTr("Processing...")
                        return qsTr("Subscribe")
                    }
                    font.pixelSize: Theme.typography.body2
                    font.weight: Font.Bold
                    color: "white"
                }

                MouseArea {
                    id: buttonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !subscriptionCard.isPurchasing
                    onClicked: subscriptionCard.purchaseClicked()
                }
            }
        }
    }
}
