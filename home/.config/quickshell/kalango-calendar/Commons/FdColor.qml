// Colors Flight Deck Calendar asks its host for: its "omarchy" theme uses these.
// The kalango palette, from the shell's Theme.qml; this app runs on its own.
pragma Singleton

import QtQuick

QtObject {
    readonly property color background: "#000000"
    readonly property color foreground: "#E6F1EC"
    readonly property color muted: "#7A8C85"
    readonly property color accent: "#3DFF9A"
    readonly property color urgent: "#FFD23F"
    readonly property var popups: ({ background: "#0A0F14", border: "#0C322C" })
}
