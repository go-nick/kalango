// Font and sizes Flight Deck Calendar asks its host for.
pragma Singleton

import QtQuick

QtObject {
    readonly property var font: ({ family: "JetBrainsMono Nerd Font", body: 14, bodySmall: 14, caption: 12, title: 18 })
    function space(value) { return Number(value); }
}
