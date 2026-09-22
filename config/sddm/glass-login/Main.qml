import QtQuick 2.15
import QtQuick.Controls 2.15

Pane {
    id: root
    width: Screen.width
    height: Screen.height
    padding: 0
    focus: true
    property bool loginFailed: false
    property color white: "#f6f7fb"
    property color secondary: "#c8ceda"

    function login() {
        if (password.text.length > 0)
            sddm.login(users.currentValue, password.text, sessions.currentIndex);
    }

    background: Image { source: "Backgrounds/macos-blue.svg"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true }
    Rectangle { anchors.fill: parent; color: "#15040a18" }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(28, parent.height * 0.035)
        spacing: -8
        Label {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.secondary
            font.families: ["SF Pro Display", "SF Pro Text", "Inter"]
            font.pixelSize: Math.max(16, root.height * 0.023)
            font.weight: Font.DemiBold
        }
        Label {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.white
            font.families: ["SF Pro Display", "SF Pro Text", "Inter"]
            font.pixelSize: Math.max(68, root.height * 0.087)
            font.weight: Font.DemiBold
            font.letterSpacing: -2
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.height * 0.19
        spacing: 10
        Rectangle {
            width: 86; height: 86; radius: 43
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#38ffffff"
            border.width: 1; border.color: "#40ffffff"
            Label {
                anchors.centerIn: parent
                text: users.displayText ? users.displayText.charAt(0).toUpperCase() : "A"
                color: root.white
                font.families: ["SF Pro Display", "SF Pro Text", "Inter"]
                font.pixelSize: 38
                font.weight: Font.DemiBold
            }
        }
        ComboBox {
            id: users
            width: 230
            anchors.horizontalCenter: parent.horizontalCenter
            model: userModel
            currentIndex: userModel.lastIndex
            textRole: config.UseRealName === "true" ? "realName" : "name"
            valueRole: "name"
            font.families: ["SF Pro Display", "SF Pro Text", "Inter"]
            font.pixelSize: 17
            font.weight: Font.DemiBold
            contentItem: Label { text: users.displayText; color: root.white; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: users.font }
            background: Rectangle { color: "transparent" }
            indicator: Item {}
        }
        TextField {
            id: password
            width: 230; height: 38
            anchors.horizontalCenter: parent.horizontalCenter
            placeholderText: root.loginFailed ? "Incorrect password" : "Enter Password"
            placeholderTextColor: root.loginFailed ? "#ffffb4ab" : "#a9ffffff"
            color: root.white
            selectionColor: "#7097d7ff"
            horizontalAlignment: Text.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "•"
            font.families: ["SF Pro Display", "SF Pro Text", "Inter"]
            font.pixelSize: 13
            focus: true
            onAccepted: root.login()
            background: Rectangle {
                radius: height / 2
                color: "#3a5f64a0"
                border.width: password.activeFocus ? 1 : 0.5
                border.color: password.activeFocus ? "#80ffffff" : "#35ffffff"
            }
        }
    }

    ComboBox {
        id: sessions
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        width: 190; height: 36
        model: sessionModel
        currentIndex: sessionModel.lastIndex
        textRole: "name"
        font.families: ["SF Pro Display", "SF Pro Text", "Inter"]
        contentItem: Label { text: sessions.displayText; color: root.white; verticalAlignment: Text.AlignVCenter; leftPadding: 14; font: sessions.font }
        background: Rectangle { radius: 18; color: "#28000000"; border.width: 0.5; border.color: "#30ffffff" }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10
        Button {
            width: 44; height: 44; text: "↻"
            onClicked: sddm.reboot()
            contentItem: Label { text: parent.text; color: root.white; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 20 }
            background: Rectangle { radius: 22; color: parent.hovered ? "#42ffffff" : "#28000000"; border.width: 0.5; border.color: "#30ffffff" }
            ToolTip.visible: hovered; ToolTip.text: "Restart"
        }
        Button {
            width: 44; height: 44; text: "⏻"
            onClicked: sddm.powerOff()
            contentItem: Label { text: parent.text; color: root.white; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 20 }
            background: Rectangle { radius: 22; color: parent.hovered ? "#42ffffff" : "#28000000"; border.width: 0.5; border.color: "#30ffffff" }
            ToolTip.visible: hovered; ToolTip.text: "Shut Down"
        }
    }

    Timer {
        interval: 1000; repeat: true; running: true
        onTriggered: {
            const now = new Date();
            timeLabel.text = Qt.formatTime(now, "H:mm");
            dateLabel.text = Qt.formatDate(now, "ddd MMM d");
        }
    }
    Component.onCompleted: {
        const now = new Date();
        timeLabel.text = Qt.formatTime(now, "H:mm");
        dateLabel.text = Qt.formatDate(now, "ddd MMM d");
    }
    Connections {
        target: sddm
        function onLoginFailed() { root.loginFailed = true; password.clear(); password.forceActiveFocus(); }
        function onLoginSucceeded() { root.loginFailed = false; }
    }
}
