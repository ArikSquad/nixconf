pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Slider {
    id: root
    from: 0
    to: 1
    implicitHeight: Tokens.controlHeight
    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: Tokens.small
        radius: height / 2
        color: Tokens.control
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Tokens.accent
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        width: Tokens.padding
        height: width
        radius: width / 2
        color: Tokens.text
        border.width: root.activeFocus ? 2 : 0
        border.color: Tokens.accent
    }
}
