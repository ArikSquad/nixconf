pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Button {
    id: root
    required property string symbol
    property bool selected: false
    implicitHeight: 52
    hoverEnabled: true
    Accessible.name: text
    contentItem: Column {
        spacing: 5
        Symbol {
            name: root.symbol
            color: root.selected ? Tokens.text : Tokens.secondary
            anchors.horizontalCenter: parent.horizontalCenter
        }
        GlassLabel {
            text: root.text
            color: root.selected ? Tokens.text : Tokens.secondary
            font.pixelSize: 10
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    background: Rectangle {
        radius: Tokens.controlRadius
        color: root.down ? Tokens.pressed : root.selected ? "#28ffffff" : root.hovered ? Tokens.hover : "transparent"
        border.width: root.selected || root.activeFocus ? 0.5 : 0
        border.color: root.activeFocus ? Tokens.accent : "#14ffffff"
        scale: root.down ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: Tokens.fast; easing.type: Easing.OutCubic } }
        Behavior on color {
            ColorAnimation {
                duration: Tokens.fast
            }
        }
    }
}
