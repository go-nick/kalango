// kalango shell — long-running Quickshell instance (`qs -c kalango`).
// Components are toggled over IPC, e.g. `qs -c kalango ipc call launcher metaLauncherToggle`.
import QtQuick
import Quickshell

ShellRoot {
    // DesktopEntries only scans on first access; touch it at startup so the
    // first Meta+Space already has the app list.
    // Notifications is touched too, so the notification server starts at login.
    Component.onCompleted: { DesktopEntries.applications; Notifications.unread; }

    Launcher {}
    Bar {}
    NotificationPopups {}
    NotificationList {}
}
