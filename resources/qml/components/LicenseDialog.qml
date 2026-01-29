import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: licenseDialog

    visible: false
    modal: true
    focus: true

    width: Math.min(600, parent.width - 40)
    height: Math.min(500, parent.height - 40)
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    title: qsTr("Open Source Licenses")

    property bool isDarkMode: typeof Theme !== 'undefined' ? Theme.isDarkMode : false

    contentItem: ColumnLayout {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 16

        // License selector
        ComboBox {
            id: licenseSelector
            Layout.fillWidth: true
            model: [
                "JinGo VPN - GPL v3",
                "Xray-core - MPL 2.0",
                "Qt Framework - LGPL v3",
                "OpenSSL - Apache 2.0"
            ]
            currentIndex: 0
            onCurrentIndexChanged: {
                licenseText.text = getLicenseText(currentIndex)
            }
        }

        // License text area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: licenseText
                readOnly: true
                wrapMode: TextArea.Wrap
                font.family: "monospace"
                font.pixelSize: 11
                color: isDarkMode ? "#E0E0E0" : "#333333"
                background: Rectangle {
                    color: isDarkMode ? "#2A2520" : "#F5F5F5"
                    radius: 4
                }
                text: getLicenseText(0)
            }
        }

        // Project links
        Label {
            text: qsTr("Project Links:")
            font.bold: true
            color: isDarkMode ? "#E0E0E0" : "#333333"
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "GitHub: Xray-core"
                flat: true
                font.pixelSize: 12
                onClicked: Qt.openUrlExternally("https://github.com/XTLS/Xray-core")
            }
            Button {
                text: "Qt Project"
                flat: true
                font.pixelSize: 12
                onClicked: Qt.openUrlExternally("https://www.qt.io/licensing/open-source-lgpl-obligations")
            }
        }
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Close
        onRejected: licenseDialog.close()
    }

    function getLicenseText(index) {
        switch(index) {
            case 0: // JinGo VPN GPL v3
                return qsTr("JinGo VPN - GNU General Public License v3.0\n\n" +
"Copyright (C) 2024-2025 JinGo Team\n\n" +
"This program is free software: you can redistribute it and/or modify\n" +
"it under the terms of the GNU General Public License as published by\n" +
"the Free Software Foundation, either version 3 of the License, or\n" +
"(at your option) any later version.\n\n" +
"This program is distributed in the hope that it will be useful,\n" +
"but WITHOUT ANY WARRANTY; without even the implied warranty of\n" +
"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n" +
"GNU General Public License for more details.\n\n" +
"You should have received a copy of the GNU General Public License\n" +
"along with this program. If not, see <https://www.gnu.org/licenses/>.\n\n" +
"---\n\n" +
"Third-party components:\n" +
"- Xray-core: Mozilla Public License 2.0\n" +
"- Qt Framework: LGPL v3\n" +
"- OpenSSL: Apache License 2.0\n")

            case 1: // Xray-core MPL 2.0
                return "Xray-core - Mozilla Public License 2.0\n\n" +
"Copyright (C) 2020-2025 XTLS Contributors\n\n" +
"This Source Code Form is subject to the terms of the Mozilla Public\n" +
"License, v. 2.0. If a copy of the MPL was not distributed with this\n" +
"file, You can obtain one at https://mozilla.org/MPL/2.0/.\n\n" +
"Project Xray-core is a set of network tools that help you to build\n" +
"your own computer network. It secures your network connections and\n" +
"protects your privacy.\n\n" +
"Main features:\n" +
"- Multiple inbound/outbound proxies: Socks, HTTP, Shadowsocks,\n" +
"  VMess, VLESS, Trojan, etc.\n" +
"- Flexible routing configuration\n" +
"- Multiple transport protocols: TCP, mKCP, WebSocket, HTTP/2, QUIC,\n" +
"  gRPC, Reality, etc.\n" +
"- Built-in DNS server with DoH/DoT support\n\n" +
"Source: https://github.com/XTLS/Xray-core"

            case 2: // Qt LGPL v3
                return "Qt Framework - GNU Lesser General Public License v3.0\n\n" +
"Copyright (C) 2024 The Qt Company Ltd.\n\n" +
"Qt is available under the GNU Lesser General Public License version 3.\n\n" +
"The Qt Toolkit is Copyright (C) The Qt Company Ltd. and other contributors.\n" +
"Contact: https://www.qt.io/licensing/\n\n" +
"You may use, distribute and copy the Qt GUI Toolkit under the terms of\n" +
"GNU Lesser General Public License version 3, which is displayed below.\n" +
"This license makes reference to the version 3 of the GNU General\n" +
"Public License.\n\n" +
"GNU LESSER GENERAL PUBLIC LICENSE\n" +
"Version 3, 29 June 2007\n\n" +
"Everyone is permitted to copy and distribute verbatim copies\n" +
"of this license document, but changing it is not allowed.\n\n" +
"This version of the GNU Lesser General Public License incorporates\n" +
"the terms and conditions of version 3 of the GNU General Public\n" +
"License, supplemented by the additional permissions listed below.\n\n" +
"Source: https://www.qt.io/licensing/open-source-lgpl-obligations"

            case 3: // OpenSSL Apache 2.0
                return "OpenSSL - Apache License 2.0\n\n" +
"Copyright (C) 1998-2024 The OpenSSL Project Authors\n" +
"Copyright (C) 1995-1998 Eric A. Young, Tim J. Hudson\n\n" +
"Licensed under the Apache License, Version 2.0 (the \"License\");\n" +
"you may not use this file except in compliance with the License.\n" +
"You may obtain a copy of the License at\n\n" +
"    https://www.apache.org/licenses/LICENSE-2.0\n\n" +
"Unless required by applicable law or agreed to in writing, software\n" +
"distributed under the License is distributed on an \"AS IS\" BASIS,\n" +
"WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n" +
"See the License for the specific language governing permissions and\n" +
"limitations under the License.\n\n" +
"OpenSSL is a robust, commercial-grade, full-featured Open Source\n" +
"Toolkit for the Transport Layer Security (TLS) protocol formerly\n" +
"known as the Secure Sockets Layer (SSL) protocol.\n\n" +
"Source: https://www.openssl.org/"

            default:
                return ""
        }
    }
}
