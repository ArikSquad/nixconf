pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var notification
    property var heldNotification: null
    function holdCurrent() {
        if (heldNotification === notification)
            return;
        const previous = heldNotification;
        heldNotification = notification;
        if (heldNotification)
            heldNotification.lock(root);
        if (previous)
            previous.unlock(root);
    }
    onNotificationChanged: holdCurrent()
    Component.onCompleted: holdCurrent()
    Component.onDestruction: {
        if (heldNotification) {
            if (!heldNotification.closed)
                heldNotification.timer.restart();
            heldNotification.unlock(root);
        }
    }
    signal dismissed
    implicitHeight: column.implicitHeight
    ColumnLayout {
        id: column
        width: parent.width
        spacing: Tokens.gap
        RowLayout {
            Layout.fillWidth: true
            GlassLabel {
                text: root.notification?.appName || "Notification"
                color: Tokens.secondary
                font.pixelSize: Tokens.caption
                Layout.fillWidth: true
            }
            GlassLabel {
                text: root.notification?.timeStr ?? "now"
                color: Tokens.secondary
                font.pixelSize: Tokens.caption
            }
        }
        GlassLabel {
            text: root.notification?.summary ?? ""
            font.pixelSize: Tokens.clock
            font.weight: Tokens.semibold
            Layout.fillWidth: true
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
        GlassLabel {
            text: (root.notification?.body ?? "").replace(/<[^>]*>/g, "")
            color: Tokens.secondary
            Layout.fillWidth: true
            maximumLineCount: 4
            wrapMode: Text.Wrap
        }
        Flow {
            Layout.fillWidth: true
            spacing: Tokens.small
            Repeater {
                model: root.notification?.actions ?? []
                GlassButton {
                    required property var modelData
                    text: modelData.text
                    selected: index === 0
                    onClicked: modelData.invoke()
                }
            }
        }
    }
    HoverHandler {
        onHoveredChanged: {
            if (!root.notification)
                return;
            if (hovered)
                root.notification.timer.stop();
            else
                root.notification.timer.restart();
        }
    }
}
