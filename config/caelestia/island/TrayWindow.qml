pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.utils

PanelWindow {
    id: root

    required property string targetScreenName
    readonly property bool isFocusedScreen: root.targetScreenName === (Hypr.focusedMonitor?.name ?? "")
    readonly property bool hasFullscreen: Hypr.focusedWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property var visibleItems: SystemTray.items.values.filter(item => item.status !== Status.Passive)

    visible: root.isFocusedScreen && !root.hasFullscreen && root.visibleItems.length > 0
    color: "transparent"
    anchors.top: true
    anchors.right: true
    implicitWidth: trayRow.implicitWidth + 16
    implicitHeight: Tokens.compactHeight + Tokens.topMargin
    exclusiveZone: 0

    WlrLayershell.namespace: "caelestia-tray"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Item {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: Tokens.topMargin
        width: trayRow.implicitWidth
        height: Tokens.compactHeight

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: ScriptModel { values: root.visibleItems }

                Rectangle {
                    id: trayItem
                    required property var modelData
                    width: 28
                    height: 28
                    radius: 9
                    color: trayHover.hovered || trayMenu.visible ? Tokens.hover : "transparent"

                    IconImage {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: Icons.getTrayIcon(trayItem.modelData.id, trayItem.modelData.icon)
                    }

                    QsMenuAnchor {
                        id: trayMenu
                        menu: trayItem.modelData.menu
                        anchor.item: trayItem
                        anchor.edges: Edges.Bottom | Edges.Right
                        anchor.gravity: Edges.Bottom | Edges.Left
                    }

                    HoverHandler { id: trayHover }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: trayItem.modelData.activate()
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            if (trayItem.modelData.hasMenu)
                                trayMenu.open();
                            else
                                trayItem.modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
