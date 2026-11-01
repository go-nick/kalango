// Notification popups: stacked at the top-left, under the bar's bell, on the
// active monitor. Low: 4 s, normal: 6 s (or the app's own timeout), critical:
// until handled. Hovering pauses the timer. Hidden while the list is open.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

Scope {
    LazyLoader {
        active: Notifications.popups.length > 0 && !Notifications.listOpen

        PanelWindow {
            anchors { top: true; left: true }
            margins { top: 6; left: 10 }
            // Below the bar: respect its exclusive zone without reserving our own
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            implicitWidth: 400
            implicitHeight: stack.implicitHeight
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kalango-notifications"

            Column {
                id: stack
                width: parent.width
                spacing: 8

                Repeater {
                    model: ScriptModel {
                        values: Notifications.popups.slice(0, 4)
                        objectProp: "key"
                    }

                    NotificationCard {
                        id: popup
                        required property var modelData
                        entry: modelData
                        width: stack.width

                        // Slide in from the left
                        x: -16
                        opacity: 0
                        Component.onCompleted: { x = 0; opacity = 1; }
                        // (opacity already animates in NotificationCard)
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        readonly property int timeout: {
                            if (critical || n.expireTimeout === 0) return 0;    // stays
                            if (n.expireTimeout > 0) return n.expireTimeout;
                            return n.urgency === NotificationUrgency.Low ? 4000 : 6000;
                        }

                        Timer {
                            id: life
                            interval: popup.timeout
                            running: popup.timeout > 0 && !popup.hovered
                            onTriggered: Notifications.hidePopup(popup.entry)
                        }
                        // New text from the app (e.g. download progress) restarts the clock
                        Connections {
                            target: popup.n
                            function onBodyChanged() { life.restart(); }
                            function onSummaryChanged() { life.restart(); }
                        }
                    }
                }
            }
        }
    }
}
