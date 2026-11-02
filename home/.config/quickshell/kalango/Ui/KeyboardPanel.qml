// The box Flight Deck Calendar draws into. It picks its size; the screen limits it.
import QtQuick
import qs

Item {
    property Item anchorItem: null
    property var owner: null
    property var bar: null
    property bool open: false
    property bool centerOnBar: false
    property Item focusTarget: null
    property int contentWidth: 1080
    property int contentHeight: 720

    width: contentWidth
    height: contentHeight
    visible: open

    function fittedContentWidth(value) { return Math.min(value, Calendar.maxWidth); }
    function fittedContentHeight(value) { return Math.min(value, Calendar.maxHeight); }

    onOpenChanged: if (open && focusTarget) focusTarget.forceActiveFocus()
}
