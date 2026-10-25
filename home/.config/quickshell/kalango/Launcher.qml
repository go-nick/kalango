// kalango launcher — search mode (Meta+Space).
// Opens on the active monitor (the compositor picks the screen), searches installed apps.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property bool open: false

    // IPC names are prefixed (metaLauncher*) so they can never collide with
    // `qs ipc` subcommands (show, call, wait, listen, prop):
    //   qs -c kalango ipc call launcher metaLauncherToggle
    IpcHandler {
        target: "launcher"

        function metaLauncherToggle(): void { root.open = !root.open; }
        function metaLauncherOpen(): void { root.open = true; }
        function metaLauncherClose(): void { root.open = false; }
        function metaLauncherIsOpen(): bool { return root.open; }
    }

    // Rank an app against the query: higher is better, -1 means no match.
    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name.startsWith(q)) return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        const extra = [entry.genericName, entry.keywords.join(" "), entry.categories.join(" ")]
            .join(" ").toLowerCase();
        if (extra.includes(q)) return 40;
        if ((entry.comment || "").toLowerCase().includes(q)) return 20;
        // Loose subsequence: "frx" matches "Firefox"
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 10 : -1;
    }

    function search(text) {
        const q = text.trim().toLowerCase();
        // YaST2-groups-* are YaST control-center group headers, not launchable apps
        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !e.id.startsWith("YaST2-groups-"));
        if (q === "")
            return apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        return apps
            .map(e => ({ e: e, s: score(e, q) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .map(r => r.e);
    }

    // Recreated on every open so the compositor places it on the current monitor
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

            property var results: root.search(input.text)

            function launch(entry) {
                if (!entry) return;
                entry.execute();
                root.open = false;
            }

            // Click anywhere outside the panel to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            GradientFrame {
                id: panel

                width: Math.min(680, win.width - 40)
                height: content.implicitHeight + 32
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(win.height * 0.22)

                // Swallow clicks so they don't reach the close area behind
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 10

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
                            onTextChanged: list.currentIndex = 0

                            Text {
                                visible: !input.text
                                text: "Search apps…"
                                color: Theme.muted
                                font: input.font
                            }

                            Keys.onEscapePressed: root.open = false
                            Keys.onReturnPressed: win.launch(win.results[list.currentIndex])
                            Keys.onEnterPressed: win.launch(win.results[list.currentIndex])
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                            Keys.onBacktabPressed: list.decrementCurrentIndex()
                            Keys.onPressed: (event) => {
                                // Vim-style Ctrl+J / Ctrl+K
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.key === Qt.Key_J) { list.incrementCurrentIndex(); event.accepted = true; }
                                    else if (event.key === Qt.Key_K) { list.decrementCurrentIndex(); event.accepted = true; }
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
                        implicitHeight: Math.min(count, 8) * 44
                        visible: count > 0
                        clip: true
                        model: win.results
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
                            width: list.width
                            height: 44

                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                spacing: 12

                                IconImage {
                                    implicitSize: 26
                                    source: Quickshell.iconPath(row.modelData.icon, true)
                                            || Quickshell.iconPath("application-x-executable")
                                }

                                Text {
                                    text: row.modelData.name
                                    color: row.ListView.isCurrentItem ? Theme.text : Qt.darker(Theme.text, 1.15)
                                    font.pixelSize: 16
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.genericName || row.modelData.comment || ""
                                    color: Theme.muted
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: list.currentIndex = row.index
                                onClicked: win.launch(row.modelData)
                            }
                        }
                    }

                    Text {
                        visible: list.count === 0
                        text: "No matching apps"
                        color: Theme.muted
                        font.pixelSize: 14
                        Layout.leftMargin: 4
                    }
                }
            }
        }
    }
}
