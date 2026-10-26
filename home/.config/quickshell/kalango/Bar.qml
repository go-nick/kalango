// kalango top bar — slim Omarchy-style panel on every monitor.
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

    readonly property int height: 26

    function ic(cp) { return String.fromCodePoint(cp); }
    function kcm(name) { Quickshell.execDetached(["systemsettings", name]); }

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
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: mod.label !== ""
                text: mod.label
                color: Theme.text
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: bar.height
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "kalango-bar"
            BackgroundEffect.blurRegion: Region { item: bg }

            Rectangle {
                id: bg
                anchors.fill: parent
                color: Theme.glass
            }
            // Signature blue -> green hairline along the bottom edge
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.blue }
                    GradientStop { position: 1; color: Theme.neon }
                }
            }

            // ── left ──
            RowLayout {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 0

                Module {
                    icon: bar.ic(0xF009A)    // bell
                    onClicked: bar.kcm("kcm_notifications")
                }
            }

            // ── center: system meters, battery at their right ──
            RowLayout {
                anchors.centerIn: parent
                spacing: 0

                Module {
                    label: `${bar.ic(0xF0EE0)} ${Math.round(Stats.cpu * 100)}%   `
                         + `${bar.ic(0xF035B)} ${(Stats.ramUsed / 1024 ** 3).toFixed(1)}/${Math.round(Stats.ramTotal / 1024 ** 3)}G   `
                         + `${bar.ic(0xF01DA)}${Stats.rate(Stats.down)} ${bar.ic(0xF0552)}${Stats.rate(Stats.up)}`
                    onClicked: Quickshell.execDetached(["plasma-systemmonitor"])
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
            RowLayout {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 0

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
