// kalango top bar — three floating islands on every monitor.
//   left:   notifications (placeholder until kalango's own notifications land)
//   center: CPU, RAM, network down/up (click opens System Monitor), battery
//   right:  audio, Wi-Fi, Bluetooth, date + time
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

    function ic(cp) { return String.fromCodePoint(cp); }
    function kcm(name) { Quickshell.execDetached(["systemsettings", name]); }
    function sysmon() { Quickshell.execDetached(["plasma-systemmonitor"]); }

    // Load (0..1) along the kalango palette: blue idle -> neon busy -> solar heavy
    function load(x) {
        const mix = (a, b, t) => Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
                                         a.b + (b.b - a.b) * t, 1);
        // Blue is lightened a little to stay readable on the Pine islands
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
        signal scrolled(int delta)

        implicitWidth: row.implicitWidth + 12
        implicitHeight: bar.height
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => mod.scrolled(wheel.angleDelta.y)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 4
            color: mod.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
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
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: mod.label !== ""
                text: mod.label
                color: mod.labelTint
                Behavior on color { ColorAnimation { duration: 600 } }
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // A floating pill of modules; the wallpaper shows between islands
    component Island: Rectangle {
        default property alias content: modules.data
        implicitWidth: modules.implicitWidth + 8
        implicitHeight: bar.height
        radius: height / 2
        color: Theme.island
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
            implicitHeight: bar.gap + bar.height
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "kalango-bar"
            // Blur only behind the islands
            BackgroundEffect.blurRegion: Region {
                Region { item: left; radius: left.radius }
                Region { item: center; radius: center.radius }
                Region { item: right; radius: right.radius }
            }

            // ── left ──
            Island {
                id: left
                anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom }

                Module {
                    icon: bar.ic(0xF009A)    // bell
                    onClicked: bar.kcm("kcm_notifications")
                }
            }

            // ── center: system meters, battery at their right ──
            Island {
                id: center
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }

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
                    label: `${bar.ic(0xF01DA)}${Stats.rate(Stats.down)} ${bar.ic(0xF0552)}${Stats.rate(Stats.up)}`
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
                anchors { right: parent.right; rightMargin: 10; bottom: parent.bottom }

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

                // Date + time; click toggles the full date
                Module {
                    property bool full: false
                    label: Qt.formatDateTime(clock.date, full ? "dddd, d MMMM yyyy  HH:mm" : "ddd d MMM  HH:mm")
                    onClicked: full = !full
                }
            }
        }
    }
}
