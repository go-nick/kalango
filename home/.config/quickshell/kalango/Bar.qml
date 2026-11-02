// kalango top bar — three floating islands on every monitor.
//   left:   notifications bell (unread count, opens the notification list), date + time (opens the calendar)
//   center: CPU, RAM, network down/up (click opens System Monitor), battery
//   right:  keyboard layout menu, audio, Wi-Fi, Bluetooth
// Every module opens the matching KDE settings page on click, so mouse users
// always have a way in.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

Scope {
    id: bar

    readonly property int height: 26    // one island
    readonly property int gap: 4        // space above the islands
    readonly property int glow: 8       // room under the islands for their glow
    // Every module uses the same sizes
    readonly property int iconSize: 19
    readonly property int labelSize: 13

    function ic(cp) { return String.fromCodePoint(cp); }
    function kcm(name) { Quickshell.execDetached(["systemsettings", name]); }
    function sysmon() { Quickshell.execDetached(["plasma-systemmonitor"]); }

    // Load (0..1) along the kalango palette: blue idle -> neon busy -> solar heavy
    function load(x) {
        const mix = (a, b, t) => Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
                                         a.b + (b.b - a.b) * t, 1);
        // Blue is lightened a little to stay readable on the black islands
        return x < 0.6 ? mix(Qt.lighter(Theme.blue, 1.4), Theme.neon, x / 0.6)
                       : mix(Theme.neon, Theme.solar, Math.min(1, (x - 0.6) / 0.3));
    }

    // Default sink must be tracked for its volume/mute to be live
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [bar.sink] }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // One clickable glyph (+ optional text) in the bar
    component Module: MouseArea {
        id: mod
        property string icon
        property string label
        property color tint: Theme.text
        property color labelTint: Theme.text
        property bool labelBold: false
        property int padding: 14
        signal scrolled(int delta)

        implicitWidth: row.implicitWidth + padding
        implicitHeight: bar.height
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => mod.scrolled(wheel.angleDelta.y)

        // The bar's one gradient: a short blue -> green underline that grows
        // under the hovered module
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
            width: mod.containsMouse ? row.implicitWidth : 0
            height: 2
            radius: 1
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.blue }
                GradientStop { position: 1; color: Theme.neon }
            }
        }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5
            Text {
                visible: mod.icon !== ""
                text: mod.icon
                color: mod.tint
                Behavior on color { ColorAnimation { duration: 600 } }
                font.pixelSize: bar.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: mod.label !== ""
                text: mod.label
                color: mod.labelTint
                Behavior on color { ColorAnimation { duration: 600 } }
                font.pixelSize: bar.labelSize
                font.bold: mod.labelBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // One row in a bar menu: check mark, label, hint on the right
    component MenuRow: Rectangle {
        id: row
        property bool mark: false
        property string text
        property string hint
        signal clicked()
        implicitHeight: 32
        radius: 8
        color: rowArea.containsMouse ? Theme.void_ : "transparent"
        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 8
            Text {
                text: row.mark ? String.fromCodePoint(0xF012C) : ""    // check
                color: Theme.neon
                font.pixelSize: 14
                Layout.preferredWidth: 16
            }
            Text {
                text: row.text
                color: rowArea.containsMouse ? Theme.neon : Theme.text
                font.pixelSize: 13
                font.bold: row.mark
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: row.hint
                color: Theme.muted
                font.pixelSize: 11
            }
        }
        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    // A floating pill of modules; the wallpaper shows between islands
    component Island: Rectangle {
        default property alias content: modules.data
        implicitWidth: modules.implicitWidth + 8
        implicitHeight: bar.height
        radius: height / 2
        color: Theme.island

        // Soft blue -> green glow below the pill: stacked translucent pills
        Repeater {
            model: [[7, 0.05], [5, 0.08], [3, 0.12], [1, 0.2]]
            Rectangle {
                required property var modelData
                z: -1
                x: -modelData[0]
                y: modelData[0] + 1
                width: parent.width + modelData[0] * 2
                height: parent.height
                radius: height / 2
                opacity: modelData[1]
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.blue }
                    GradientStop { position: 1; color: Theme.neon }
                }
            }
        }
        RowLayout {
            id: modules
            anchors.centerIn: parent
            spacing: 0
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: bar.gap + bar.height + bar.glow
            // Only the bar reserves space and takes clicks; the glow below it doesn't
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: bar.gap + bar.height
            mask: Region { item: zone }
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "kalango-bar"
            // Blur only behind the islands
            BackgroundEffect.blurRegion: Region {
                Region { item: left; radius: left.radius }
                Region { item: center; radius: center.radius }
                Region { item: right; radius: right.radius }
            }

            Item {
                id: zone
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: bar.gap + bar.height
            }

            // The screen corner belongs to the bell: throw the mouse up-left and click
            MouseArea {
                anchors { left: parent.left; top: parent.top }
                height: zone.height
                width: left.x + 4 + bell.width
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.toggleList()
            }

            // ── left ──
            Island {
                id: left
                anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: bar.gap }

                // Bell: unread count, DND state. Any click opens the notification list;
                // Do not disturb and settings live inside it
                Module {
                    id: bell
                    labelBold: true
                    padding: 24
                    icon: Notifications.dnd ? bar.ic(0xF009B)            // bell-off
                        : Notifications.unread > 0 ? bar.ic(0xF009E)     // bell-ring
                        : bar.ic(0xF009A)                                // bell
                    tint: Notifications.dnd ? Theme.solar : Notifications.unread > 0 ? Theme.neon : Theme.text
                    label: Notifications.unread > 0 ? Notifications.unread : ""
                    labelTint: tint
                    onClicked: Notifications.toggleList()
                }

                // Date + time, next to the notifications; click opens the calendar,
                // right-click toggles the full date
                Module {
                    property bool full: false
                    label: Qt.formatDateTime(clock.date, full ? "dddd, d MMMM yyyy  HH:mm" : "ddd d MMM  HH:mm")
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) full = !full;
                        else Calendar.toggle(win.modelData);
                    }
                }
            }

            // ── center: system meters, battery at their right ──
            Island {
                id: center
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: bar.gap }

                // CPU and RAM take their color from their load
                Module {
                    icon: bar.ic(0xF0EE0)
                    label: Math.round(Stats.cpu * 100) + "%"
                    tint: bar.load(Stats.cpu)
                    labelTint: tint
                    onClicked: bar.sysmon()
                }
                Module {
                    icon: bar.ic(0xF035B)
                    label: `${(Stats.ramUsed / 1024 ** 3).toFixed(1)}/${Math.round(Stats.ramTotal / 1024 ** 3)}G`
                    tint: bar.load(Stats.ramTotal ? Stats.ramUsed / Stats.ramTotal : 0)
                    labelTint: tint
                    onClicked: bar.sysmon()
                }
                Module {
                    icon: bar.ic(0xF01DA)    // download
                    label: Stats.rate(Stats.down)
                    onClicked: bar.sysmon()
                }
                Module {
                    icon: bar.ic(0xF0552)    // upload
                    label: Stats.rate(Stats.up)
                    onClicked: bar.sysmon()
                }

                // Battery: hidden on desktops without one
                Module {
                    readonly property var dev: UPower.displayDevice
                    readonly property int pct: Math.round(dev.percentage * 100)
                    readonly property bool charging: dev.state === UPowerDeviceState.Charging
                                                  || dev.state === UPowerDeviceState.FullyCharged
                    visible: dev.isLaptopBattery
                    icon: charging ? bar.ic(0xF0084)
                        : pct >= 95 ? bar.ic(0xF0079) : bar.ic(0xF007A + Math.max(0, Math.floor(pct / 10) - 1))
                    tint: charging ? Theme.neon : pct <= 15 ? Theme.solar : Theme.text
                    label: pct + "%"
                    onClicked: bar.kcm("kcm_powerdevilprofilesconfig")
                }
            }

            // ── right ──
            Island {
                id: right
                anchors { right: parent.right; rightMargin: 10; top: parent.top; topMargin: bar.gap }

                // Keyboard layout: click opens a menu of the configured layouts,
                // scroll cycles them, right-click opens keyboard settings
                Module {
                    id: kbd
                    visible: KeyboardLayouts.active !== null
                    icon: bar.ic(0xF030C)    // keyboard
                    label: KeyboardLayouts.active ? KeyboardLayouts.active.code.toUpperCase() : ""
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) bar.kcm("kcm_keyboard");
                        else menu.visible = !menu.visible;
                    }
                    onScrolled: delta => delta > 0 ? KeyboardLayouts.previous() : KeyboardLayouts.next()

                    PopupWindow {
                        id: menu
                        anchor.item: kbd
                        anchor.edges: Edges.Bottom
                        anchor.gravity: Edges.Bottom
                        anchor.margins.top: 6
                        // Closes on a click anywhere else
                        grabFocus: true
                        implicitWidth: 260
                        implicitHeight: entries.implicitHeight + 16
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius + 4
                            color: "#000000"
                            border.width: 1
                            border.color: Theme.pine

                            ColumnLayout {
                                id: entries
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                spacing: 2

                                Repeater {
                                    model: KeyboardLayouts.layouts
                                    MenuRow {
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        mark: index === KeyboardLayouts.current
                                        text: modelData.name
                                        hint: modelData.code.toUpperCase()
                                        onClicked: { KeyboardLayouts.set(index); menu.visible = false; }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.margins: 4
                                    implicitHeight: 1
                                    color: Theme.pine
                                }
                                MenuRow {
                                    Layout.fillWidth: true
                                    text: "Add or change layouts…"
                                    hint: "Meta+Alt+K"
                                    onClicked: { menu.visible = false; bar.kcm("kcm_keyboard"); }
                                }
                            }
                        }
                    }
                }

                // Audio: scroll = volume, right-click = mute, click = sound settings
                Module {
                    readonly property var audio: bar.sink?.audio ?? null
                    readonly property int pct: audio ? Math.round(audio.volume * 100) : 0
                    visible: audio !== null
                    icon: !audio || audio.muted ? bar.ic(0xF075F)
                        : pct > 66 ? bar.ic(0xF057E) : pct > 33 ? bar.ic(0xF0580) : bar.ic(0xF057F)
                    tint: audio && audio.muted ? Theme.muted : Theme.text
                    label: pct + "%"
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) audio.muted = !audio.muted;
                        else bar.kcm("kcm_pulseaudio");
                    }
                    onScrolled: delta => audio.volume = Math.max(0, Math.min(1, audio.volume + (delta > 0 ? 0.05 : -0.05)))
                }

                // Network: wired, Wi-Fi strength, or disconnected
                Module {
                    readonly property var devices: Networking.devices.values
                    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
                    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
                    readonly property var net: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
                    readonly property real strength: net ? net.signalStrength : 0
                    icon: wired ? bar.ic(0xF0200)
                        : !wifi ? bar.ic(0xF092D)
                        : bar.ic([0xF091F, 0xF0922, 0xF0925, 0xF0928][Math.min(3, Math.floor(strength * 4))])
                    tint: wired || wifi ? Theme.text : Theme.muted
                    onClicked: bar.kcm("kcm_networkmanagement")
                }

                // Bluetooth: right-click toggles the radio
                Module {
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property bool linked: adapter ? adapter.devices.values.some(d => d.connected) : false
                    visible: adapter !== null
                    icon: !adapter || !adapter.enabled ? bar.ic(0xF00B2) : linked ? bar.ic(0xF00B1) : bar.ic(0xF00AF)
                    tint: adapter && adapter.enabled ? (linked ? Theme.blue : Theme.text) : Theme.muted
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) adapter.enabled = !adapter.enabled;
                        else bar.kcm("kcm_bluetooth");
                    }
                }

            }
        }
    }
}
