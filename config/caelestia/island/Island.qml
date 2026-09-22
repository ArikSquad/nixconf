pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services

Scope {
    FontLoader {
        id: islandFont
        source: Quickshell.env("CAELESTIA_ISLAND_FONT")
    }
    Controller {
        id: islandController
    }
    Binding {
        target: IslandBridge
        property: "controller"
        value: islandController
    }
    Variants {
        model: Screens.screens
        Scope {
            required property ShellScreen modelData
            IslandWindow {
                screen: modelData
                controller: islandController
            }
            ActivePillWindow {
                screen: modelData
                targetScreenName: modelData.name
            }
            TrayWindow {
                screen: modelData
                targetScreenName: modelData.name
            }
            LauncherWindow {
                screen: modelData
            }
        }
    }
}
