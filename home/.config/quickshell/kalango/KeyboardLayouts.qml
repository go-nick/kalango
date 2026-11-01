// Keyboard layouts from KDE (org.kde.keyboard over D-Bus): the configured list,
// the current one, and switching. Follows changes made anywhere else
// (Meta+Alt+K, System Settings) by listening to KDE's signals.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ code: "br", variant: "", name: "Portuguese (Brazil)" }, ...]
    property var layouts: []
    property int current: 0
    readonly property var active: layouts[current] ?? null

    readonly property var call: ["busctl", "--user", "--json=short", "call",
                                 "org.kde.keyboard", "/Layouts", "org.kde.KeyboardLayouts"]

    function set(index) {
        Quickshell.execDetached(call.concat(["setLayout", "u", String(index)]));
    }
    function next() { if (layouts.length > 1) set((current + 1) % layouts.length); }
    function previous() { if (layouts.length > 1) set((current + layouts.length - 1) % layouts.length); }
    function refresh() { list.running = true; }

    Process {
        id: list
        command: root.call.concat(["getLayoutsList"])
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.layouts = JSON.parse(text).data[0].map(l => ({ code: l[0], variant: l[1], name: l[2] }));
                } catch (e) {
                    root.layouts = [];
                }
                layout.running = true;
            }
        }
    }

    Process {
        id: layout
        command: root.call.concat(["getLayout"])
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.current = JSON.parse(text).data[0]; } catch (e) {}
            }
        }
    }

    // layoutChanged / layoutListChanged from KDE
    Process {
        running: true
        command: ["dbus-monitor", "--session", "type='signal',interface='org.kde.KeyboardLayouts'"]
        stdout: SplitParser {
            onRead: line => { if (line.includes("member=layout")) root.refresh(); }
        }
    }

    Component.onCompleted: refresh()
}
