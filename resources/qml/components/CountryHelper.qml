// CountryHelper.qml - 国家/地区辅助工具（单例）
pragma Singleton
import QtQuick 2.15

QtObject {
    id: root

    /**
     * 获取大洲的本地化名称
     * @param continent 大洲名称（可能是中文、英文等）
     * @return 本地化后的大洲名称
     */
    function getContinentName(continent) {
        if (!continent) return qsTr("Unknown")

        var continentLower = continent.toLowerCase()

        // 亚洲
        if (continentLower.indexOf("asia") >= 0 || continentLower.indexOf("亚洲") >= 0) {
            return qsTr("Asia")
        }
        // 欧洲
        if (continentLower.indexOf("europe") >= 0 || continentLower.indexOf("欧洲") >= 0) {
            return qsTr("Europe")
        }
        // 北美洲
        if (continentLower.indexOf("north america") >= 0 || continentLower.indexOf("北美") >= 0) {
            return qsTr("North America")
        }
        // 南美洲
        if (continentLower.indexOf("south america") >= 0 || continentLower.indexOf("南美") >= 0) {
            return qsTr("South America")
        }
        // 非洲
        if (continentLower.indexOf("africa") >= 0 || continentLower.indexOf("非洲") >= 0) {
            return qsTr("Africa")
        }
        // 大洋洲
        if (continentLower.indexOf("oceania") >= 0 || continentLower.indexOf("大洋洲") >= 0 ||
            continentLower.indexOf("australia") >= 0 || continentLower.indexOf("澳洲") >= 0) {
            return qsTr("Oceania")
        }
        // 南极洲
        if (continentLower.indexOf("antarctica") >= 0 || continentLower.indexOf("南极") >= 0) {
            return qsTr("Antarctica")
        }

        // 未知大洲，返回原始名称
        return continent
    }

    /**
     * 获取大洲图标
     * @param continent 大洲名称
     * @return 图标文字
     */
    function getContinentIcon(continent) {
        if (!continent) return "🌐"

        var continentLower = continent.toLowerCase()

        // 亚洲 - Asia
        if (continentLower.indexOf("asia") >= 0 || continentLower.indexOf("亚洲") >= 0) {
            return "🌏"
        }
        // 欧洲 - Europe
        if (continentLower.indexOf("europe") >= 0 || continentLower.indexOf("欧洲") >= 0) {
            return "🌍"
        }
        // 北美洲 - North America
        if (continentLower.indexOf("north america") >= 0 || continentLower.indexOf("北美") >= 0) {
            return "🌎"
        }
        // 南美洲 - South America
        if (continentLower.indexOf("south america") >= 0 || continentLower.indexOf("南美") >= 0) {
            return "🗺️"
        }
        // 非洲 - Africa
        if (continentLower.indexOf("africa") >= 0 || continentLower.indexOf("非洲") >= 0) {
            return "🌍"
        }
        // 大洋洲 - Oceania
        if (continentLower.indexOf("oceania") >= 0 || continentLower.indexOf("大洋洲") >= 0 ||
            continentLower.indexOf("australia") >= 0 || continentLower.indexOf("澳洲") >= 0) {
            return "🌏"
        }
        // 南极洲 - Antarctica
        if (continentLower.indexOf("antarctica") >= 0 || continentLower.indexOf("南极") >= 0) {
            return "🧊"
        }

        return "🌐"
    }

    /**
     * 获取国家旗帜 emoji
     * @param countryCode 国家代码（ISO 3166-1 alpha-2）
     * @return 旗帜 emoji
     */
    function getCountryFlag(countryCode) {
        if (!countryCode || countryCode.length !== 2) {
            return "🏳️"
        }

        // 将国家代码转换为 Unicode 区域指示符号
        // 例如: CN -> 🇨🇳
        var code = countryCode.toUpperCase()
        var codePoints = []
        for (var i = 0; i < code.length; i++) {
            // 区域指示符号的 Unicode 范围是 0x1F1E6-0x1F1FF
            // 对应 A-Z (0x41-0x5A)
            codePoints.push(0x1F1E6 + (code.charCodeAt(i) - 0x41))
        }

        return String.fromCodePoint(codePoints[0], codePoints[1])
    }

    /**
     * 获取国家名称（本地化）
     * @param countryCode 国家代码
     * @return 国家名称
     */
    function getCountryName(countryCode) {
        var countries = {
            "US": qsTr("United States"),
            "GB": qsTr("United Kingdom"),
            "CN": qsTr("China"),
            "JP": qsTr("Japan"),
            "KR": qsTr("South Korea"),
            "HK": qsTr("Hong Kong"),
            "TW": qsTr("Taiwan"),
            "SG": qsTr("Singapore"),
            "DE": qsTr("Germany"),
            "FR": qsTr("France"),
            "CA": qsTr("Canada"),
            "AU": qsTr("Australia"),
            "RU": qsTr("Russia"),
            "IN": qsTr("India"),
            "BR": qsTr("Brazil"),
            "NL": qsTr("Netherlands"),
            "SE": qsTr("Sweden"),
            "CH": qsTr("Switzerland"),
            "IT": qsTr("Italy"),
            "ES": qsTr("Spain"),
            "VN": qsTr("Vietnam"),
            "KH": qsTr("Cambodia"),
            "MM": qsTr("Myanmar"),
            "IR": qsTr("Iran")
        }

        return countries[countryCode] || countryCode
    }
}
