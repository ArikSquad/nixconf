pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Button {
    id: root
    property bool selected: false
    implicitHeight: Tokens.controlHeight
    implicitWidth: Math.max(Tokens.controlHeight, contentItem.implicitWidth + Tokens.padding)
    hoverEnabled: true
    Accessible.name: text
    contentItem: GlassLabel {
        text: root.text
        color: !root.enabled ? Tokens.secondary : root.selected ? Tokens.accent : Tokens.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Tokens.caption
    }
    background: Rectangle {
        radius: Tokens.controlRadius
        color: root.down ? Tokens.pressed : root.selected ? Tokens.selected : root.hovered ? Tokens.hover : Tokens.control
        border.width: root.activeFocus ? Tokens.borderWidth : 0
        border.color: Tokens.accent
        Behavior on color {
            ColorAnimation {
                duration: Tokens.fast
            }
        }
    }
}
