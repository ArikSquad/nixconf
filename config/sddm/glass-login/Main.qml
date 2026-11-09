import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Pane {
    id: root
    width: Screen.width
    height: Screen.height
    padding: 0
    focus: true
    property bool loginFailed: false
    property bool authenticating: false
    property color white: "#f6f7fb"
    property string clockText: ""
    property string dateText: ""

    function updateClock() {
        const now = new Date();
        clockText = Qt.formatTime(now, "H:mm");
        dateText = Qt.formatDate(now, "dddd, MMMM d");
    }

    function login() {
        if (!authenticating && password.text.length > 0 && users.currentIndex >= 0) {
            loginFailed = false;
            authenticating = true;
            sddm.login(users.currentValue, password.text, sessions.currentIndex);
        }
    }

    // Paweł Czerwiński, Unsplash License: https://unsplash.com/photos/VhG_oPx5CEY
    background: Image {
        source: "Backgrounds/blue-waves.jpg"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#65071328" }
            GradientStop { position: 0.5; color: "#40071328" }
            GradientStop { position: 1; color: "#95071328" }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(24, root.height * 0.065)
        spacing: 0
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: "#edffffff"
            font.family: "Inter"
            font.pixelSize: Math.max(16, Math.min(25, root.height * 0.025))
            font.weight: Font.Medium
        }
        Item {
            width: clockFace.implicitWidth + 16
            height: clockFace.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
            Text {
                id: clockFace
                anchors.centerIn: parent
                text: root.clockText
                font.family: "Inter"
                font.pixelSize: Math.max(72, Math.min(160, root.height * 0.15))
                font.weight: Font.DemiBold
                font.letterSpacing: -5
                color: "#65ffffff"
                style: Text.Outline
                styleColor: "#a0ffffff"
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#40061736"
                    shadowBlur: 0.6
                    shadowVerticalOffset: 5
                }
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: root.clockText
                font: clockFace.font
                color: "transparent"
                style: Text.Raised
                styleColor: "#50ffffff"
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.min(150, root.height * 0.17)
        spacing: 12
        Rectangle {
            width: 72; height: 72; radius: 36
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#26ffffff"
            border.color: "#60ffffff"
            Label {
                anchors.centerIn: parent
                text: users.displayText ? users.displayText.charAt(0).toUpperCase() : ""
                color: root.white
                font.family: "Inter"
                font.pixelSize: 30
                font.weight: Font.Medium
            }
        }
        ComboBox {
            id: users
            width: 248; height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            model: userModel
            currentIndex: userModel.lastIndex
            textRole: config.UseRealName === "true" ? "realName" : "name"
            valueRole: "name"
            enabled: !root.authenticating
            font.family: "Inter"
            font.pixelSize: 18
            font.weight: Font.DemiBold
            onActivated: { password.clear(); root.loginFailed = false; password.forceActiveFocus(); }
            contentItem: Label {
                text: users.displayText
                color: root.white
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: users.font
            }
            background: Rectangle { radius: 16; color: users.hovered && users.count > 1 ? "#18ffffff" : "transparent" }
            indicator: Item {}
            Accessible.name: "Account"
        }
        TextField {
            id: password
            width: 248; height: 42
            anchors.horizontalCenter: parent.horizontalCenter
            placeholderText: root.authenticating ? "Signing in…" : "Password"
            placeholderTextColor: "#c4ffffff"
            color: root.white
            selectionColor: "#7097d7ff"
            leftPadding: 18
            rightPadding: 44
            echoMode: TextInput.Password
            passwordCharacter: "•"
            font.family: "Inter"
            font.pixelSize: 14
            focus: true
            enabled: !root.authenticating
            onAccepted: root.login()
            onTextEdited: root.loginFailed = false
            Accessible.name: "Password"
            background: Rectangle {
                radius: height / 2
                color: password.activeFocus ? "#40ffffff" : "#28ffffff"
                border.width: 1
                border.color: root.loginFailed ? "#ffe1b5b1" : password.activeFocus ? "#a0ffffff" : "#50ffffff"
                Behavior on color { ColorAnimation { duration: 160 } }
            }
            Button {
                id: signIn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 6
                width: 30; height: 30
                text: "→"
                enabled: password.text.length > 0 && !root.authenticating
                onClicked: root.login()
                Accessible.name: "Sign in"
                contentItem: Label {
                    text: signIn.text
                    color: root.white
                    opacity: signIn.enabled ? 1 : 0.4
                    font.pixelSize: 21
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { radius: 15; color: signIn.hovered || signIn.visualFocus ? "#50ffffff" : "#20ffffff" }
            }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.loginFailed ? "Incorrect password. Try again." : ""
            color: "#ffe1d4"
            font.family: "Inter"
            font.pixelSize: 12
            Accessible.role: Accessible.AlertMessage
        }
    }

    Button {
        id: options
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        width: 40; height: 40
        text: "···"
        Accessible.name: "Login options"
        onClicked: optionsMenu.open()
        contentItem: Label {
            text: options.text
            color: root.white
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 20
            color: options.hovered || options.visualFocus ? "#40ffffff" : "#18ffffff"
            border.color: "#40ffffff"
        }
        ToolTip.visible: hovered
        ToolTip.text: "Login options"
        Menu {
            id: optionsMenu
            x: options.width - width
            y: -height - 10
            width: 240
            MenuItem { text: "Session"; enabled: false }
            ComboBox {
                id: sessions
                width: parent.width
                model: sessionModel
                currentIndex: sessionModel.lastIndex
                textRole: "name"
                enabled: !root.authenticating
                Accessible.name: "Desktop session"
            }
            MenuSeparator {}
            MenuItem { text: "Restart"; enabled: sddm.canReboot; onTriggered: sddm.reboot() }
            MenuItem { text: "Shut Down"; enabled: sddm.canPowerOff; onTriggered: sddm.powerOff() }
        }
    }

    Timer { interval: 1000; repeat: true; running: true; onTriggered: root.updateClock() }
    Component.onCompleted: root.updateClock()
    Connections {
        target: sddm
        function onLoginFailed() {
            root.authenticating = false;
            root.loginFailed = true;
            password.clear();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { root.loginFailed = false; }
    }
}
