// kalango launcher (Meta+Space) — Omarchy-style menu of task categories
// (Apps, Learn, Appearance, Trigger, Settings, Software, System) filled with openSUSE/KDE tools.
// Typing at the top searches everything; inside a category it searches that category.
// Opens on the active monitor (the compositor picks the screen).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "MenuModel.js" as Menu

Scope {
    id: root

    property bool open: false
    property string startAt: "root"

    // IPC names are prefixed (metaLauncher*) so they can never collide with
    // `qs ipc` subcommands (show, call, wait, listen, prop):
    //   qs -c kalango ipc call launcher metaLauncherToggle
    //   qs -c kalango ipc call launcher metaLauncherOpenAt system
    IpcHandler {
        target: "launcher"

        function metaLauncherToggle(): void { root.startAt = "root"; root.open = !root.open; }
        function metaLauncherOpen(): void { root.startAt = "root"; root.open = true; }
        function metaLauncherOpenAt(id: string): void { root.startAt = id; root.open = true; }
        function metaLauncherClose(): void { root.open = false; }
        function metaLauncherIsOpen(): bool { return root.open; }
    }

    // Rank `label` (+ secondary text) against the query: higher is better, -1 means no match.
    function score(label, extra, q) {
        const name = label.toLowerCase();
        if (name.startsWith(q)) return 100;
        if (name.split(/[\s\-_.&]+/).some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        if (extra.toLowerCase().includes(q)) return 30;
        // Loose subsequence: "frx" matches "Firefox"
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 10 : -1;
    }

    function apps() {
        // YaST2-groups-* are YaST control-center group headers, not launchable apps
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !e.id.startsWith("YaST2-groups-"));
    }

    function run(spec) {
        if (spec.kcm) Quickshell.execDetached(["systemsettings", spec.kcm]);
        else if (spec.desktop) {
            const e = DesktopEntries.byId(spec.desktop);
            if (e) e.execute();
        }
        else if (spec.cmd) {
            const home = Quickshell.env("HOME");
            Quickshell.execDetached(spec.cmd.map(a => a.startsWith("~/") ? home + a.slice(1) : a));
        }
        else if (spec.sh) Quickshell.execDetached(["bash", "-c", spec.sh]);
        else if (spec.url) Quickshell.execDetached(["xdg-open", spec.url]);
        else if (spec.terminal)
            Quickshell.execDetached(["konsole", "-e", "bash", "-c",
                spec.terminal + "; echo; read -rp 'Done. Press Enter to close…'"]);
        else if (spec.shortcut)
            Quickshell.execDetached(["qdbus6", "org.kde.kglobalaccel", "/component/" + spec.shortcut[0],
                "org.kde.kglobalaccel.Component.invokeShortcut", spec.shortcut[1]]);
    }

    // Shortcut-style actions must hit the window that was focused before the
    // launcher opened, so run them after the launcher has closed.
    Timer {
        id: deferred
        property var spec
        interval: 150
        onTriggered: root.run(spec)
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win

            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "kalango-launcher"
            BackgroundEffect.blurRegion: Region { item: panel; radius: Theme.radius }

            readonly property var tree: Menu.build(root.apps())
            // Navigation stack of menu nodes; last element is the current one
            property var stack: Menu.pathTo(tree, root.startAt) || [tree]
            readonly property var node: stack[stack.length - 1]
            property var confirming: null

            readonly property var rows: {
                const q = input.text.trim().toLowerCase();
                if (q === "") return node.children.map(c => ({ item: c, path: [] }));
                // Search every leaf below the current node; apps appear in several
                // categories, so keep each one once
                const seen = {};
                return Menu.leaves(node)
                    .filter(r => {
                        const key = r.item.entry ? "app:" + r.item.entry.id : r.path.join("/") + "/" + r.item.label;
                        if (seen[key]) return false;
                        return (seen[key] = true);
                    })
                    .map(r => ({ r: r, s: root.score(r.item.label, (r.item.hint || "") + " " + r.path.join(" "), q) }))
                    .filter(x => x.s >= 0)
                    .sort((a, b) => b.s - a.s || a.r.item.label.localeCompare(b.r.item.label))
                    .slice(0, 50)
                    .map(x => x.r);
            }

            function enter(item) {
                stack = stack.concat([item]);
                input.text = "";
                list.currentIndex = 0;
                confirming = null;
            }

            function back() {
                if (stack.length > 1) {
                    stack = stack.slice(0, -1);
                    list.currentIndex = 0;
                    confirming = null;
                }
            }

            function activate(row) {
                if (!row) return;
                const item = row.item;
                if (item.children) return enter(item);
                if (item.entry) { item.entry.execute(); root.open = false; return; }
                if (item.confirm && confirming !== item) { confirming = item; return; }
                root.open = false;
                if (item.run.shortcut) { deferred.spec = item.run; deferred.restart(); }
                else root.run(item.run);
            }

            // Click anywhere outside the panel to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            GradientFrame {
                id: panel

                width: Math.min(720, win.width - 40)
                height: content.implicitHeight + 32
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(win.height * 0.2)

                // Swallow clicks so they don't reach the close area behind
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 10

                    // Breadcrumb: kalango › Settings › Administration (YaST)
                    Text {
                        Layout.fillWidth: true
                        text: win.stack.map(n => n.label).join("  ›  ")
                        color: Theme.solar
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        elide: Text.ElideLeft
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "󰍉"
                            color: Theme.neon
                            font.pixelSize: 22
                        }

                        TextInput {
                            id: input
                            Layout.fillWidth: true
                            focus: true
                            color: Theme.text
                            selectionColor: Theme.pine
                            font.pixelSize: 20
                            clip: true
                            onTextChanged: { list.currentIndex = 0; win.confirming = null; }

                            Text {
                                visible: !input.text
                                text: win.node.id === "root" ? "Search apps, settings, actions…" : "Search " + win.node.label + "…"
                                color: Theme.muted
                                font: input.font
                            }

                            Keys.onEscapePressed: root.open = false
                            Keys.onReturnPressed: win.activate(win.rows[list.currentIndex])
                            Keys.onEnterPressed: win.activate(win.rows[list.currentIndex])
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                            Keys.onBacktabPressed: list.decrementCurrentIndex()
                            Keys.onPressed: (event) => {
                                if (event.modifiers & Qt.ControlModifier) {
                                    // Vim-style Ctrl+J / Ctrl+K
                                    if (event.key === Qt.Key_J) { list.incrementCurrentIndex(); event.accepted = true; }
                                    else if (event.key === Qt.Key_K) { list.decrementCurrentIndex(); event.accepted = true; }
                                } else if (input.text === "") {
                                    // Empty box: Backspace / Left go up a level, Right opens a category
                                    if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) { win.back(); event.accepted = true; }
                                    else if (event.key === Qt.Key_Right) {
                                        const r = win.rows[list.currentIndex];
                                        if (r && r.item.children) win.enter(r.item);
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.pine
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        implicitHeight: Math.min(count, 10) * 46
                        visible: count > 0
                        clip: true
                        model: win.rows
                        highlightMoveDuration: 0
                        boundsBehavior: Flickable.StopAtBounds

                        highlight: Rectangle {
                            color: Theme.pine
                            radius: 6
                            Rectangle {
                                width: 3; height: parent.height - 14
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 2
                                color: Theme.neon
                            }
                        }

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property var item: modelData.item
                            readonly property bool current: ListView.isCurrentItem
                            readonly property bool asking: win.confirming === item
                            width: list.width
                            height: 46

                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                spacing: 12

                                // Nerd Font glyph for categories, theme icon for apps/tools
                                Item {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    Text {
                                        anchors.centerIn: parent
                                        visible: !!row.item.glyph
                                        text: row.item.glyph || ""
                                        color: row.current ? Theme.neon : Theme.blue
                                        font.pixelSize: 20
                                    }
                                    IconImage {
                                        anchors.fill: parent
                                        visible: !row.item.glyph
                                        source: row.item.glyph ? "" : (Quickshell.iconPath(row.item.icon || "", true)
                                                || Quickshell.iconPath("application-x-executable"))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        text: row.item.label
                                        color: row.current ? Theme.text : Qt.darker(Theme.text, 1.15)
                                        font.pixelSize: 15
                                        elide: Text.ElideRight
                                    }
                                    // Where it lives in the OS (the learning part), or a confirm prompt
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: row.asking ? "Press Enter again to " + row.item.label.toLowerCase()
                                            : [row.modelData.path.join(" › "), row.item.hint || ""].filter(s => s).join("  ·  ")
                                        color: row.asking ? Theme.solar : Theme.muted
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                // Key chip for things that also have a shortcut
                                Rectangle {
                                    visible: !!row.item.keys
                                    implicitWidth: keyText.implicitWidth + 12
                                    implicitHeight: 20
                                    radius: 4
                                    color: "transparent"
                                    border.color: Theme.solar
                                    Text {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: row.item.keys || ""
                                        color: Theme.solar
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    visible: !!row.item.children
                                    text: "›"
                                    color: Theme.muted
                                    font.pixelSize: 18
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: list.currentIndex = row.index
                                onClicked: win.activate(row.modelData)
                            }
                        }
                    }

                    Text {
                        visible: list.count === 0
                        text: "Nothing matches"
                        color: Theme.muted
                        font.pixelSize: 14
                        Layout.leftMargin: 4
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "↑↓ move   ⏎ open   ⌫ back   esc close"
                        color: Theme.muted
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
