pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import qs.services
import "State.js" as State

Scope {
    id: root
    readonly property bool microphoneActive: Pipewire.links.values.some(link => link.state === PwLinkState.Active && link.target?.isStream && link.target?.isSink && !!link.target?.audio && !link.source?.isStream && !link.source?.isSink && !link.source?.audio?.muted)
    // Only report camera use when PipeWire exposes an active camera-to-app link.
    readonly property bool cameraActive: Pipewire.links.values.some(link => link.state === PwLinkState.Active && link.target?.isStream && !link.source?.isStream && link.source?.properties["media.class"] === "Video/Source" && !!link.source?.properties["device.api"])
    PwObjectTracker {
        objects: [...Pipewire.nodes.values, ...Pipewire.links.values]
    }
    onMicrophoneActiveChanged: pulse("microphone")
    onCameraActiveChanged: pulse("microphone")
    Connections {
        target: Bluetooth.defaultAdapter
        function onEnabledChanged() {
            root.pulse("network");
        }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.pulse("controls");
        }
    }
    property string page: "idle"
    property string eventMode: ""
    property bool ready: false
    property bool greetingShown: false
    property string bootDuration: ""
    property double deadline: 0
    property double now: Date.now()
    property int timerDurationMinutes: 25
    property bool timerFinished: false
    readonly property int secondsLeft: State.remaining(deadline, now)
    property var popup: null
    function refreshPopup() {
        popup = Notifs.dnd ? null : Notifs.popups.find(n => !n.closed) ?? null;
    }
    Component.onCompleted: refreshPopup()
    Connections {
        target: Notifs
        function onPopupsChanged() {
            Qt.callLater(root.refreshPopup);
        }
        function onDndChanged() {
            Qt.callLater(root.refreshPopup);
        }
    }
    readonly property string mode: State.resolve(page, eventMode, popup)
    readonly property bool expanded: mode !== "idle"
    function open(next) {
        if (State.validPage(next))
            page = next;
    }
    function dismiss() {
        if (popup)
            popup.popup = false;
        eventMode = "";
        page = "idle";
    }
    function pulse(kind) {
        if (!ready)
            return;
        eventMode = kind;
        timeout.restart();
    }
    function greetingForHour(hour) {
        if (hour >= 5 && hour < 12)
            return "Good morning";
        if (hour >= 12 && hour < 17)
            return "Good afternoon";
        if (hour >= 17 && hour < 22)
            return "Good evening";
        return "Good night";
    }
    function showGreeting() {
        if (greetingShown || popup)
            return;
        greetingShown = true;
        eventMode = "greeting";
        greetingTimer.restart();
    }
    function startTimer(minutes) {
        timerDurationMinutes = Math.max(1, Math.min(1440, Math.round(minutes)));
        timerFinished = false;
        deadline = Date.now() + timerDurationMinutes * 60000;
        now = Date.now();
        open("timer");
    }
    function addTimerMinutes(minutes) {
        timerFinished = false;
        deadline = Math.max(Date.now(), deadline) + minutes * 60000;
        now = Date.now();
        open("timer");
    }
    function stopTimer() {
        deadline = 0;
        timerFinished = false;
        now = Date.now();
    }
    Timer {
        interval: 1200
        running: true
        onTriggered: {
            root.ready = true;
            root.showGreeting();
        }
    }
    Timer {
        id: greetingTimer
        interval: 4600
        onTriggered: if (root.eventMode === "greeting")
            root.eventMode = ""
    }
    Timer {
        id: timeout
        interval: Tokens.transientDuration
        onTriggered: root.eventMode = ""
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.deadline > 0
        onTriggered: {
            root.now = Date.now();
            if (root.secondsLeft === 0) {
                root.deadline = 0;
                root.timerFinished = true;
                root.open("timer");
                Quickshell.execDetached(["notify-send", "Timer complete", "Done. Add a few minutes or start another timer."]);
            }
        }
    }
    Connections {
        target: Audio
        function onVolumeChanged() {
            root.pulse("volume");
        }
        function onMutedChanged() {
            root.pulse("volume");
        }
        function onSourceMutedChanged() {
            root.pulse("microphone");
        }
    }
    Process {
        running: true
        command: ["systemd-analyze", "time"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/=\s*([0-9.]+)(ms|s|min)/);
                if (!match)
                    return;
                let seconds = Number(match[1]);
                if (match[2] === "ms")
                    seconds /= 1000;
                else if (match[2] === "min")
                    seconds *= 60;
                root.bootDuration = seconds.toFixed(1) + " seconds";
            }
        }
    }
    Connections {
        target: Players.active
        function onTrackTitleChanged() {
            if (Players.active?.trackTitle)
                root.pulse("media");
        }
    }
    Connections {
        target: Nmcli
        function onActiveConnectionChanged() {
            root.pulse("network");
        }
    }
    IpcHandler {
        target: "island"
        function open(page: string): void {
            root.open(page);
        }
        function close(): void {
            root.dismiss();
        }
        function timer(minutes: int): void {
            if (minutes > 0 && minutes <= 1440)
                root.startTimer(minutes);
        }
    }
}
