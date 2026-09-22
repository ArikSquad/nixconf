pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root
    property real value: 0
    implicitHeight: Tokens.small
    radius: height / 2
    color: Tokens.control
    Rectangle {
        width: root.width * (isNaN(root.value) ? 0 : Math.max(0, Math.min(1, root.value)))
        height: parent.height
        radius: parent.radius
        color: Tokens.text
        Behavior on width {
            NumberAnimation {
                duration: Tokens.duration
                easing.type: Tokens.easing
            }
        }
    }
}
