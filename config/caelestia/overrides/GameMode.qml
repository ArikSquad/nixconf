pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled
    property int previousPowerProfile: PowerProfile.Balanced
    property bool hasSavedPowerProfile: false

    function setDynamicConfs(): void {
        Hypr.extras.applyOptions({
            "animations:enabled": 0,
            "decoration:shadow:enabled": 0,
            "decoration:blur:enabled": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": 1
        });
    }

    onEnabledChanged: {
        if (enabled) {
            setDynamicConfs();
            if (PowerProfiles.hasPerformanceProfile) {
                previousPowerProfile = PowerProfiles.profile;
                hasSavedPowerProfile = true;
                PowerProfiles.profile = PowerProfile.Performance;
            }
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode enabled"), Tr.tr("Reduced Hyprland effects and selected the performance power profile when available"), "gamepad");
        } else {
            Hypr.extras.message("reload");
            if (hasSavedPowerProfile && PowerProfiles.hasPerformanceProfile)
                PowerProfiles.profile = previousPowerProfile;
            hasSavedPowerProfile = false;
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode disabled"), Tr.tr("Hyprland settings and power profile restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: Hypr.options["animations:enabled"] === 0 // qmllint disable missing-property

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
