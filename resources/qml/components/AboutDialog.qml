import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import JinGo 1.0

Dialog {
    id: aboutDialog

    visible: false
    modal: true
    focus: true

    width: 420
    height: 380
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    title: qsTr("About JinGo")

    property bool isDarkMode: typeof Theme !== 'undefined' ? Theme.isDarkMode : false
    property string appVersion: "1.0.0"

    // License dialog instance
    LicenseDialog {
        id: licenseDialog
        parent: Overlay.overlay
    }

    contentItem: ColumnLayout {
        spacing: 12
        anchors.fill: parent
        anchors.margins: 20

        // App Icon
        Image {
            source: "qrc:/icons/app.png"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignHCenter
            fillMode: Image.PreserveAspectFit
        }

        Label {
            text: qsTr("JinGo Client")
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            color: isDarkMode ? "#FFFFFF" : "#333333"
        }

        Label {
            text: qsTr("Version") + ": " + appVersion
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
            color: isDarkMode ? "#CCCCCC" : "#666666"
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: isDarkMode ? "#444444" : "#E0E0E0"
            Layout.topMargin: 8
            Layout.bottomMargin: 8
        }

        Label {
            text: qsTr("Powered by")
            font.pixelSize: 12
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            color: isDarkMode ? "#AAAAAA" : "#888888"
        }

        Label {
            text: "Xray-core, Qt/QML, OpenSSL"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
            color: isDarkMode ? "#888888" : "#666666"
        }

        Item { Layout.fillHeight: true }

        // Buttons row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Button {
                text: qsTr("Open Source Licenses")
                flat: true
                font.pixelSize: 12
                onClicked: licenseDialog.open()
            }

            Button {
                text: qsTr("Website")
                flat: true
                font.pixelSize: 12
                onClicked: {
                    if (bundleConfig && bundleConfig.termsOfServiceUrl) {
                        var url = bundleConfig.termsOfServiceUrl.replace("/terms", "")
                        Qt.openUrlExternally(url)
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        Label {
            text: qsTr("Copyright") + " © 2024-2025 JinGo Team."
            font.pixelSize: 10
            color: isDarkMode ? "#777777" : "#AAAAAA"
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: qsTr("All rights reserved.")
            font.pixelSize: 10
            color: isDarkMode ? "#777777" : "#AAAAAA"
            Layout.alignment: Qt.AlignHCenter
        }
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok
        onAccepted: aboutDialog.close()
    }
}
