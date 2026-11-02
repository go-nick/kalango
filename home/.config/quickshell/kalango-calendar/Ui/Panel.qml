// The base Flight Deck Calendar's panel builds on: settings and an open/closed state.
import QtQuick

Item {
    property var bar: null
    property string moduleName: ""
    property var settings: ({})
    property string ipcTarget: ""
    property bool manageIpc: false
    readonly property bool opened: controller.open
    readonly property alias controller: controller

    QtObject {
        id: controller
        property bool open: false
        function show() { open = true; }
        function hide() { open = false; }
    }
}
