// components/CustomRadioButton.qml - RadioButton with orange indicator
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Templates 2.15 as T

T.RadioButton {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6

    readonly property bool isDarkMode: {
        var mainWindow = Qt.application.topLevelWindow
        return mainWindow ? mainWindow.isDarkMode : false
    }

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding) : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 10
        border.width: 2
        border.color: control.checked ? Theme.colors.warning : (isDarkMode ? "#666666" : "#BDBDBD")
        color: "transparent"

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: 5
            color: Theme.colors.warning
            visible: control.checked
            scale: control.checked ? 1 : 0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
    }

    contentItem: Text {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0

        text: control.text
        font: control.font
        color: Theme.colors.textPrimary
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
