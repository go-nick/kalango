// NickKeys — searchable popup of every KDE global shortcut.
// Launched by `nickkeys --gui`; {rows, favs, favPath} arrive as a JSON argument after "--".
// Favorites are saved back to favPath (XHR file write enabled by the launcher).
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Window {
    id: root
    title: "NickKeys"
    width: 1100
    height: 650
    visible: true
    color: "#0A0F14"

    readonly property color cVoid: "#0A0F14"
    readonly property color cPine: "#0C322C"
    readonly property color cGreen: "#3DFF9A"
    readonly property color cBlue: "#2E6BFF"
    readonly property color cYellow: "#FFD23F"
    readonly property color cText: "#E6F1EC"
    readonly property color cMuted: "#7A8C85"
    readonly property string mono: "JetBrainsMono Nerd Font"

    readonly property var payload: {
        const args = Qt.application.arguments;
        const i = args.indexOf("--");
        return i >= 0 && i + 1 < args.length ? JSON.parse(args[i + 1]) : ({ rows: [], favs: [] });
    }
    readonly property var rows: payload.rows
    property var favs: payload.favs

    function matches(r, q) {
        const hay = (r.keys + " " + r.action + " " + r.group + (favs.includes(r.id) ? " fav" : "")).toLowerCase();
        return q.toLowerCase().split(/\s+/).every(w => hay.indexOf(w) >= 0);
    }
    // Favorites float to the top; otherwise keep the order nickkeys sent
    property var shown: {
        const hits = rows.filter(r => matches(r, search.text));
        const fav = hits.filter(r => favs.includes(r.id));
        const rest = hits.filter(r => !favs.includes(r.id));
        return fav.map((r, i) => Object.assign({}, r, { fav: true, label: i === 0 ? "★  FAVORITES" : "" }))
            .concat(rest.map((r, i) => Object.assign({}, r, { fav: false, label: i === 0 && fav.length ? "ALL SHORTCUTS" : "" })));
    }

    property int pendingSaves: 0
    property bool quitRequested: false
    function quit() {             // don't drop a favorite that is still being written
        quitRequested = true;
        if (pendingSaves === 0) Qt.quit();
    }

    function toggleFav(id) {
        const f = favs.slice();
        const i = f.indexOf(id);
        if (i >= 0) f.splice(i, 1); else f.push(id);
        favs = f;
        const xhr = new XMLHttpRequest();
        pendingSaves++;
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            pendingSaves--;
            if (quitRequested && pendingSaves === 0) Qt.quit();
        };
        xhr.open("PUT", "file://" + payload.favPath);
        xhr.send(JSON.stringify(f, null, 2));
        list.currentIndex = shown.findIndex(r => r.id === id);   // selection follows the row
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰌌  "; color: root.cGreen; font.family: root.mono; font.pixelSize: 22 }
            TextField {
                id: search
                Layout.fillWidth: true
                focus: true
                placeholderText: "search shortcuts…  (e.g. tiling, close, Meta+Shift)"
                placeholderTextColor: root.cMuted
                color: root.cText
                font.family: root.mono
                font.pixelSize: 18
                background: Item {}
                onTextChanged: list.currentIndex = 0
                Keys.onEscapePressed: root.quit()
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier) && list.currentItem) {
                        root.toggleFav(root.shown[list.currentIndex].id);
                        e.accepted = true;
                    }
                }
            }
            Text {
                text: root.shown.length + " / " + root.rows.length
                color: root.cMuted; font.family: root.mono; font.pixelSize: 14
            }
        }

        // Gradient rule: electric blue -> neon green
        Rectangle {
            Layout.fillWidth: true
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.cBlue }
                GradientStop { position: 1; color: root.cGreen }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.shown
            highlightMoveDuration: 0
            ScrollBar.vertical: ScrollBar {}
            highlight: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: list.currentItem && list.currentItem.hasLabel ? 30 : 0
                    color: root.cPine; radius: 4
                }
            }
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool hasLabel: modelData.label !== ""
                width: list.width
                height: hasLabel ? 60 : 30
                Text {
                    visible: row.hasLabel
                    y: 8
                    leftPadding: 10
                    text: modelData.label
                    color: modelData.fav ? root.cYellow : root.cMuted
                    font.family: root.mono; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2
                }
                MouseArea { anchors.fill: parent; onClicked: list.currentIndex = index }
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 16
                    Text {
                        text: modelData.fav ? "★" : "☆"
                        color: modelData.fav ? root.cYellow : root.cMuted
                        opacity: modelData.fav || row.ListView.isCurrentItem || starArea.containsMouse ? 1 : 0.35
                        font.pixelSize: 17
                        MouseArea {
                            id: starArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFav(modelData.id)
                        }
                    }
                    Text {
                        Layout.preferredWidth: 320
                        text: modelData.keys
                        color: root.cGreen
                        font.family: root.mono; font.pixelSize: 15; font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.action
                        color: root.cText
                        font.family: root.mono; font.pixelSize: 15
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.preferredWidth: 200
                        horizontalAlignment: Text.AlignRight
                        text: modelData.group
                        color: modelData.group === "Tiling" ? root.cYellow : root.cMuted
                        font.family: root.mono; font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Text {
            text: "type to filter  ·  ↑↓ move  ·  Ctrl+S / click ☆ favorite  ·  Esc close"
            color: root.cMuted; font.family: root.mono; font.pixelSize: 12
        }
    }

    onActiveChanged: if (!active) root.quit()   // close when you click away, like a launcher
}
