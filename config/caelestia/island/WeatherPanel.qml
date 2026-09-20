pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root

    function glyph(code) {
        const n = Number(code);
        if (n <= 1)
            return "☀";
        if (n <= 3)
            return "◒";
        if (n === 45 || n === 48)
            return "≋";
        if ((n >= 51 && n <= 67) || (n >= 80 && n <= 82))
            return "☂";
        if ((n >= 71 && n <= 77) || n >= 85 && n <= 86)
            return "✣";
        if (n >= 95)
            return "ϟ";
        return "☁";
    }

    spacing: Tokens.gap

    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            GlassLabel { text: Weather.city || "Weather"; font.pixelSize: Tokens.title; font.weight: Tokens.semibold }
            GlassLabel { text: Weather.description; color: Tokens.secondary; font.pixelSize: Tokens.caption }
        }
        GlassLabel { text: root.glyph(Weather.cc?.weatherCode); font.pixelSize: 32; color: Tokens.text }
        GlassLabel { text: Weather.temp; font.pixelSize: 30; font.weight: Font.Light }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: conditions.implicitHeight + 24
        radius: Tokens.controlRadius + 4
        color: Tokens.control
        RowLayout {
            id: conditions
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16
            ColumnLayout {
                Layout.fillWidth: true
                GlassLabel { text: "FEELS LIKE"; color: Tokens.tertiary; font.pixelSize: 9 }
                GlassLabel { text: Weather.feelsLike; font.weight: Tokens.semibold }
            }
            ColumnLayout {
                Layout.fillWidth: true
                GlassLabel { text: "HUMIDITY"; color: Tokens.tertiary; font.pixelSize: 9 }
                GlassLabel { text: Weather.humidity + "%"; font.weight: Tokens.semibold }
            }
            ColumnLayout {
                Layout.fillWidth: true
                GlassLabel { text: "WIND"; color: Tokens.tertiary; font.pixelSize: 9 }
                GlassLabel { text: Math.round(Weather.windSpeed) + " km/h"; font.weight: Tokens.semibold }
            }
        }
    }

    GlassLabel { text: "NEXT HOURS"; color: Tokens.tertiary; font.pixelSize: 10; font.weight: Tokens.semibold }
    RowLayout {
        Layout.fillWidth: true
        spacing: 3
        Repeater {
            model: Weather.hourlyForecast.slice(0, 5)
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 86
                radius: Tokens.controlRadius
                color: Tokens.control
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    GlassLabel { Layout.alignment: Qt.AlignHCenter; text: modelData.hour.toString().padStart(2, "0") + ":00"; color: Tokens.secondary; font.pixelSize: 10 }
                    GlassLabel { Layout.alignment: Qt.AlignHCenter; text: root.glyph(modelData.weatherCode); font.pixelSize: 18 }
                    GlassLabel { Layout.alignment: Qt.AlignHCenter; text: Weather.formatTemp(modelData.tempC, true); font.weight: Tokens.semibold; font.pixelSize: Tokens.caption }
                }
            }
        }
    }

    GlassLabel { text: "5-DAY FORECAST"; color: Tokens.tertiary; font.pixelSize: 10; font.weight: Tokens.semibold }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Repeater {
            model: Weather.forecast.slice(0, 5)
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 28
                GlassLabel { Layout.preferredWidth: 72; text: Qt.formatDate(new Date(modelData.date), "ddd"); color: Tokens.secondary }
                GlassLabel { text: root.glyph(modelData.weatherCode); font.pixelSize: 17 }
                Item { Layout.fillWidth: true }
                GlassLabel { text: Weather.formatTemp(modelData.minTempC, true); color: Tokens.tertiary }
                Level { Layout.preferredWidth: 76; value: (modelData.maxTempC + 25) / 65 }
                GlassLabel { text: Weather.formatTemp(modelData.maxTempC, true); font.weight: Tokens.semibold }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !Weather.cc
        GlassLabel { text: "Weather is unavailable"; font.weight: Tokens.semibold }
        GlassLabel { Layout.fillWidth: true; text: "Set a location in Caelestia settings or check the network connection."; color: Tokens.secondary; wrapMode: Text.Wrap }
        GlassButton { text: "Try again"; onClicked: Weather.reload() }
    }
}
