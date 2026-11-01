// Notification list: a full-height panel that slides out under the bar's bell.
// Unread notifications on top, already-read ones dimmed under "Earlier".
// Every card shows the source app, date and time, title and message.
// Close with the bell, Esc or a click outside.
//   qs -c kalango ipc call notifications notificationsToggleList
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    // The window outlives listOpen while the close animation plays
    property bool alive: false
    Connections {
        target: Notifications
        function onListOpenChanged() { if (Notifications.listOpen) root.alive = true; }
    }

    // IPC names are prefixed so they can never collide with `qs ipc` subcommands
    IpcHandler {
        target: "notifications"

        function notificationsToggleList(): void { Notifications.toggleList(); }
        function notificationsToggleDnd(): void { Notifications.toggleDnd(); }
        function notificationsMarkAllRead(): void { Notifications.markAllRead(); }
        function notificationsClearAll(): void { Notifications.clearAll(); }
        function notificationsToggleSounds(): void { Notifications.toggleSounds(); }
        function notificationsUnread(): int { return Notifications.unread; }
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win

            anchors { top: true; bottom: true; left: true; right: true }
            // Below the bar, like the popups
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kalango-notification-list"
            // Modal while open, so Esc works right away
            WlrLayershell.keyboardFocus: Notifications.listOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property var unread: Notifications.entries.filter(e => !e.read)
            readonly property var earlier: Notifications.entries.filter(e => e.read)

            // 0 = hidden, 1 = shown
            property real reveal: 0
            Component.onCompleted: reveal = 1
            Connections {
                target: Notifications
                function onListOpenChanged() { win.reveal = Notifications.listOpen ? 1 : 0; }
            }
            Behavior on reveal {
                NumberAnimation {
                    duration: Notifications.listOpen ? 180 : 130
                    easing.type: Notifications.listOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
            onRevealChanged: if (reveal === 0 && !Notifications.listOpen) root.alive = false

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: Notifications.listOpen = false
            }

            Rectangle {
                id: panel

                width: 440
                anchors { top: parent.top; bottom: parent.bottom; topMargin: 6; bottomMargin: 10 }
                // Slide in from the left edge
                x: 10 - (width + 10) * (1 - win.reveal)
                opacity: win.reveal
                radius: Theme.radius + 4
                color: "#000000"

                focus: true
                Keys.onEscapePressed: Notifications.listOpen = false

                // Swallow clicks so they don't reach the close area behind
                MouseArea { anchors.fill: parent }

                // Same border as the focused window
                SpinningBorder {
                    anchors.fill: parent
                    radius: panel.radius
                    running: Notifications.listOpen
                }

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 12

                    // Title, unread count, Do not disturb
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "Notifications"
                            color: Theme.text
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Rectangle {
                            visible: Notifications.unread > 0
                            implicitWidth: count.implicitWidth + 14
                            implicitHeight: 20
                            radius: 10
                            color: Theme.neon
                            Text {
                                id: count
                                anchors.centerIn: parent
                                text: Notifications.unread + " unread"
                                color: Theme.void_
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                        Item { Layout.fillWidth: true }
                        HeaderButton {
                            icon: Notifications.dnd ? 0xF009B : 0xF009A    // bell-off / bell
                            label: "Do not disturb"
                            active: Notifications.dnd
                            onClicked: Notifications.toggleDnd()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        HeaderButton {
                            icon: 0xF012C    // check-all
                            label: "Mark all read"
                            enabled: Notifications.unread > 0
                            onClicked: Notifications.markAllRead()
                        }
                        HeaderButton {
                            icon: 0xF0A79    // trash
                            label: "Clear all"
                            enabled: Notifications.entries.length > 0
                            onClicked: Notifications.clearAll()
                        }
                        HeaderButton {
                            icon: Notifications.sounds ? 0xF057E : 0xF075F    // volume / mute
                            label: Notifications.sounds ? "Sound on" : "Sound off"
                            onClicked: Notifications.toggleSounds()
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Flickable {
                        visible: Notifications.entries.length > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: sections.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: sections
                            width: parent.width
                            spacing: 8

                            SectionLabel {
                                visible: win.unread.length > 0
                                text: "Unread · " + win.unread.length
                            }
                            Repeater {
                                model: ScriptModel { values: win.unread; objectProp: "key" }
                                NotificationCard {
                                    required property var modelData
                                    entry: modelData
                                    Layout.fillWidth: true
                                    inList: true
                                }
                            }

                            SectionLabel {
                                visible: win.earlier.length > 0
                                text: "Earlier"
                                Layout.topMargin: win.unread.length > 0 ? 8 : 0
                            }
                            Repeater {
                                model: ScriptModel { values: win.earlier; objectProp: "key" }
                                NotificationCard {
                                    required property var modelData
                                    entry: modelData
                                    Layout.fillWidth: true
                                    inList: true
                                }
                            }
                        }
                    }

                    // Empty state
                    ColumnLayout {
                        visible: Notifications.entries.length === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        Item { Layout.fillHeight: true }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: String.fromCodePoint(0xF009A)
                            color: Theme.pine
                            font.pixelSize: 48
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No notifications. You're all caught up"
                            color: Theme.muted
                            font.pixelSize: 13
                        }
                        Item { Layout.fillHeight: true }
                    }

                    // Where per-app notification settings live
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Notification settings  ›  System Settings › Notifications"
                        color: settingsArea.containsMouse ? Theme.neon : Theme.muted
                        font.pixelSize: 11
                        MouseArea {
                            id: settingsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Notifications.listOpen = false;
                                Quickshell.execDetached(["systemsettings", "kcm_notifications"]);
                            }
                        }
                    }
                }
            }
        }
    }

    component SectionLabel: Text {
        color: Theme.muted
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1
        font.capitalization: Font.AllUppercase
    }

    // Icon + label pill: Pine, neon on hover, solar when active (DND on)
    component HeaderButton: Rectangle {
        id: btn
        property int icon
        property string label
        property bool active: false
        signal clicked()
        implicitHeight: 28
        implicitWidth: row.implicitWidth + 20
        radius: 8
        opacity: enabled ? 1 : 0.4
        color: active ? Theme.solar : btnArea.containsMouse && enabled ? Theme.neon : Theme.pine
        readonly property color fg: active || (btnArea.containsMouse && enabled) ? Theme.void_ : Theme.text
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: String.fromCodePoint(btn.icon)
                color: btn.fg
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: btn.label
                color: btn.fg
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (btn.enabled) btn.clicked()
        }
    }
}
