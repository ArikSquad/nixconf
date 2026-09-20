pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Services
import qs.services

ColumnLayout {
    id: root
    required property var controller
    required property var monitor
    readonly property string mode: controller.mode
    readonly property var player: Players.active
    property string confirmAction: ""
    function duration(seconds) {
        const value = Math.max(0, Math.floor(seconds || 0));
        return Math.floor(value / 60) + ":" + (value % 60).toString().padStart(2, "0");
    }
    onModeChanged: confirmAction = ""
    spacing: Tokens.gap
    RowLayout {
        Layout.fillWidth: true
        GlassLabel {
            text: Time.format("HH:mm")
            font.weight: Tokens.semibold
            Layout.fillWidth: true
        }
        GlassLabel {
            text: Qt.formatDate(Time.date, "ddd, MMM d")
            color: Tokens.secondary
            font.pixelSize: Tokens.caption
        }
    }
    Loader {
        id: pageLoader
        Layout.fillWidth: true
        onLoaded: pageFade.restart()
        NumberAnimation {
            id: pageFade
            target: pageLoader
            property: "opacity"
            from: 0
            to: 1
            duration: Tokens.fast
        }
        sourceComponent: {
            switch (root.mode) {
            case "notification":
                return notification;
            case "notifications":
                return history;
            case "media":
                return media;
            case "calendar":
                return calendar;
            case "weather":
                return weather;
            case "performance":
                return performance;
            case "greeting":
                return greeting;
            case "timer":
                return timer;
            case "system":
                return system;
            case "more":
                return more;
            case "controls":
            case "volume":
            case "brightness":
            case "network":
            case "microphone":
                return controls;
            default:
                return overview;
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.small
        implicitHeight: 58
        radius: 18
        color: "#0cffffff"
        border.width: 0.5
        border.color: "#12ffffff"
        visible: root.controller.page !== "idle"
        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 3
            Repeater {
                model: [
                    {key: "overview", symbol: "today", label: "Today"},
                    {key: "controls", symbol: "controls", label: "Controls"},
                    {key: "media", symbol: "media", label: "Music"},
                    {key: "notifications", symbol: "notifications", label: "Inbox"},
                    {key: "more", symbol: "more", label: "More"}
                ]
                NavButton {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    symbol: modelData.symbol
                    text: modelData.label
                    selected: root.mode === modelData.key || (modelData.key === "more" && ["calendar", "weather", "performance", "timer", "system"].includes(root.mode))
                    onClicked: {
                        root.controller.eventMode = "";
                        root.controller.open(modelData.key);
                    }
                }
            }
        }
    }
    Component {
        id: more
        GridLayout {
            columns: 2
            columnSpacing: Tokens.small
            rowSpacing: Tokens.small
            Repeater {
                model: [
                    {
                        key: "calendar",
                        label: "Calendar"
                    },
                    {
                        key: "weather",
                        label: "Weather"
                    },
                    {
                        key: "performance",
                        label: "Activity"
                    },
                    {
                        key: "timer",
                        label: "Focus timer"
                    },
                    {
                        key: "system",
                        label: "System"
                    }
                ]
                GlassButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    onClicked: root.controller.open(modelData.key)
                }
            }
        }
    }
    Component {
        id: greeting
        ColumnLayout {
            spacing: 5
            GlassLabel {
                text: root.controller.greetingForHour(Time.hours) + ", Ari"
                font.pixelSize: 23
                font.weight: Tokens.semibold
            }
            GlassLabel {
                text: root.controller.bootDuration ? "Booted in " + root.controller.bootDuration : "Your desktop is ready"
                color: Tokens.secondary
                font.pixelSize: Tokens.body
            }
        }
    }
    Component {
        id: overview
        ColumnLayout {
            spacing: 9
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 49
                radius: 14
                color: todayHover.hovered ? Tokens.hover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 8
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        GlassLabel { text: root.controller.greetingForHour(Time.hours) + ", Ari"; font.pixelSize: 22; font.weight: Tokens.semibold }
                        GlassLabel { text: Qt.formatDate(Time.date, "dddd, MMMM d") + " · Week " + Math.ceil((((Time.date - new Date(Time.date.getFullYear(), 0, 1)) / 86400000) + new Date(Time.date.getFullYear(), 0, 1).getDay() + 1) / 7); color: Tokens.secondary; font.pixelSize: Tokens.caption }
                    }
                    Symbol { name: "arrow.right"; size: 16; color: Tokens.secondary }
                }
                HoverHandler { id: todayHover }
                TapHandler { onTapped: root.controller.open("calendar") }
                Accessible.role: Accessible.Button
                Accessible.name: "Open calendar"
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 64; radius: 16; color: Tokens.control
                RowLayout {
                    anchors.fill: parent; anchors.margins: 11; spacing: 10
                    Rectangle { width: 36; height: 36; radius: 11; color: root.controller.deadline > 0 ? "#2eff9f0a" : "#18ffffff"; GlassLabel { anchors.centerIn: parent; text: "◷"; color: root.controller.deadline > 0 ? Tokens.amber : Tokens.secondary; font.pixelSize: 20 } }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        GlassLabel { text: root.controller.deadline > 0 ? "Focus in progress" : "Start a focus timer"; font.weight: Tokens.semibold }
                        GlassLabel { text: root.controller.deadline > 0 ? Math.floor(root.controller.secondsLeft / 60) + " min " + (root.controller.secondsLeft % 60) + " sec remaining" : "A quiet 25-minute session"; color: Tokens.secondary; font.pixelSize: 11 }
                    }
                    GlassButton { text: root.controller.deadline > 0 ? "Open" : "Start"; onClicked: root.controller.deadline > 0 ? root.controller.open("timer") : root.controller.startTimer(25) }
                }
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 52; radius: 15; color: Tokens.control
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10
                    Symbol { name: root.player?.isPlaying ? "pause" : "media"; color: Tokens.secondary; size: 19 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        GlassLabel {
                            text: root.player?.trackTitle || "No audio playing"
                            font.weight: Tokens.semibold
                            font.pixelSize: Tokens.caption
                        }
                        GlassLabel {
                            text: root.player?.trackArtist || "Play something to see it here"
                            color: Tokens.tertiary
                            font.pixelSize: 10
                        }
                    }
                    GlassButton { text: "Music"; enabled: !!root.player?.trackTitle; onClicked: root.controller.open("media") }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                GlassButton {
                    Layout.fillWidth: true
                    text: Notifs.dnd ? "Focus on" : "Focus off"
                    selected: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
                GlassButton {
                    Layout.fillWidth: true
                    text: Notifs.notClosed.length + " notifications"
                    onClicked: root.controller.open("notifications")
                }
                GlassButton {
                    Layout.fillWidth: true
                    text: Nmcli.isConnected ? Nmcli.activeConnection : "Offline"
                    onClicked: root.controller.open("controls")
                }
            }
        }
    }
    Component {
        id: notification
        NotificationCard {
            notification: root.controller.popup
            onDismissed: root.controller.dismiss()
        }
    }
    Component {
        id: history
        ColumnLayout {
            spacing: Tokens.gap
            RowLayout {
                Layout.fillWidth: true
                GlassLabel { text: "Notifications"; font.pixelSize: Tokens.title; Layout.fillWidth: true }
                GlassButton {
                    visible: Notifs.notClosed.length > 0
                    text: "Clear all"
                    onClicked: Notifs.notClosed.slice().forEach(notification => notification.close())
                }
            }
            GlassLabel {
                visible: Notifs.notClosed.length === 0
                text: "You're all caught up."
                color: Tokens.secondary
            }
            Repeater {
                model: Notifs.notClosed.slice(0, 20)
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    NotificationCard {
                        Layout.fillWidth: true
                        notification: parent.modelData
                    }
                    GlassButton {
                        text: "Clear"
                        onClicked: parent.modelData.close()
                    }
                }
            }
            GlassLabel {
                visible: Notifs.notClosed.length > 20
                text: "Showing the latest 20 notifications"
                color: Tokens.secondary
            }
        }
    }
    Component {
        id: media
        ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 13
                Item {
                    Layout.preferredWidth: 82; Layout.preferredHeight: 82
                    Image { id: coverSource; anchors.fill: parent; source: Players.getArtUrl(root.player); fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false }
                    Rectangle { id: coverMask; anchors.fill: parent; radius: 19; visible: false; layer.enabled: true }
                    MultiEffect { anchors.fill: parent; source: coverSource; maskEnabled: true; maskSource: coverMask }
                    Rectangle { anchors.fill: parent; radius: 19; color: "transparent"; border.width: 0.5; border.color: "#20ffffff" }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    GlassLabel {
                        text: root.player?.trackTitle || ""
                        font.pixelSize: Tokens.title
                        font.weight: Tokens.semibold
                        Layout.fillWidth: true
                    }
                    GlassLabel {
                        text: root.player?.trackArtist || root.player?.identity || ""
                        color: Tokens.secondary
                        Layout.fillWidth: true
                    }
                    GlassLabel { text: root.player?.trackAlbum || ""; visible: text.length > 0; color: Tokens.tertiary; font.pixelSize: 11; Layout.fillWidth: true }
                }
            }
            Meter {
                Layout.fillWidth: true
                value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                enabled: (root.player?.canSeek ?? false) && root.player.length > 0
                Accessible.name: "Playback position"
                onMoved: root.player.position = value * root.player.length
            }
            RowLayout {
                Layout.fillWidth: true
                GlassLabel { text: root.duration(root.player?.position); color: Tokens.secondary; font.pixelSize: 10; Layout.fillWidth: true }
                GlassLabel { text: "−" + root.duration(Math.max(0, (root.player?.length ?? 0) - (root.player?.position ?? 0))); color: Tokens.secondary; font.pixelSize: 10 }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 25
                Rectangle {
                    width: 42; height: 42; radius: 21; color: previousTap.pressed ? Tokens.pressed : previousHover.hovered ? Tokens.hover : "transparent"; opacity: (root.player?.canGoPrevious ?? false) ? 1 : 0.35
                    Symbol { anchors.centerIn: parent; name: "previous"; size: 25 }
                    HoverHandler { id: previousHover }
                    TapHandler { id: previousTap; enabled: root.player?.canGoPrevious ?? false; onTapped: root.player.previous() }
                }
                Rectangle {
                    width: 54; height: 54; radius: 27; color: playTap.pressed ? "#d8ffffff" : Tokens.text; opacity: (root.player?.canTogglePlaying ?? false) ? 1 : 0.35
                    Symbol { anchors.centerIn: parent; name: root.player?.isPlaying ? "pause" : "play"; size: 29; color: Tokens.tint }
                    TapHandler { id: playTap; enabled: root.player?.canTogglePlaying ?? false; onTapped: root.player.togglePlaying() }
                }
                Rectangle {
                    width: 42; height: 42; radius: 21; color: nextTap.pressed ? Tokens.pressed : nextHover.hovered ? Tokens.hover : "transparent"; opacity: (root.player?.canGoNext ?? false) ? 1 : 0.35
                    Symbol { anchors.centerIn: parent; name: "next"; size: 25 }
                    HoverHandler { id: nextHover }
                    TapHandler { id: nextTap; enabled: root.player?.canGoNext ?? false; onTapped: root.player.next() }
                }
            }
        }
    }
    Component {
        id: controls
        ColumnLayout {
            spacing: Tokens.gap
            RowLayout {
                Layout.fillWidth: true
                GlassLabel { text: "Control Center"; font.pixelSize: Tokens.title; font.weight: Tokens.semibold; Layout.fillWidth: true }
                GlassLabel { visible: UPower.displayDevice.isLaptopBattery; text: Math.round(UPower.displayDevice.percentage * 100) + "%"; color: Tokens.secondary }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 7
                GlassButton { Layout.fillWidth: true; text: Nmcli.wifiEnabled ? "Wi‑Fi on" : "Wi‑Fi off"; selected: Nmcli.wifiEnabled; onClicked: Nmcli.toggleWifi(null) }
                GlassButton { Layout.fillWidth: true; text: Bluetooth.defaultAdapter?.enabled ? "Bluetooth on" : "Bluetooth off"; enabled: !!Bluetooth.defaultAdapter; selected: Bluetooth.defaultAdapter?.enabled ?? false; onClicked: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
                GlassButton { Layout.fillWidth: true; text: Notifs.dnd ? "Focus on" : "Focus off"; selected: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
            }
            RowLayout {
                GlassLabel {
                    text: Audio.muted ? "Volume · Muted" : "Volume"
                    Layout.fillWidth: true
                }
                GlassLabel {
                    text: Math.round(Audio.volume * 100) + "%"
                    color: Tokens.secondary
                }
                GlassButton {
                    text: Audio.muted ? "Unmute" : "Mute"
                    enabled: !!Audio.sink?.audio
                    onClicked: Audio.sink.audio.muted = !Audio.muted
                }
            }
            Meter {
                Layout.fillWidth: true
                value: Audio.volume
                enabled: !!Audio.sink?.audio
                Accessible.name: "Volume"
                onMoved: Audio.setVolume(value)
            }
            GlassLabel {
                text: root.monitor ? "Display brightness" : "Brightness unavailable"
                color: Tokens.secondary
            }
            Meter {
                Layout.fillWidth: true
                value: root.monitor?.brightness ?? 0
                enabled: !!root.monitor
                Accessible.name: "Display brightness"
                onMoved: root.monitor.setBrightness(value)
            }
            GlassLabel {
                text: Nmcli.isConnected ? "Connected · " + Nmcli.activeConnection : "Network disconnected"
                color: Tokens.secondary
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                GlassButton {
                    Layout.fillWidth: true
                    text: Audio.sourceMuted ? "Mic muted" : "Mute mic"
                    enabled: !!Audio.source?.audio
                    onClicked: Audio.source.audio.muted = !Audio.sourceMuted
                }
                GlassButton { Layout.fillWidth: true; text: root.monitor ? "Display " + Math.round(root.monitor.brightness * 100) + "%" : "Display unavailable"; enabled: !!root.monitor }
            }
            GlassLabel {
                visible: root.controller.microphoneActive || root.controller.cameraActive
                text: root.controller.cameraActive ? "Camera capture active" : "Microphone capture active"
                color: root.controller.cameraActive ? Tokens.green : Tokens.amber
            }
            GlassLabel {
                visible: UPower.displayDevice.isLaptopBattery
                text: "Battery · " + Math.round(UPower.displayDevice.percentage * 100) + "%" + (UPower.onBattery ? " · On battery" : " · Plugged in")
                color: Tokens.secondary
            }
        }
    }
    Component {
        id: calendar
        CalendarPanel {
            controller: root.controller
        }
    }
    Component {
        id: weather
        WeatherPanel {}
    }
    Component {
        id: performance
        PerformancePanel {}
    }
    Component {
        id: timer
        ColumnLayout {
            id: timerPanel
            property int selectedHours: 0
            property int selectedMinutes: 25
            readonly property int selectedTotal: Math.max(1, selectedHours * 60 + selectedMinutes)
            spacing: 11
            RowLayout {
                Layout.fillWidth: true
                Item {
                    width: 54; height: 54
                    Rectangle {
                        id: timerHalo
                        anchors.centerIn: parent
                        width: 50; height: 50; radius: 25
                        color: root.controller.timerFinished ? "#4d30d158" : "#28ff9f0a"
                        border.width: root.controller.timerFinished ? 2 : 0
                        border.color: Tokens.green
                        GlassLabel { anchors.centerIn: parent; text: root.controller.timerFinished ? "✓" : "◷"; color: root.controller.timerFinished ? Tokens.green : Tokens.amber; font.pixelSize: 28; font.weight: Tokens.semibold }
                    }
                    SequentialAnimation {
                        running: root.controller.timerFinished
                        loops: Animation.Infinite
                        NumberAnimation { target: timerHalo; property: "scale"; from: 1; to: 1.12; duration: 520; easing.type: Easing.OutCubic }
                        NumberAnimation { target: timerHalo; property: "scale"; from: 1.12; to: 1; duration: 520; easing.type: Easing.InOutCubic }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    GlassLabel { text: root.controller.timerFinished ? "Timer complete" : root.controller.deadline > 0 ? "Timer" : "New timer"; color: root.controller.timerFinished ? Tokens.green : Tokens.secondary; font.pixelSize: Tokens.caption }
                    GlassLabel { text: root.controller.timerFinished ? "Done" : root.controller.deadline > 0 ? Math.floor(root.controller.secondsLeft / 60).toString().padStart(2, "0") + ":" + (root.controller.secondsLeft % 60).toString().padStart(2, "0") : "Set a duration"; font.pixelSize: 28; font.weight: Tokens.semibold; color: root.controller.deadline > 0 ? Tokens.amber : Tokens.text }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: root.controller.timerFinished
                Repeater {
                    model: [1, 5, 10]
                    GlassButton {
                        required property int modelData
                        Layout.fillWidth: true
                        text: "+" + modelData + " min"
                        onClicked: root.controller.addTimerMinutes(modelData)
                    }
                }
                GlassButton {
                    text: "Dismiss"
                    onClicked: root.controller.stopTimer()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: !root.controller.timerFinished && root.controller.deadline <= 0
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 72; radius: 16; color: Tokens.control
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 3
                        GlassLabel { text: "HOURS"; color: Tokens.tertiary; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                        RowLayout {
                            GlassButton { text: "−"; onClicked: timerPanel.selectedHours = Math.max(0, timerPanel.selectedHours - 1) }
                            GlassLabel { text: timerPanel.selectedHours.toString().padStart(2, "0"); font.pixelSize: 21; font.weight: Tokens.semibold; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignHCenter }
                            GlassButton { text: "+"; onClicked: timerPanel.selectedHours = Math.min(23, timerPanel.selectedHours + 1) }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 72; radius: 16; color: Tokens.control
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 3
                        GlassLabel { text: "MINUTES"; color: Tokens.tertiary; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                        RowLayout {
                            GlassButton { text: "−"; onClicked: timerPanel.selectedMinutes = Math.max(0, timerPanel.selectedMinutes - 5) }
                            GlassLabel { text: timerPanel.selectedMinutes.toString().padStart(2, "0"); font.pixelSize: 21; font.weight: Tokens.semibold; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignHCenter }
                            GlassButton { text: "+"; onClicked: timerPanel.selectedMinutes = Math.min(55, timerPanel.selectedMinutes + 5) }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: !root.controller.timerFinished && root.controller.deadline <= 0
                Repeater {
                    model: [5, 15, 25, 45]
                    GlassButton {
                        required property int modelData
                        Layout.fillWidth: true
                        text: modelData + "m"
                        selected: timerPanel.selectedHours === 0 && timerPanel.selectedMinutes === modelData
                        onClicked: { timerPanel.selectedHours = 0; timerPanel.selectedMinutes = modelData; }
                    }
                }
            }
            GlassButton {
                Layout.fillWidth: true
                visible: !root.controller.timerFinished && root.controller.deadline <= 0
                text: "Start " + timerPanel.selectedTotal + " minute timer"
                onClicked: root.controller.startTimer(timerPanel.selectedTotal)
            }
            RowLayout {
                Layout.fillWidth: true
                visible: root.controller.deadline > 0
                GlassLabel { Layout.fillWidth: true; text: "Ends at " + Qt.formatTime(new Date(root.controller.deadline), "HH:mm"); color: Tokens.secondary }
                GlassButton { text: "+5 min"; onClicked: root.controller.addTimerMinutes(5) }
                GlassButton { text: "Cancel"; onClicked: root.controller.stopTimer() }
            }
        }
    }
    Component {
        id: system
        ColumnLayout {
            spacing: Tokens.gap
            GlassLabel {
                text: "System"
                font.pixelSize: Tokens.title
            }
            RowLayout {
                GlassButton {
                    text: "Lock"
                    onClicked: {
                        root.controller.dismiss();
                        Quickshell.execDetached(["loginctl", "lock-session"]);
                    }
                }
                GlassButton {
                    text: "Sleep"
                    onClicked: root.confirmAction = "suspend"
                }
                GlassButton {
                    text: "Restart"
                    onClicked: root.confirmAction = "reboot"
                }
                GlassButton {
                    text: "Shut down"
                    onClicked: root.confirmAction = "poweroff"
                }
            }
            RowLayout {
                visible: root.confirmAction !== ""
                GlassLabel {
                    text: "Confirm " + root.confirmAction + "?"
                    Layout.fillWidth: true
                }
                GlassButton {
                    text: "Cancel"
                    onClicked: root.confirmAction = ""
                }
                GlassButton {
                    text: "Confirm"
                    onClicked: {
                        const action = root.confirmAction;
                        root.confirmAction = "";
                        root.controller.dismiss();
                        SessionManager.exec([action]);
                    }
                }
            }
        }
    }
}
