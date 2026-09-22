pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: root
    required property var controller
    readonly property var monitor: Brightness.getMonitorForScreen(screen)
    readonly property var screenState: ShellState.forScreen(screen)
    readonly property bool mediaAvailable: !!Players.active?.trackTitle
    readonly property bool expanded: controller.expanded && !(controller.mode === "media" && !root.mediaAvailable) && screen.name === (Hypr.focusedMonitor?.name ?? Quickshell.screens[0]?.name)
    readonly property int targetHeight: Math.ceil(content.implicitHeight + Tokens.padding * 2)
    readonly property int compactSurfaceWidth: Math.max(96, Math.min(224, compactContent.implicitWidth + 20))
    color: "transparent"
    anchors.top: true
    implicitWidth: Math.min(screen.width, Tokens.expandedWidth + Tokens.padding * 2)
    implicitHeight: Math.min(screen.height, 680)
    exclusiveZone: Tokens.compactHeight + Tokens.topMargin
    WlrLayershell.namespace: "caelestia-island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.expanded && controller.page !== "idle" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region {
        item: surface
        radius: surface.radius
    }
    HyprlandFocusGrab {
        active: root.expanded && root.controller.page !== "idle"
        windows: [root]
        onCleared: root.controller.dismiss()
    }
    Connections {
        target: root.monitor
        function onBrightnessChanged() {
            root.controller.pulse("brightness");
        }
    }
    Connections {
        target: root.screenState
        function onDashboardChanged() {
            if (root.screenState.dashboard) {
                root.controller.open("overview");
                root.screenState.dashboard = false;
            }
        }
        function onUtilitiesChanged() {
            if (root.screenState.utilities) {
                root.controller.open("controls");
                root.screenState.utilities = false;
            }
        }
        function onSessionChanged() {
            if (root.screenState.session) {
                root.controller.open("system");
                root.screenState.session = false;
            }
        }
    }
    Glass {
        id: surface
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.topMargin
        width: root.expanded ? Math.min(Tokens.expandedWidth, root.width - Tokens.padding) : root.compactSurfaceWidth
        height: root.expanded ? Math.min(root.screen.height - 88, root.targetHeight) : Tokens.compactHeight
        radius: root.expanded ? Tokens.radius : Tokens.compactHeight / 2
        Behavior on width {
            NumberAnimation { duration: Tokens.morph; easing.type: Tokens.morphEasing }
        }
        Behavior on height {
            NumberAnimation { duration: Tokens.morph; easing.type: Tokens.morphEasing }
        }
        Behavior on radius {
            NumberAnimation {
                duration: Tokens.duration
                easing.type: Tokens.easing
            }
        }
        Item {
            anchors.fill: parent
            opacity: root.expanded ? 0 : 1
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.fast
                }
            }
            Row {
                id: compactContent
                anchors.centerIn: parent
                height: parent.height
                spacing: 7
                GlassLabel {
                    text: Time.format("HH:mm")
                    font.pixelSize: Tokens.clock
                    font.weight: Tokens.semibold
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    visible: root.controller.deadline > 0
                    width: 1
                    height: 14
                    color: Tokens.separator
                    anchors.verticalCenter: parent.verticalCenter
                }
                GlassLabel {
                    visible: root.controller.deadline > 0
                    text: "◷"
                    color: Tokens.amber
                    font.pixelSize: 15
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
                GlassLabel {
                    visible: root.controller.deadline > 0
                    text: Math.floor(root.controller.secondsLeft / 60).toString().padStart(2, "0") + ":" + (root.controller.secondsLeft % 60).toString().padStart(2, "0")
                    color: Tokens.amber
                    font.pixelSize: Tokens.caption
                    font.weight: Tokens.semibold
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    visible: root.controller.microphoneActive
                    width: 5
                    height: 5
                    radius: 3
                    color: Tokens.amber
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    visible: root.controller.cameraActive
                    width: 5
                    height: 5
                    radius: 3
                    color: Tokens.green
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => root.controller.open(event.button === Qt.RightButton ? "controls" : "overview")
                onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
            }
            Accessible.role: Accessible.Button
            Accessible.name: "Clock. Open island"
            Accessible.onPressAction: root.controller.open("overview")
        }
        Flickable {
            anchors.fill: parent
            anchors.margins: Tokens.padding
            clip: true
            contentHeight: content.implicitHeight
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            interactive: contentHeight > height
            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.duration
                }
            }
            IslandContent {
                id: content
                width: parent.width
                controller: root.controller
                monitor: root.monitor
            }
        }
        focus: root.expanded
        Keys.onEscapePressed: root.controller.dismiss()
    }
}
