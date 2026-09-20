pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.utils

PanelWindow {
    id: root
    property bool expanded: false
    required property string targetScreenName
    readonly property var active: Hypr.activeToplevel
    readonly property var info: active?.lastIpcObject ?? null
    readonly property bool isFocusedScreen: root.targetScreenName === (Hypr.focusedMonitor?.name ?? "")
    readonly property string appName: friendlyName(info?.class ?? "")
    readonly property var workspaceWindows: active?.workspace?.toplevels?.values ?? []

    function friendlyName(appClass) {
        const raw = String(appClass).replace(/^com\./, "").split(".").pop();
        const known = {"helium": "Helium", "ghostty": "Ghostty", "T3Code": "T3 Code", "vesktop": "Vesktop", "org.kde.dolphin": "Files"};
        return known[appClass] ?? known[raw] ?? raw.replace(/[-_]/g, " ").replace(/\b\w/g, c => c.toUpperCase());
    }
    function dispatchWindow(command) {
        if (info?.address)
            Hypr.dispatch(command + " address:" + info.address);
    }

    visible: root.isFocusedScreen && root.active !== null
    color: "transparent"
    anchors.top: true
    anchors.left: true
    implicitWidth: root.expanded ? 390 : Math.min(300, Math.max(86, appIdentity.implicitWidth + 20))
    implicitHeight: (root.expanded ? panel.implicitHeight + Tokens.padding * 2 : Tokens.compactHeight) + Tokens.topMargin
    exclusiveZone: 0
    WlrLayershell.namespace: "caelestia-active-pill"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: root.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: surface.radius }

    onActiveChanged: if (!active) expanded = false
    HyprlandFocusGrab { active: root.expanded; windows: [root]; onCleared: root.expanded = false }

    Glass {
        id: surface
        x: 8
        y: Tokens.topMargin
        width: root.width - 8
        height: root.expanded ? panel.implicitHeight + Tokens.padding * 2 : Tokens.compactHeight
        radius: root.expanded ? Tokens.radius : Tokens.compactHeight / 2
        color: root.expanded ? Tokens.surface : Qt.alpha(Tokens.tint, compactHover.hovered ? 0.32 : 0.22)
        outlined: false
        elevated: root.expanded
        Behavior on width { NumberAnimation { duration: Tokens.morph; easing.type: Tokens.morphEasing } }
        Behavior on height { NumberAnimation { duration: Tokens.morph; easing.type: Tokens.morphEasing } }
        Behavior on radius { NumberAnimation { duration: Tokens.duration; easing.type: Tokens.easing } }

        Row {
            id: compactRow
            anchors.centerIn: parent
            spacing: 7
            opacity: root.expanded ? 0 : 1
            visible: opacity > 0
            Row {
                id: appIdentity
                height: Tokens.compactHeight - 8
                spacing: 7
                anchors.verticalCenter: parent.verticalCenter
                IconImage {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    source: Icons.getAppIcon(root.info?.class ?? "", "application-x-executable")
                }
                GlassLabel {
                    width: Math.min(210, implicitWidth)
                    text: root.appName
                    font.pixelSize: Tokens.caption
                    font.weight: Tokens.semibold
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                TapHandler { onTapped: root.expanded = true }
            }
            Behavior on opacity { NumberAnimation { duration: Tokens.fast } }
        }
        HoverHandler { id: compactHover; enabled: !root.expanded }

        ColumnLayout {
            id: panel
            anchors.fill: parent
            anchors.margins: Tokens.padding
            spacing: 11
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Tokens.fast } }

            RowLayout {
                Layout.fillWidth: true; spacing: 11
                Rectangle {
                    width: 40; height: 40; radius: 12; color: Tokens.control
                    IconImage { anchors.centerIn: parent; width: 24; height: 24; source: Icons.getAppIcon(root.info?.class ?? "", "application-x-executable") }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    GlassLabel { text: root.appName; font.pixelSize: Tokens.title; font.weight: Tokens.semibold }
                    GlassLabel { Layout.fillWidth: true; text: root.info?.title ?? ""; color: Tokens.secondary; font.pixelSize: Tokens.caption; maximumLineCount: 1 }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                GlassButton { Layout.fillWidth: true; text: root.info?.floating ? "Tile" : "Float"; onClicked: root.dispatchWindow("togglefloating") }
                GlassButton { Layout.fillWidth: true; text: root.info?.fullscreen ? "Restore" : "Full screen"; onClicked: root.dispatchWindow("fullscreen 1,") }
                GlassButton { Layout.fillWidth: true; text: "Close"; onClicked: { root.dispatchWindow("closewindow"); root.expanded = false; } }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Tokens.separator }
            RowLayout {
                Layout.fillWidth: true
                GlassLabel { text: "DESKTOPS"; color: Tokens.tertiary; font.pixelSize: 10; font.weight: Tokens.semibold; Layout.fillWidth: true }
                GlassLabel { text: "Current " + (root.active?.workspace?.name ?? "—"); color: Tokens.secondary; font.pixelSize: 11 }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: 5
                    GlassButton {
                        required property int index
                        Layout.fillWidth: true; text: String(index + 1); selected: Hypr.activeWsId === index + 1
                        onClicked: { Hypr.focusWorkspace(index + 1); root.expanded = false; }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                GlassButton { Layout.fillWidth: true; text: "Move left"; onClicked: root.dispatchWindow("movetoworkspace r-1,") }
                GlassButton { Layout.fillWidth: true; text: "Move right"; onClicked: root.dispatchWindow("movetoworkspace r+1,") }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Tokens.separator }
            RowLayout {
                Layout.fillWidth: true
                GlassLabel { text: "Workspace windows"; color: Tokens.secondary; Layout.fillWidth: true }
                GlassLabel { text: String(root.workspaceWindows.length); font.weight: Tokens.semibold }
            }
            GlassLabel {
                Layout.fillWidth: true
                text: (root.info?.floating ? "Floating" : "Tiled") + " · " + (root.info?.size ? root.info.size[0] : "—") + " × " + (root.info?.size ? root.info.size[1] : "—")
                color: Tokens.tertiary; font.pixelSize: 11
            }
        }
    }
}
