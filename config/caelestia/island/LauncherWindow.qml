pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config as CConfig
import Caelestia.Services
import qs.services
import qs.modules.launcher.services

PanelWindow {
    id: root

    readonly property var state: ShellState.forScreen(screen)
    property bool retainedVisible: false
    property real openProgress: 0
    property bool launching: false
    property var pendingEntry: null
    readonly property int transitionDuration: Tokens.reducedMotion ? 0 : 180
    readonly property bool commandMode: search.text.startsWith(CConfig.GlobalConfig.launcher.actionPrefix)

    function open(): void {
        retainedVisible = true;
        launching = false;
        openProgress = 1;
        Qt.callLater(() => search.forceActiveFocus());
    }

    function close(): void {
        openProgress = 0;
        closeTimer.restart();
    }

    function activate(item): void {
        if (!item)
            return;

        if (!commandMode) {
            pendingEntry = item;
            launching = true;
            launchTimer.restart();
            return;
        }

        const command = item.command ?? [];
        if (command.length === 0)
            return;
        if (command[0] === "autocomplete" && command.length > 1) {
            search.text = `${CConfig.GlobalConfig.launcher.actionPrefix}${command[1]} `;
            search.forceActiveFocus();
        } else if (command[0] === "setMode" && command.length > 1) {
            Colours.setMode(command[1]);
            state.launcher = false;
        } else {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
            state.launcher = false;
        }
    }

    visible: retainedVisible
    color: "transparent"
    anchors.top: true
    implicitWidth: Math.min(screen.width, 700)
    implicitHeight: Math.min(screen.height, 680)
    exclusiveZone: 0

    WlrLayershell.namespace: "caelestia-island-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: {
        // Force the application database to initialise before the first shortcut.
        const unused = Apps.search("");
        if (state?.launcher)
            open();
    }

    Connections {
        target: root.state

        function onLauncherChanged(): void {
            if (root.state.launcher)
                root.open();
            else {
                root.close();
                search.text = "";
            }
        }
    }

    Behavior on openProgress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Tokens.morphEasing
        }
    }

    Timer {
        id: closeTimer
        interval: root.transitionDuration + 20
        onTriggered: if (!root.state?.launcher)
            root.retainedVisible = false
    }

    Timer {
        id: launchTimer
        interval: Tokens.fast
        onTriggered: {
            if (root.pendingEntry)
                Apps.launch(root.pendingEntry);
            root.pendingEntry = null;
            if (root.state)
                root.state.launcher = false;
        }
    }

    HyprlandFocusGrab {
        active: root.state?.launcher ?? false
        windows: [root]
        onCleared: if (root.state)
            root.state.launcher = false
    }

    Glass {
        id: surface

        width: Math.min(640, root.width - Tokens.padding * 2)
        height: Math.min(548, root.height - 84)
        x: Math.round((root.width - width) / 2)
        y: Math.round(68 + 16 * (1 - root.openProgress))
        radius: 30
        opacity: root.openProgress * (root.launching ? 0.72 : 1)
        scale: (0.965 + root.openProgress * 0.035) * (root.launching ? 0.985 : 1)
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: Tokens.fast; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Tokens.fast; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Row {
                width: parent.width
                height: 28

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.commandMode ? "Commands" : "Applications"
                    color: Tokens.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.title
                    font.weight: Tokens.semibold
                }

                Item { width: parent.width - 190; height: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: resultList.count === 1 ? "1 result" : `${resultList.count} results`
                    color: Tokens.tertiary
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.caption
                }
            }

            Rectangle {
                width: parent.width
                height: 48
                radius: 15
                color: search.activeFocus ? Tokens.selected : Tokens.control
                border.width: Tokens.borderWidth
                border.color: search.activeFocus ? Qt.alpha(Tokens.accent, 0.56) : Tokens.separator

                Behavior on color { ColorAnimation { duration: Tokens.fast } }
                Behavior on border.color { ColorAnimation { duration: Tokens.fast } }

                Symbol {
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.commandMode ? "terminal" : "search"
                    size: 19
                    color: search.activeFocus ? Tokens.text : Tokens.secondary
                }

                Text {
                    visible: search.text.length === 0
                    anchors.left: parent.left
                    anchors.leftMargin: 47
                    anchors.verticalCenter: parent.verticalCenter
                    text: `Search apps or type ${CConfig.GlobalConfig.launcher.actionPrefix} for commands`
                    color: Tokens.tertiary
                    font.family: Tokens.fontFamily
                    font.pixelSize: 15
                }

                TextInput {
                    id: search

                    anchors.left: parent.left
                    anchors.leftMargin: 47
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    color: Tokens.text
                    selectionColor: Qt.alpha(Tokens.accent, 0.42)
                    selectedTextColor: Tokens.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: 15
                    clip: true

                    onTextChanged: resultList.currentIndex = 0
                    onAccepted: root.activate(resultList.currentItem?.itemData)
                    Keys.onUpPressed: resultList.decrementCurrentIndex()
                    Keys.onDownPressed: resultList.incrementCurrentIndex()
                    Keys.onEscapePressed: if (root.state)
                        root.state.launcher = false
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            resultList.incrementCurrentIndex();
                            event.accepted = true;
                        }
                    }
                }

            }

            Item {
                width: parent.width
                height: parent.height - 28 - 48 - 28

                ListView {
                    id: resultList

                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    currentIndex: count > 0 ? 0 : -1
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: Tokens.duration
                    highlightResizeDuration: Tokens.duration
                    highlightMoveVelocity: -1
                    highlightResizeVelocity: -1

                    model: ScriptModel {
                        values: root.commandMode ? Actions.query(search.text) : Apps.search(search.text)
                    }

                    highlightFollowsCurrentItem: true
                    highlight: Rectangle {
                        radius: 14
                        color: Tokens.selected
                        border.width: Tokens.borderWidth
                        border.color: Tokens.separator
                    }

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Tokens.duration }
                            NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: Tokens.duration; easing.type: Easing.OutCubic }
                        }
                    }
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; to: 0; duration: Tokens.fast }
                            NumberAnimation { property: "scale"; to: 0.97; duration: Tokens.fast }
                        }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: Tokens.duration; easing.type: Tokens.easing }
                    }

                    delegate: Item {
                        id: resultItem
                        required property var modelData
                        required property int index
                        readonly property var itemData: modelData
                        readonly property bool selected: ListView.isCurrentItem

                        width: ListView.view.width
                        height: 50

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: pointer.containsMouse && !resultItem.selected ? Tokens.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: Tokens.fast } }
                        }

                        Loader {
                            id: resultIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            height: 30
                            sourceComponent: root.commandMode ? commandIcon : appIcon
                        }

                        Column {
                            anchors.left: resultIcon.right
                            anchors.leftMargin: 12
                            anchors.right: launchGlyph.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: resultItem.modelData?.name ?? ""
                                color: Tokens.text
                                elide: Text.ElideRight
                                font.family: Tokens.fontFamily
                                font.pixelSize: 14
                                font.weight: resultItem.selected ? Tokens.semibold : Tokens.medium
                            }

                            Text {
                                width: parent.width
                                text: root.commandMode ? (resultItem.modelData?.desc ?? "") : (resultItem.modelData?.comment || resultItem.modelData?.genericName || "")
                                visible: text.length > 0
                                color: Tokens.secondary
                                elide: Text.ElideRight
                                font.family: Tokens.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Symbol {
                            id: launchGlyph
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            name: root.commandMode ? "arrow.right" : "return"
                            size: 14
                            color: resultItem.selected ? Tokens.secondary : Tokens.tertiary
                            opacity: resultItem.selected || pointer.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Tokens.fast } }
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: resultList.currentIndex = index
                            onClicked: root.activate(resultItem.modelData)
                        }

                        Component {
                            id: appIcon
                            IconImage {
                                anchors.fill: parent
                                asynchronous: true
                                source: Quickshell.iconPath(resultItem.modelData?.icon, "image-missing")
                                mipmap: true
                            }
                        }

                        Component {
                            id: commandIcon
                            Rectangle {
                                radius: 9
                                color: Tokens.control
                                Symbol {
                                    anchors.centerIn: parent
                                    name: resultItem.modelData?.icon ?? "ellipsis"
                                    size: 17
                                    color: Tokens.secondary
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: resultList.count === 0

                    Symbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: root.commandMode ? "terminal" : "search"
                        size: 26
                        color: Tokens.tertiary
                    }
                    Text {
                        text: search.text.length > 0 ? "No matching results" : "Start typing to search"
                        color: Tokens.secondary
                        font.family: Tokens.fontFamily
                        font.pixelSize: 13
                    }
                }
            }

        }
    }
}
