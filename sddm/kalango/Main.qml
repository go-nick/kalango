// kalango login screen: crossfading calango wallpapers, clock, a login card with the
// focused-window border, and a power island. Plain QtQuick and SDDM's own API, so
// Plasma updates can't break logging in.
// Test without logging out: sddm-greeter-qt6 --test-mode --theme <this folder>
import QtQuick
import QtQml
import Qt.labs.folderlistmodel

Rectangle {
    id: root

    readonly property string font_: "JetBrainsMono Nerd Font"
    readonly property color neon: "#3DFF9A"
    readonly property color pine: "#0C322C"
    readonly property color solar: "#FFD23F"
    readonly property color text_: "#E6F1EC"
    readonly property color muted: "#7A8C85"

    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    readonly property var user: users.count > userIndex ? users.objectAt(userIndex) : null
    readonly property var session: sessions.count > sessionIndex ? sessions.objectAt(sessionIndex) : null
    property string message: ""
    property bool busy: false

    color: "#000000"

    function login() {
        if (!user || busy) return;
        busy = true;
        message = "";
        sddm.login(user.name, password.text, sessionIndex);
    }

    Instantiator {
        id: users
        model: userModel
        QtObject {
            required property string name
            required property string realName
            required property string icon
        }
    }
    Instantiator {
        id: sessions
        model: sessionModel
        QtObject { required property string name }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.message = "Wrong password";
            password.text = "";
            password.forceActiveFocus();
            shake.restart();
        }
        function onInformationMessage(message) { root.message = message; }
    }

    // ── wallpapers, crossfading every 10 minutes ──
    FolderListModel {
        id: wallpapers
        folder: Qt.resolvedUrl("backgrounds")
        nameFilters: ["*.png"]
        showDirs: false
    }
    property int wallpaper: 0
    Timer {
        interval: 600000
        running: wallpapers.count > 1
        repeat: true
        onTriggered: root.wallpaper = (root.wallpaper + 1) % wallpapers.count
    }
    Repeater {
        model: wallpapers
        Image {
            required property int index
            required property url fileUrl
            anchors.fill: parent
            source: fileUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: index === root.wallpaper ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 1500 } }
        }
    }

    // ── clock ──
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }
    Column {
        id: clock
        property date now: new Date()
        anchors { horizontalCenter: parent.horizontalCenter; bottom: card.top; bottomMargin: 36 }
        spacing: 4
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.now, "HH:mm")
            color: root.text_
            font { family: root.font_; pixelSize: 72 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.now, "dddd, d MMMM yyyy")
            color: root.text_
            font { family: root.font_; pixelSize: 16 }
        }
    }

    // ── login card ──
    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 400
        height: fields.implicitHeight + 48
        radius: 14
        color: "#000000"

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: cardShift; property: "x"; to: -8; duration: 50 }
            NumberAnimation { target: cardShift; property: "x"; to: 8; duration: 50 }
            NumberAnimation { target: cardShift; property: "x"; to: 0; duration: 50 }
        }
        transform: Translate { id: cardShift }

        SpinningBorder {
            anchors.fill: parent
            radius: card.radius
        }

        Column {
            id: fields
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 14

            // User, with arrows when there's more than one
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                Glyph {
                    visible: users.count > 1
                    code: 0xF0141    // chevron-left
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.userIndex = (root.userIndex + users.count - 1) % users.count
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.user ? (root.user.realName || root.user.name) : ""
                    color: root.text_
                    font { family: root.font_; pixelSize: 20; bold: true }
                }
                Glyph {
                    visible: users.count > 1
                    code: 0xF0142    // chevron-right
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.userIndex = (root.userIndex + 1) % users.count
                }
            }

            // Password; Enter logs in
            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: "#0A0F14"
                border.width: 1
                border.color: password.activeFocus ? root.neon : root.pine

                TextInput {
                    id: password
                    anchors { fill: parent; leftMargin: 14; rightMargin: 44 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.text_
                    selectionColor: root.neon
                    selectedTextColor: "#0A0F14"
                    font { family: root.font_; pixelSize: 15 }
                    clip: true
                    focus: true
                    enabled: !root.busy
                    Component.onCompleted: forceActiveFocus()
                    onAccepted: root.login()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !password.text
                        text: "Password"
                        color: root.muted
                        font: password.font
                    }
                }
                Glyph {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    code: 0xF0054    // arrow-right
                    tint: root.neon
                    onClicked: root.login()
                }
            }

            // Problems: wrong password, Caps Lock
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                text: root.message || (keyboard.capsLock ? "Caps Lock is on" : "")
                color: root.solar
                font { family: root.font_; pixelSize: 13 }
            }
        }
    }

    // ── session, keyboard and power ──
    Rectangle {
        anchors { right: parent.right; bottom: parent.bottom; margins: 16 }
        width: island.implicitWidth + 24
        height: 40
        radius: height / 2
        color: "#000000"

        Row {
            id: island
            anchors.centerIn: parent
            spacing: 16

            Label {
                visible: sessions.count > 1
                text: root.session ? root.session.name : ""
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessions.count
            }
            Label {
                visible: keyboard.layouts.length > 1
                text: keyboard.layouts.length > keyboard.currentLayout
                      ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
            Glyph {
                visible: sddm.canSuspend
                code: 0xF04B2    // sleep
                onClicked: sddm.suspend()
            }
            Glyph {
                visible: sddm.canReboot
                code: 0xF0709    // restart
                onClicked: sddm.reboot()
            }
            Glyph {
                visible: sddm.canPowerOff
                code: 0xF0425    // power
                onClicked: sddm.powerOff()
            }
        }
    }

    // Clickable icon
    component Glyph: Text {
        id: glyph
        property int code
        property color tint: root.text_
        signal clicked()
        text: String.fromCodePoint(code)
        color: glyphArea.containsMouse ? root.neon : tint
        font { family: root.font_; pixelSize: 20 }
        MouseArea {
            id: glyphArea
            anchors { fill: parent; margins: -6 }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: glyph.clicked()
        }
    }

    // Clickable text that cycles a setting
    component Label: Text {
        id: label
        signal clicked()
        anchors.verticalCenter: parent.verticalCenter
        color: labelArea.containsMouse ? root.neon : root.text_
        font { family: root.font_; pixelSize: 13 }
        MouseArea {
            id: labelArea
            anchors { fill: parent; margins: -6 }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: label.clicked()
        }
    }
}
