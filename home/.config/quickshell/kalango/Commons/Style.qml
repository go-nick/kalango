// Sizes and font Flight Deck Calendar asks its host for. Sizes are its own test values.
pragma Singleton

import QtQuick

QtObject {
    readonly property var font: ({ family: "JetBrainsMono Nerd Font", body: 12, bodySmall: 12, caption: 10, title: 14 })
    function space(value) { return Number(value); }
}
