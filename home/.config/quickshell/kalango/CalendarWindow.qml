// Hosts Flight Deck Calendar under the bar, in place of Omarchy's shell.
// Close with the clock, Esc or a click outside.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "flightdeck" as FlightDeck

PanelWindow {
    id: win

    screen: Calendar.screen
    visible: Calendar.open
    anchors { top: true; bottom: true; left: true; right: true }
    // Below the bar
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "kalango-calendar"
    // On demand, not exclusive: signing in happens in the browser
    WlrLayershell.keyboardFocus: Calendar.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property int margin: 10

    Binding { target: Calendar; property: "maxWidth"; value: win.width - 2 * win.margin }
    Binding { target: Calendar; property: "maxHeight"; value: win.height - 2 * win.margin }

    MouseArea {
        anchors.fill: parent
        onClicked: Calendar.open = false
    }

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
        readonly property color foreground: Theme.text
        readonly property string fontFamily: "JetBrainsMono Nerd Font"
        readonly property QtObject shell: QtObject {
            function updateEntryInline(moduleName, entry) {
                Quickshell.execDetached(["mkdir", "-pm", "700", saved.path.replace(/\/[^\/]*$/, "")]);
                saved.setText(JSON.stringify(entry));
            }
        }
    }
    Item { id: anchorPoint }

    ClippingRectangle {
        id: frame
        x: win.margin
        y: win.margin
        width: calendar.childrenRect.width
        height: calendar.childrenRect.height
        radius: Theme.radius
        color: "#000000"
        border.width: 1
        border.color: Theme.pine

        // Clicks inside must not reach the close area
        MouseArea { anchors.fill: parent }

        FlightDeck.Panel {
            id: calendar
            anchors.fill: parent
            bar: host
            anchorItem: anchorPoint
            calendarService: service
            settings: Object.assign({ defaultView: "today", theme: "omarchy" }, win.savedSettings())
            onOpenedChanged: if (!opened) Calendar.open = false
        }
    }

    Connections {
        target: Calendar
        function onOpenChanged() { Calendar.open ? calendar.open() : calendar.close(); }
    }
    Component.onCompleted: if (Calendar.open) calendar.open()
}
