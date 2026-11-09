pragma ComponentBehavior: Bound

import QtQuick
import "Launcher.js" as Launcher
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
    readonly property bool commandMode: CConfig.GlobalConfig.launcher.actionPrefix.length > 0 && search.text.startsWith(CConfig.GlobalConfig.launcher.actionPrefix)
    readonly property var answer: commandMode ? null : Launcher.answer(search.text)

    function moveSelection(delta): void {
        if (resultList.count > 0)
            resultList.currentIndex = (resultList.currentIndex + delta + resultList.count) % resultList.count;
    }

    function open(): void {
        closeTimer.stop();
        retainedVisible = true;
        launching = false;
        openProgress = 1;
        Qt.callLater(() => search.forceActiveFocus());
    }

    function close(): void {
        launchTimer.stop();
        pendingEntry = null;
        launching = false;
        openProgress = 0;
        closeTimer.restart();
    }

    function activate(item): void {
        if (!item || launching || !state?.launcher)
            return;

        if (item.kind === "Calculator" || item.kind === "Conversion") {
            Quickshell.execDetached(["wl-copy", "--", item.value]);
            state.launcher = false;
            return;
        }

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
    implicitWidth: Math.min(screen.width, 820)
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
            if (root.state?.launcher && root.pendingEntry)
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

        width: Math.min(760, root.width - Tokens.padding * 2)
        height: Math.min(548, root.height - 84)
        x: Math.round((root.width - width) / 2)
        y: Math.round(68 + 16 * (1 - root.openProgress))
        radius: 16
        // Leave the wallpaper visible through Hyprland's backdrop blur.
        color: Tokens.opaque ? "#171719" : "#78171719"
        border.width: 1
        border.color: "#30ffffff"
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
            anchors.margins: 10
            spacing: 10

            Rectangle {
                width: parent.width
                height: 66
                color: "transparent"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: -10
                    anchors.rightMargin: -10
                    height: 1
                    color: "#20ffffff"
                }

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
                    text: "Search anything…"
                    color: "#99ffffff"
                    font.family: Tokens.fontFamily
                    font.pixelSize: 19
                }

                TextInput {
                    id: search

                    anchors.left: parent.left
                    anchors.leftMargin: 47
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    color: Tokens.text
                    selectionColor: "#40ffffff"
                    selectedTextColor: Tokens.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: 19
                    clip: true

                    onAccepted: root.activate(resultList.currentItem?.itemData)
                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onEscapePressed: if (root.state)
                        root.state.launcher = false
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            root.moveSelection(event.modifiers & Qt.ShiftModifier ? -1 : 1);
                            event.accepted = true;
                        }
                    }
                }

            }

            Item {
                width: parent.width
                height: parent.height - 66 - 10

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
                        values: {
                            if (root.commandMode)
                                return Actions.query(search.text);

                            const apps = Apps.search(search.text);
                            const results = root.answer ? [root.answer, ...apps] : apps;
                            return Launcher.appResults(search.text, results, Apps.search(""), CConfig.GlobalConfig.launcher.specialPrefix);
                        }
                        onValuesChanged: {
                            resultList.currentIndex = resultList.count > 0 ? 0 : -1;
                            if (resultList.count > 0)
                                resultList.positionViewAtIndex(0, ListView.Beginning);
                        }
                    }

                    highlightFollowsCurrentItem: true
                    highlight: Rectangle {
                        radius: 8
                        color: "#24ffffff"
                    }

                    delegate: Item {
                        id: resultItem
                        required property var modelData
                        required property int index
                        readonly property var itemData: modelData
                        readonly property bool selected: ListView.isCurrentItem

                        width: ListView.view.width
                        height: resultItem.modelData?.kind ? 76 : 52

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
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
                            sourceComponent: root.commandMode || resultItem.modelData?.kind ? commandIcon : appIcon
                        }

                        Column {
                            anchors.left: resultIcon.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: resultItem.modelData?.name ?? ""
                                color: Tokens.text
                                elide: Text.ElideRight
                                font.family: Tokens.fontFamily
                                font.pixelSize: resultItem.modelData?.kind ? 24 : 14
                                font.weight: resultItem.selected ? Tokens.semibold : Tokens.medium
                            }

                            Text {
                                width: parent.width
                                text: resultItem.modelData?.kind ? `${resultItem.modelData.kind} · ${resultItem.modelData.desc}` : root.commandMode ? (resultItem.modelData?.desc ?? "") : (resultItem.modelData?.comment || resultItem.modelData?.genericName || "")
                                visible: text.length > 0
                                color: Tokens.secondary
                                elide: Text.ElideRight
                                font.family: Tokens.fontFamily
                                font.pixelSize: 11
                            }
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
                                    name: resultItem.modelData?.kind ? "equal" : (resultItem.modelData?.icon ?? "ellipsis")
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
