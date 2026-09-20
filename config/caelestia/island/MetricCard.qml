pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property string label
    required property string valueText
    property string detail: ""
    property real value: 0
    property color accent: Tokens.accent
    property var history: []

    implicitHeight: history.length > 1 ? 116 : 86
    radius: Tokens.controlRadius + 4
    color: Tokens.control
    border.width: Tokens.borderWidth
    border.color: Tokens.separator

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            GlassLabel { text: root.label; color: Tokens.secondary; font.pixelSize: Tokens.caption; Layout.fillWidth: true }
            GlassLabel { text: root.valueText; font.weight: Tokens.semibold; font.pixelSize: Tokens.body }
        }
        GlassLabel {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.detail
            color: Tokens.tertiary
            font.pixelSize: 10
        }
        Sparkline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.history.length > 1
            values: root.history
            lineColor: root.accent
        }
        Level {
            Layout.fillWidth: true
            visible: root.history.length < 2
            value: root.value
        }
    }
}
