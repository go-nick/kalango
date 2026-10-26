// kalango shell — long-running Quickshell instance (`qs -c kalango`).
// Components are toggled over IPC, e.g. `qs -c kalango ipc call launcher metaLauncherToggle`.
import QtQuick
import Quickshell

ShellRoot {
    // DesktopEntries only scans on first access; touch it at startup so the
    // first Meta+Space already has the app list.
    Component.onCompleted: DesktopEntries.applications

    Launcher {}
    Bar {}
}
