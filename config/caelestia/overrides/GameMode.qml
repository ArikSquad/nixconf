import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.services

Scope {
    id: root

    readonly property bool enabled: RuntimeState.gameMode
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

    Connections {
        function onConfigReloaded(): void {
            if (root.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return RuntimeState.gameMode;
        }

        function toggle(): void {
            RuntimeState.gameMode = !RuntimeState.gameMode;
        }

        function enable(): void {
            RuntimeState.gameMode = true;
        }

        function disable(): void {
            RuntimeState.gameMode = false;
        }

        target: "gameMode"
    }
}
