pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import "State.js" as State

ColumnLayout {
    id: root

    required property var controller
    property int shownMonth: Time.date.getMonth()
    property int shownYear: Time.date.getFullYear()
    property date selectedDate: Time.date
    property int direction: 1
    property real calendarOffset: 0
    property real calendarOpacity: 1

    readonly property bool selectedIsToday: selectedDate.toDateString() === Time.date.toDateString()

    function moveMonth(delta) {
        direction = delta;
        monthOut.restart();
    }

    function commitMonth(delta) {
        let next = shownMonth + delta;
        if (next < 0) {
            next = 11;
            shownYear--;
        } else if (next > 11) {
            next = 0;
            shownYear++;
        }
        shownMonth = next;
    }

    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const start = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil((((d - start) / 86400000) + 1) / 7);
    }

    function calendarCells() {
        return State.visibleMonthCells(shownYear, shownMonth);
    }

    function showToday() {
        selectedDate = Time.date;
        shownMonth = Time.date.getMonth();
        shownYear = Time.date.getFullYear();
    }

    spacing: Tokens.gap

    SequentialAnimation {
        id: monthOut
        ParallelAnimation {
            NumberAnimation { target: root; property: "calendarOffset"; to: -root.direction * 22; duration: Tokens.fast; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "calendarOpacity"; to: 0; duration: Tokens.fast }
        }
        ScriptAction { script: { root.commitMonth(root.direction); root.calendarOffset = root.direction * 22; } }
        ParallelAnimation {
            NumberAnimation { target: root; property: "calendarOffset"; to: 0; duration: Tokens.duration; easing.type: Tokens.morphEasing }
            NumberAnimation { target: root; property: "calendarOpacity"; to: 1; duration: Tokens.duration }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        GlassButton { text: "‹"; Accessible.name: "Previous month"; onClicked: root.moveMonth(-1) }
        GlassLabel {
            Layout.fillWidth: true
            text: Qt.formatDate(new Date(root.shownYear, root.shownMonth, 1), "MMMM yyyy")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Tokens.body
            font.weight: Tokens.semibold
        }
        GlassButton {
            text: "Today"
            selected: root.selectedIsToday
            onClicked: root.showToday()
        }
        GlassButton { text: "›"; Accessible.name: "Next month"; onClicked: root.moveMonth(1) }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: calendarGrid.implicitHeight
        opacity: root.calendarOpacity
        transform: Translate { x: root.calendarOffset }

        GridLayout {
            id: calendarGrid
            width: parent.width
            columns: 7
            rowSpacing: 1
            columnSpacing: 2

            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                GlassLabel {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    text: modelData
                    color: Tokens.tertiary
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10
                    font.weight: Tokens.semibold
                }
            }
            Repeater {
                model: root.calendarCells()
                Rectangle {
                    id: dayCell
                    required property var modelData
                    readonly property date date: new Date(modelData.year, modelData.month, modelData.day)
                    readonly property bool today: date.toDateString() === Time.date.toDateString()
                    readonly property bool selected: date.toDateString() === root.selectedDate.toDateString()
                    Layout.fillWidth: true
                    implicitHeight: 33
                    radius: Tokens.controlRadius
                    color: selected ? Tokens.text : dayHover.hovered ? Tokens.hover : "transparent"
                    GlassLabel {
                        anchors.centerIn: parent
                        text: dayCell.modelData.day
                        color: dayCell.selected ? Tokens.tint : dayCell.modelData.current ? Tokens.text : Tokens.tertiary
                        font.pixelSize: Tokens.body
                        font.weight: dayCell.today || dayCell.selected ? Tokens.semibold : Tokens.medium
                    }
                    Rectangle {
                        visible: dayCell.today && !dayCell.selected
                        width: 4
                        height: 4
                        radius: 2
                        color: Tokens.accent
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                    }
                    HoverHandler { id: dayHover }
                    TapHandler { onTapped: root.selectedDate = dayCell.date }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        GlassLabel { text: Qt.formatDate(root.selectedDate, "dddd, MMMM d"); font.pixelSize: Tokens.body; font.weight: Tokens.semibold; Layout.fillWidth: true }
        GlassLabel { text: "Week " + root.isoWeek(root.selectedDate); color: Tokens.tertiary; font.pixelSize: 10 }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: agendaContent.implicitHeight + 22
        radius: Tokens.controlRadius + 4
        color: Tokens.control
        ColumnLayout {
            id: agendaContent
            anchors.fill: parent
            anchors.margins: 11
            spacing: 4
            GlassLabel {
                text: root.selectedIsToday && root.controller.deadline > 0 ? "Focus timer" : "No events"
                font.weight: Tokens.semibold
            }
            GlassLabel {
                Layout.fillWidth: true
                text: root.selectedIsToday && root.controller.deadline > 0 ? "Ends at " + Qt.formatTime(new Date(root.controller.deadline), "HH:mm") : root.selectedIsToday ? "Your day is clear." : "No linked calendar events for this day."
                color: Tokens.secondary
                font.pixelSize: Tokens.caption
            }
        }
    }
}
