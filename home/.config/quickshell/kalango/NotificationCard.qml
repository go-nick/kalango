// One notification, as a popup or as a row in the notification list:
// source app + date/time, title, message, progress, buttons, inline reply.
// Click runs the app's default action (if any) and marks it read.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

ClippingRectangle {
    id: card

    required property var entry
    property bool inList: false
    // Re-read the entry whenever the service refreshes (entries are plain JS objects)
    readonly property bool read: (Notifications.entries, entry.read)
    readonly property date time: (Notifications.entries, entry.time)
    readonly property var n: entry.n
    readonly property bool critical: n.urgency === NotificationUrgency.Critical
    readonly property bool hovered: hover.hovered
    readonly property var app: n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null
    readonly property var progress: n.hints.value

    function iconSource(name) {
        if (!name) return "";
        if (name.startsWith("/")) return "file://" + name;
        if (name.includes("://")) return name;
        return Quickshell.iconPath(name, true);
    }
    readonly property string appIcon: iconSource(n.appIcon) || iconSource(app ? app.icon : "")
                                      || Quickshell.iconPath("dialog-information")

    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius + 4
    color: hovered ? Theme.void_ : "#000000"
    border.width: 1
    border.color: critical ? Qt.rgba(1, 0.82, 0.25, 0.5) : Theme.pine
    opacity: inList && read ? 0.55 : 1
    Behavior on opacity { NumberAnimation { duration: 150 } }

    HoverHandler { id: hover }

    // Click anywhere that isn't a button
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.activate(card.entry)
    }

    // The signature as a thin edge: gradient, solar for critical, dim for low
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 3
        opacity: card.n.urgency === NotificationUrgency.Low ? 0.45 : 1
        gradient: Gradient {
            GradientStop { position: 0; color: card.critical ? Theme.solar : Theme.blue }
            GradientStop { position: 1; color: card.critical ? Theme.solar : Theme.neon }
        }
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top
                  leftMargin: 16; rightMargin: 12; topMargin: 12 }
        spacing: 8

        // Source app · date and time, unread dot, close
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconImage {
                implicitSize: 16
                source: card.appIcon
            }
            Text {
                text: (card.app ? card.app.name : "") || card.n.appName || "Unknown app"
                color: Theme.text
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: 160
            }
            Text {
                text: "· " + Notifications.when(card.time)
                color: Theme.muted
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Rectangle {
                visible: card.inList && !card.read
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Theme.neon
            }
            // Close: dismisses it from the list for good
            Text {
                text: String.fromCodePoint(0xF0156)    // close
                color: closeArea.containsMouse ? Theme.neon : Theme.muted
                font.pixelSize: 15
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.dismiss(card.entry)
                }
            }
        }

        // Image (or app icon) + title and message
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // A photo (screenshot, avatar, album art) when the app sends one, else its icon
            ClippingRectangle {
                id: picture
                readonly property bool photo: card.n.image !== ""
                implicitWidth: photo ? 56 : 40
                implicitHeight: photo ? 56 : 40
                Layout.alignment: Qt.AlignTop
                radius: photo ? 8 : 0
                color: "transparent"
                Image {
                    anchors.fill: parent
                    visible: picture.photo
                    source: picture.photo ? card.n.image : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(112, 112)
                    asynchronous: true
                }
                IconImage {
                    anchors.fill: parent
                    visible: !picture.photo
                    source: picture.photo ? "" : card.appIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: card.n.summary
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    // Apps often send a raw "<" ("a <= b"); only real markup tags stay tags
                    text: card.n.body.replace(/<(?!\/?(b|i|u|a|img|br)\b)/gi, "&lt;")
                    textFormat: Text.StyledText
                    color: Qt.rgba(0.9, 0.945, 0.925, 0.8)
                    linkColor: Theme.neon
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    maximumLineCount: card.inList ? 8 : 4
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        // Progress: the signature gradient on a Pine track
        Rectangle {
            visible: card.progress !== undefined
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.pine
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, card.progress || 0)) / 100
                height: parent.height
                radius: 3
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.blue }
                    GradientStop { position: 1; color: Theme.neon }
                }
            }
        }

        // Inline reply (chat apps)
        RowLayout {
            visible: card.n.hasInlineReply
            Layout.fillWidth: true
            spacing: 6
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 8
                color: Theme.void_
                border.width: 1
                border.color: reply.activeFocus ? Theme.neon : Theme.pine
                TextInput {
                    id: reply
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.pixelSize: 13
                    clip: true
                    onAccepted: send.clicked()
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !reply.text
                        text: card.n.inlineReplyPlaceholder || "Reply…"
                        color: Theme.muted
                        font.pixelSize: 13
                    }
                }
            }
            Pill {
                id: send
                text: "Send"
                onClicked: if (reply.text) card.n.sendInlineReply(reply.text)
            }
        }

        // The app's buttons (the default action is the click on the card)
        RowLayout {
            readonly property var buttons: card.n.actions.filter(a => a.identifier !== "default")
            visible: buttons.length > 0
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: parent.buttons
                Pill {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    // Pine button that turns neon on hover
    component Pill: Rectangle {
        id: pill
        property string text
        signal clicked()
        implicitHeight: 30
        implicitWidth: label.implicitWidth + 24
        radius: 8
        color: pillArea.containsMouse ? Theme.neon : Theme.pine
        Text {
            id: label
            anchors.centerIn: parent
            text: pill.text
            color: pillArea.containsMouse ? Theme.void_ : Theme.text
            font.pixelSize: 12
            font.bold: true
        }
        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }
}
