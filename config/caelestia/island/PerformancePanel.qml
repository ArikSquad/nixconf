pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config as CConfig
import Caelestia.Services
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property bool detailsVisible: false
    readonly property var battery: UPower.displayDevice
    readonly property var disk: Storage.primaryDisk

    function percent(value) {
        return isNaN(value) ? "—" : Math.round(value * 100) + "%";
    }

    function temp(value) {
        return !value || isNaN(value) ? "Sensor unavailable" : Math.round(value) + "°C";
    }

    function bytes(kibibytes) {
        const gib = Number(kibibytes || 0) / 1024 / 1024;
        return gib >= 1024 ? (gib / 1024).toFixed(1) + " TB" : gib.toFixed(gib >= 100 ? 0 : 1) + " GB";
    }

    function speed(value) {
        const n = Number(value || 0);
        if (n >= 1024 * 1024)
            return (n / 1024 / 1024).toFixed(1) + " MB/s";
        if (n >= 1024)
            return (n / 1024).toFixed(0) + " KB/s";
        return Math.round(n) + " B/s";
    }

    spacing: Tokens.gap

    ServiceRef { service: Cpu }
    ServiceRef { service: Gpu }
    ServiceRef { service: Memory }
    ServiceRef { service: Storage }
    ServiceRef { service: NetworkUsage }

    RowLayout {
        Layout.fillWidth: true
        GlassLabel { text: "System activity"; font.pixelSize: Tokens.title; font.weight: Tokens.semibold; Layout.fillWidth: true }
        GlassButton { text: root.detailsVisible ? "Less" : "Details"; onClicked: root.detailsVisible = !root.detailsVisible }
    }
    GlassLabel {
        Layout.fillWidth: true
        text: Nmcli.isConnected ? (Nmcli.activeConnection || "Connected") : "Offline"
        color: Nmcli.isConnected ? Tokens.secondary : Tokens.amber
        font.pixelSize: Tokens.caption
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Tokens.small
        rowSpacing: Tokens.small

        MetricCard {
            Layout.fillWidth: true
            label: "CPU"
            valueText: root.percent(Cpu.percentage)
            detail: root.temp(Cpu.temperature)
            value: Cpu.percentage
            accent: Tokens.accent
        }
        MetricCard {
            Layout.fillWidth: true
            label: "GPU"
            valueText: Gpu.detecting ? "Detecting" : root.percent(Gpu.percentage)
            detail: Gpu.type === CConfig.GpuType.None ? "No GPU telemetry" : root.temp(Gpu.temperature)
            value: Gpu.percentage
            accent: Tokens.green
        }
        MetricCard {
            Layout.fillWidth: true
            label: "Memory"
            valueText: root.percent(Memory.percentage)
            detail: root.detailsVisible ? "Working memory in use" : ""
            value: Memory.percentage
            accent: Tokens.amber
        }
        MetricCard {
            Layout.fillWidth: true
            label: "Storage"
            valueText: root.percent(root.disk?.perc ?? Storage.percentage)
            detail: root.disk ? root.bytes(root.disk.used) + " of " + root.bytes(root.disk.total) : "Scanning disks"
            value: root.disk?.perc ?? Storage.percentage
            accent: Tokens.secondary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: networkColumn.implicitHeight + 24
        radius: Tokens.controlRadius + 4
        color: Tokens.control
        border.width: Tokens.borderWidth
        border.color: Tokens.separator
        ColumnLayout {
            id: networkColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                GlassLabel { text: "Network"; color: Tokens.secondary; font.pixelSize: Tokens.caption; Layout.fillWidth: true }
                GlassLabel { text: "↓ " + root.speed(NetworkUsage.downloadSpeed) + "   ↑ " + root.speed(NetworkUsage.uploadSpeed); font.pixelSize: Tokens.caption }
            }
            Sparkline {
                Layout.fillWidth: true
                values: NetworkUsage.downloadBuffer.values
                lineColor: Tokens.accent
            }
            GlassLabel {
                visible: root.detailsVisible
                text: "Session totals  ↓ " + root.speed(NetworkUsage.downloadTotal).replace("/s", "") + "   ↑ " + root.speed(NetworkUsage.uploadTotal).replace("/s", "")
                color: Tokens.tertiary
                font.pixelSize: 10
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.battery.isLaptopBattery
        implicitHeight: batteryRow.implicitHeight + 24
        radius: Tokens.controlRadius + 4
        color: Tokens.control
        RowLayout {
            id: batteryRow
            anchors.fill: parent
            anchors.margins: 12
            GlassLabel { text: "Battery"; color: Tokens.secondary; Layout.fillWidth: true }
            GlassLabel {
                text: {
                    const pct = Math.round(root.battery.percentage * 100) + "%";
                    if (!UPower.onBattery)
                        return pct + " · Power connected";
                    const seconds = root.battery.timeToEmpty;
                    return pct + (seconds > 0 ? " · " + Math.floor(seconds / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "m" : " · On battery");
                }
                font.weight: Tokens.semibold
            }
        }
    }
}
