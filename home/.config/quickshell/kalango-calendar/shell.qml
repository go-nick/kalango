//@ pragma AppId kalango-calendar
// The kalango calendar: Flight Deck Calendar in a normal app window, in place of
// Omarchy's shell. Started by ~/.local/bin/kalango-calendar. Flight Deck itself is a
// download (scripts/install-calendar.sh); this folder only answers what it asks its host.
import QtQuick
import Quickshell
import Quickshell.Io
import "flightdeck" as FlightDeck

ShellRoot {
    FloatingWindow {
        id: win
        title: "Calendar"
        implicitWidth: 1400
        implicitHeight: 900
        color: "#000000"
        // Closing the window ends the app
        onVisibleChanged: if (!visible) Qt.quit()

        // Runs calendarctl's sync in the background
        FlightDeck.Service {
            id: service
            manifest: ({ __sourceDir: Quickshell.shellPath("flightdeck") })
        }

        // Settings saved by Flight Deck's own Settings view
        FileView {
            id: saved
            path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/kalango/calendar.json"
            blockLoading: true
            blockWrites: true
            printErrors: false
        }
        function savedSettings() {
            try { return JSON.parse(saved.text()); } catch (e) { return {}; }
        }

        // Stands in for Omarchy's bar
        QtObject {
            id: host
            readonly property color foreground: "#E6F1EC"
            readonly property string fontFamily: "JetBrainsMono Nerd Font"
            readonly property QtObject shell: QtObject {
                function updateEntryInline(moduleName, entry) {
                    Quickshell.execDetached(["mkdir", "-pm", "700", saved.path.replace(/\/[^\/]*$/, "")]);
                    saved.setText(JSON.stringify(entry));
                }
            }
        }
        Item { id: anchorPoint }

        FlightDeck.Panel {
            id: calendar
            anchors.fill: parent
            bar: host
            anchorItem: anchorPoint
            calendarService: service
            settings: Object.assign({ defaultView: "today", theme: "omarchy", density: "roomy" }, win.savedSettings())
            // Flight Deck's Esc closes its panel, which here is the app
            onOpenedChanged: if (!opened) Qt.quit()
            Component.onCompleted: open()
        }
    }
}
