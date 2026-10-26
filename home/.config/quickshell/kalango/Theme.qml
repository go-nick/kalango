// kalango palette — single source of truth for shell colors.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color void_: "#0A0F14"
    readonly property color neon: "#3DFF9A"
    readonly property color blue: "#2E6BFF"
    readonly property color solar: "#FFD23F"
    readonly property color pine: "#0C322C"
    readonly property color brazil: "#002776"
    readonly property color suse: "#30BA78"
    readonly property color text: "#E6F1EC"
    readonly property color muted: "#7A8C85"

    // Translucent Void for blurred surfaces
    readonly property color glass: Qt.rgba(10 / 255, 15 / 255, 20 / 255, 0.82)
    // Tint over the blurred screen behind modal surfaces (launcher)
    readonly property color backdrop: Qt.rgba(10 / 255, 15 / 255, 20 / 255, 0.35)

    readonly property int radius: 10
    readonly property int border: 2
}
