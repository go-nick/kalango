// kalango shell — long-running Quickshell instance (`qs -c kalango`).
// Components are toggled over IPC, e.g. `qs -c kalango ipc call launcher metaLauncherToggle`.
import Quickshell

ShellRoot {
    Launcher {}
}
