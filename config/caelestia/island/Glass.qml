pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    property bool elevated: true
    property bool outlined: true
    radius: Tokens.radius
    color: Tokens.surface
    border.width: outlined ? Tokens.borderWidth : 0
    border.color: Tokens.border
    // Shadow is a separate primitive: never rasterize the text/control subtree.
    // Material depth comes from the backdrop and edge, not a painted fill gradient.
    RectangularShadow {
        anchors.fill: parent
        z: -1
        radius: root.radius
        blur: Tokens.shadowBlur
        color: Qt.alpha(Tokens.shadow, Tokens.shadowOpacity)
        offset: Qt.vector2d(0, Tokens.shadowOffset)
        visible: root.elevated
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 0.5
        border.color: "#08ffffff"
        visible: root.outlined
    }
}
