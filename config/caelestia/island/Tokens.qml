pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property bool reducedMotion: Quickshell.env("CAELESTIA_REDUCED_MOTION") === "1"
    readonly property bool opaque: Quickshell.env("CAELESTIA_OPAQUE") === "1"
    readonly property string fontFamily: Quickshell.env("CAELESTIA_ISLAND_FONT_FAMILY") || "SF Pro Display"
    readonly property var fontFamilies: ["SF Pro Display", "SF Pro Text", fontFamily]
    readonly property int caption: 12
    readonly property int body: 13
    readonly property int title: 19
    readonly property int clock: 14
    readonly property int medium: Font.Medium
    readonly property int semibold: Font.DemiBold
    readonly property int small: 8
    readonly property int gap: 10
    readonly property int padding: 14
    readonly property int controlHeight: 32
    readonly property int compactWidth: 124
    readonly property int compactHeight: 36
    readonly property int expandedWidth: 420
    readonly property int topMargin: 8
    readonly property int radius: 24
    // Concentric interior geometry: outer radius minus content inset.
    readonly property int controlRadius: radius - padding
    readonly property real surfaceOpacity: opaque ? 1 : 0.96
    readonly property color tint: "#080809"
    readonly property color surface: Qt.alpha(tint, surfaceOpacity)
    readonly property color text: "#f5f5f7"
    readonly property color secondary: "#a1a1a6"
    readonly property color tertiary: "#6e6e73"
    readonly property color accent: "#8cbaff"
    readonly property color green: "#30d158"
    readonly property color amber: "#ff9f0a"
    readonly property color border: "#10ffffff"
    readonly property color separator: "#18ffffff"
    readonly property color control: "#0dffffff"
    readonly property color hover: "#18ffffff"
    readonly property color pressed: "#26ffffff"
    readonly property color selected: "#20ffffff"
    readonly property color shadow: "#000000"
    readonly property real borderWidth: 0.35
    readonly property int shadowBlur: 28
    readonly property real shadowOpacity: 0.42
    readonly property int shadowOffset: 5
    // The compositor provides background blur; foreground text stays sharp.
    readonly property int backdropBlur: 3
    readonly property int fast: reducedMotion ? 0 : 120
    readonly property int duration: reducedMotion ? 0 : 240
    readonly property int morph: reducedMotion ? 0 : 300
    readonly property real spring: 3.2
    readonly property real damping: 0.36
    readonly property int easing: Easing.OutCubic
    readonly property int morphEasing: Easing.OutQuint
    readonly property int transientDuration: 2400
}
