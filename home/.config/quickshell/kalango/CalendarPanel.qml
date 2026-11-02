// The calendar, opened by the bar's clock.
//   qs -c kalango ipc call calendar calendarToggle
// Loaded on first use, and from its own file: Flight Deck is a download
// (scripts/install-calendar.sh), and the shell must survive it being missing.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "calendar"
        function calendarToggle(): void { Calendar.toggle(Calendar.screen || Quickshell.screens[0]); }
    }

    property bool used: false
    Connections {
        target: Calendar
        function onOpenChanged() { if (Calendar.open) root.used = true; }
    }

    Loader {
        active: root.used
        source: "CalendarWindow.qml"
    }
}
