// The box Flight Deck Calendar draws into: here, the whole app window.
import QtQuick

Item {
    property Item anchorItem: null
    property var owner: null
    property var bar: null
    property bool open: false
    property bool centerOnBar: false
    property Item focusTarget: null
    property int contentWidth: 0
    property int contentHeight: 0

    anchors.fill: parent

    function fittedContentWidth(value) { return width; }
    function fittedContentHeight(value) { return height; }

    onOpenChanged: if (open && focusTarget) focusTarget.forceActiveFocus()
}
