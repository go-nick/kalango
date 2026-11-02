// Calendar state shared by the bar's clock and the calendar window.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool open: false
    property var screen: null
    // Room on the current screen, set by the window
    property int maxWidth: 1400
    property int maxHeight: 720

    // Clicking the clock on another monitor moves the calendar there
    function toggle(onScreen) {
        if (open && onScreen && onScreen !== screen) {
            screen = onScreen;
            return;
        }
        if (onScreen) screen = onScreen;
        open = !open;
    }
}
