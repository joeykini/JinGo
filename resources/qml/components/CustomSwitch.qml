// components/CustomSwitch.qml - Switch with orange indicator
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Templates 2.15 as T

T.Switch {
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
        implicitWidth: 48
        implicitHeight: 26
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding) : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 13
        color: control.checked ? Theme.colors.warning : (isDarkMode ? "#4A4A4A" : "#E0E0E0")
        border.width: 0

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, control.visualPosition * parent.width - (width / 2)))
            y: (parent.height - height) / 2
            width: 22
            height: 22
            radius: 11
            color: Theme.colors.textPrimary
            border.color: control.checked ? Theme.colors.warning : (isDarkMode ? "#666666" : "#BDBDBD")
            border.width: 1

            Behavior on x {
                enabled: !control.pressed
                SmoothedAnimation { velocity: 200 }
            }

            Behavior on border.color {
                ColorAnimation { duration: 150 }
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
