pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import "Lyrics.js" as Lyrics

PanelWindow {
    id: root
    required property var controller
    required property string targetScreenName
    readonly property var player: Players.active
    readonly property string trackKey: JSON.stringify([player?.trackTitle, player?.trackArtist, player?.trackAlbum, player?.lengthSupported ? player.length : 0])
    property var request: null
    property var lines: []
    property string plain: ""
    property string status: ""
    property bool loading: false
    property real position: 0
    property real rightInset: 32
    property real topInset: 88
    readonly property int scrollDuration: Tokens.reducedMotion ? 0 : 420
    readonly property int currentLine: Lyrics.activeLine(lines, position)
    readonly property bool synced: lines.length > 0 && (player?.positionSupported ?? false)
    visible: controller.lyricsVisible && controller.lyricsScreen === targetScreenName
    color: "transparent"
    anchors.top: true
    anchors.right: true
    margins.top: Math.max(0, Math.min(topInset, screen.height - implicitHeight))
    margins.right: Math.max(0, Math.min(rightInset, screen.width - implicitWidth))
    implicitWidth: Math.min(440, screen.width)
    implicitHeight: Math.min(440, screen.height)
    exclusiveZone: 0
    WlrLayershell.namespace: "caelestia-island-lyrics"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function reload() {
        requestTimeout.stop();
        const previous = request; request = null;
        if (previous) previous.abort();
        lines = []; plain = ""; status = ""; loading = false;
        if (!visible) return;
        if (!player?.trackTitle || !player?.trackArtist) {
            status = "Play a song with a title and artist to find lyrics.";
            return;
        }
        loading = true;
        const key = trackKey;
        const xhr = new XMLHttpRequest();
        request = xhr;
        let url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(player.trackTitle)
            + "&artist_name=" + encodeURIComponent(player.trackArtist);
        if (player.trackAlbum) url += "&album_name=" + encodeURIComponent(player.trackAlbum);
        if (player.lengthSupported && player.length > 0) url += "&duration=" + Math.round(player.length);
        xhr.open("GET", url);
        xhr.setRequestHeader("X-User-Agent", "Caelestia Island (https://github.com/ArikSquad/nixdots)");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || root.request !== xhr || root.trackKey !== key) return;
            requestTimeout.stop(); root.loading = false; root.request = null;
            if (xhr.status !== 200) {
                root.status = xhr.status === 404 ? "No lyrics found for this song." : "Could not reach the lyrics service.";
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                if (!data || typeof data !== "object" || Array.isArray(data))
                    throw new Error("Unexpected lyrics response format");
                const syncedLyrics = typeof data.syncedLyrics === "string" ? data.syncedLyrics : "";
                const plainLyrics = typeof data.plainLyrics === "string" ? data.plainLyrics : "";
                root.lines = Lyrics.parse(syncedLyrics, root.player?.lengthSupported ? root.player.length : 0);
                root.plain = plainLyrics || root.lines.map(line => line.text).join("\n");
                root.status = data.instrumental ? "Instrumental · let the music speak." : !root.lines.length && !root.plain ? "No lyrics found for this song." : "";
            } catch (_) { root.status = "Could not read lyrics from the service. Try again."; }
        };
        xhr.send(); requestTimeout.restart();
    }
    onTrackKeyChanged: fetchDelay.restart()
    onVisibleChanged: {
        if (visible) { position = player?.position ?? 0; reload(); entrance.restart(); }
        else { requestTimeout.stop(); const previous = request; request = null; if (previous) previous.abort(); }
    }
    onCurrentLineChanged: if (synced && currentLine >= 0) Qt.callLater(function() { lyricList.centerCurrentLine(); })
    Timer { id: fetchDelay; interval: 250; onTriggered: root.reload() }
    Timer {
        id: requestTimeout; interval: 15000
        onTriggered: {
            const pending = root.request; root.request = null;
            if (pending) pending.abort();
            root.loading = false; root.status = "Lyrics lookup timed out. Try again.";
        }
    }
    Timer {
        interval: 16; repeat: true; running: root.visible
        onTriggered: root.position = root.player?.position ?? 0
    }
    Glass {
        id: surface
        anchors.fill: parent
        anchors.margins: 10
        radius: 28
        NumberAnimation { id: entrance; target: surface; property: "opacity"; from: 0; to: 1; duration: Tokens.duration }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 22; spacing: 14
            RowLayout {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true; implicitHeight: 42
                    Column {
                        anchors.fill: parent; spacing: 3
                        Text { width: parent.width; text: root.player?.trackTitle || "Lyrics"; elide: Text.ElideRight; color: Tokens.text; font.family: Tokens.fontFamily; font.pixelSize: 15; font.weight: Tokens.semibold }
                        Text { width: parent.width; text: root.player?.trackArtist || "Nothing playing"; elide: Text.ElideRight; color: Tokens.secondary; font.family: Tokens.fontFamily; font.pixelSize: 11 }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.SizeAllCursor
                        property point origin
                        property real startRight
                        property real startTop
                        onPressed: mouse => { origin = mapToGlobal(mouse.x, mouse.y); startRight = root.rightInset; startTop = root.topInset; }
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            const point = mapToGlobal(mouse.x, mouse.y);
                            root.rightInset = Math.max(0, Math.min(root.screen.width - root.width, startRight - point.x + origin.x));
                            root.topInset = Math.max(0, Math.min(root.screen.height - root.height, startTop + point.y - origin.y));
                        }
                        Accessible.name: "Drag lyrics window"
                    }
                }
                GlassButton { text: "×"; Accessible.name: "Close lyrics"; onClicked: root.controller.lyricsVisible = false }
            }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                ListView {
                    id: lyricList
                    anchors.fill: parent; clip: true; spacing: 20
                    visible: root.synced
                    model: root.lines
                    boundsBehavior: Flickable.StopAtBounds
                    header: Item { height: lyricList.height * 0.35 }
                    footer: Item { height: lyricList.height * 0.35 }
                    function centerCurrentLine() {
                        if (root.currentLine < 0) return;
                        const item = lyricList.itemAtIndex(root.currentLine);
                        if (!item) {
                            lyricList.positionViewAtIndex(root.currentLine, ListView.Center);
                            return;
                        }
                        const target = Math.max(0, Math.min(lyricList.contentHeight - lyricList.height,
                            item.y + item.height / 2 - lyricList.height / 2));
                        scrollAnimation.stop();
                        scrollAnimation.to = target;
                        scrollAnimation.restart();
                    }
                    NumberAnimation {
                        id: scrollAnimation
                        target: lyricList; property: "contentY"
                        duration: root.scrollDuration
                        easing.type: Easing.OutCubic
                    }
                    delegate: Item {
                        id: lineItem
                        required property var modelData
                        required property int index
                        readonly property bool active: index === root.currentLine
                        width: lyricList.width
                        height: modelData.words.length ? wordFlow.implicitHeight : lineText.implicitHeight
                        opacity: active ? 1 : 0.28
                        scale: active ? 1 : 0.96
                        transformOrigin: Item.Left
                        Behavior on opacity { NumberAnimation { duration: Tokens.duration } }
                        Behavior on scale { NumberAnimation { duration: Tokens.duration; easing.type: Easing.OutCubic } }
                        Text {
                            id: lineText; width: parent.width
                            visible: !lineItem.modelData.words.length
                            text: lineItem.modelData.text || "♪"
                            textFormat: Text.PlainText; wrapMode: Text.Wrap
                            color: Tokens.text; font.family: Tokens.fontFamily; font.pixelSize: 25; font.weight: Tokens.semibold
                        }
                        Flow {
                            id: wordFlow; width: parent.width; spacing: 7
                            visible: lineItem.modelData.words.length > 0
                            Repeater {
                                model: lineItem.modelData.words
                                Text {
                                    required property var modelData
                                    readonly property real progress: Math.max(0, Math.min(1,
                                        (root.position - modelData.time) / Math.max(0.08, modelData.endTime - modelData.time)))
                                    readonly property bool activeWord: lineItem.active && root.position >= modelData.time && root.position < modelData.endTime
                                    text: modelData.text; textFormat: Text.PlainText
                                    color: activeWord ? Tokens.accent : root.position >= modelData.endTime ? Tokens.text : Tokens.secondary
                                    scale: activeWord && !Tokens.reducedMotion ? 1 + 0.05 * Math.sin(Math.PI * progress) : 1
                                    transformOrigin: Item.Center
                                    transform: Translate {
                                        y: activeWord && !Tokens.reducedMotion ? -6 * Math.sin(Math.PI * progress) : 0
                                        Behavior on y { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
                                    }
                                    font.family: Tokens.fontFamily; font.pixelSize: 25; font.weight: Tokens.semibold
                                    Behavior on color { ColorAnimation { duration: Tokens.fast } }
                                    Behavior on scale { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
                                }
                            }
                        }
                        layer.enabled: active && !Tokens.reducedMotion
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Tokens.accent; shadowBlur: 0.7; shadowOpacity: 0.35; shadowVerticalOffset: 0 }
                        TapHandler { enabled: root.player?.canSeek ?? false; onTapped: root.player.position = lineItem.modelData.time }
                    }
                }
                ScrollView {
                    anchors.fill: parent; visible: !root.synced && root.plain.length > 0
                    TextArea { readOnly: true; text: root.plain; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Tokens.text; font.family: Tokens.fontFamily; font.pixelSize: 22; background: null; selectByMouse: true }
                }
                Column {
                    anchors.centerIn: parent; width: parent.width; spacing: 14
                    visible: root.loading || root.status.length > 0
                    Text { width: parent.width; text: root.loading ? "Finding lyrics…" : root.status; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; color: Tokens.secondary; font.family: Tokens.fontFamily; font.pixelSize: 16 }
                    GlassButton { anchors.horizontalCenter: parent.horizontalCenter; visible: !root.loading && !!root.player?.trackTitle; text: "Try again"; onClicked: root.reload() }
                }
            }
        }
    }
}
