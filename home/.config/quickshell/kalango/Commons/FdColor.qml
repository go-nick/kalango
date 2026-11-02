// Colors Flight Deck Calendar asks its host for: its "omarchy" theme uses these.
pragma Singleton

import QtQuick
import qs

QtObject {
    readonly property color background: "#000000"
    readonly property color foreground: Theme.text
    readonly property color muted: Theme.muted
    readonly property color accent: Theme.neon
    readonly property color urgent: Theme.solar
    readonly property var popups: ({ background: Theme.void_, border: Theme.pine })
}
