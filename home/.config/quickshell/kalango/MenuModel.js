// kalango menu — Omarchy-style task categories filled with openSUSE / KDE tools.
// Every leaf carries a `hint` saying where the thing lives in the OS, so the menu
// also teaches where System Settings, YaST, Spectacle & co. are.
//
// Leaf `run` specs (executed by Launcher.qml):
//   { kcm: "kcm_x" }          System Settings page
//   { desktop: "id" }         desktop entry (apps, YaST modules)
//   { cmd: ["prog", ...] }    detached process ("~/" expands to $HOME)
//   { sh: "..." }             bash -c
//   { terminal: "..." }       Konsole running a command, kept open at the end
//   { url: "https://..." }    default browser
//   { shortcut: [component, action] }  invoke an existing KDE global shortcut
//   { menu: true }                     switch the launcher to the menu (stays open)
.pragma library

const g = (cp) => String.fromCodePoint(cp);

// Freedesktop main categories, labelled the way Tumbleweed's Plasma menu does
const APP_CATEGORIES = [
    ["Development", "Development", 0xF0169],
    ["Education", "Education", 0xF0474],
    ["Game", "Games", 0xF0297],
    ["Graphics", "Graphics", 0xF02E9],
    ["Network", "Internet", 0xF059F],
    ["AudioVideo", "Multimedia", 0xF075A],
    ["Office", "Office", 0xF0219],
    ["Science", "Science & Math", 0xF0093],
    ["System", "System", 0xF048B],
    ["Utility", "Utilities", 0xF1064],
];

// YaST control-center groups, from the X-SuSE-YaST-<Group> category on each module
const YAST_GROUPS = [
    ["Software", "Software", 0xF03D6],
    ["Hardware", "Hardware", 0xF061A],
    ["System", "System", 0xF048B],
    ["Net_advanced", "Network Services", 0xF0318],
    ["Security", "Security & Users", 0xF0483],
    ["Virtualization", "Virtualization", 0xF01C4],
    ["Support", "Support", 0xF02D7],
    ["Misc", "Miscellaneous", 0xF01D9],
];

const isYast = (e) => e.categories.includes("X-SuSE-YaST");
const settingsPage = (label, kcm, icon, page) =>
    ({ label: label, icon: icon, hint: "System Settings › " + (page || label), run: { kcm: kcm } });

function appRows(apps) {
    return apps.map(e => ({ label: e.name, icon: e.icon, hint: e.genericName || e.comment || "", entry: e }));
}

function build(allApps) {
    const apps = allApps.filter(e => !isYast(e)).sort((a, b) => a.name.localeCompare(b.name));
    const yast = allApps.filter(isYast);

    const appCategories = APP_CATEGORIES
        .map(([cat, label, glyph]) => ({
            id: "apps." + cat.toLowerCase(), label: label, glyph: g(glyph),
            hint: "Apps › " + label,
            children: appRows(apps.filter(e => e.categories.includes(cat))),
        }))
        .filter(c => c.children.length > 0);

    const yastGroups = YAST_GROUPS
        .map(([cat, label, glyph]) => ({
            id: "settings.yast." + cat.toLowerCase(), label: label, glyph: g(glyph),
            hint: "YaST › " + label,
            children: yast
                .filter(e => e.categories.includes("X-SuSE-YaST-" + cat))
                .sort((a, b) => a.name.localeCompare(b.name))
                .map(e => ({ label: e.name.replace(/^YaST /, ""), icon: e.icon, hint: "YaST › " + label, run: { desktop: e.id } })),
        }))
        .filter(c => c.children.length > 0);

    return {
        id: "root", label: "kalango", children: [
            {
                id: "apps", label: "Apps", glyph: g(0xF003B), hint: "Everything installed, by category",
                children: [{ id: "apps.all", label: "All Apps", glyph: g(0xF0372), hint: "Apps › All", children: appRows(apps) }]
                    .concat(appCategories),
            },
            {
                id: "learn", label: "Learn", glyph: g(0xF0474), hint: "Shortcuts and docs",
                children: [
                    { label: "Keyboard Shortcuts", glyph: g(0xF030C), keys: "Meta + /", hint: "NickKeys: every shortcut, searchable", run: { cmd: ["~/.local/bin/nickkeys", "--gui"] } },
                    { label: "kalango Cheat Sheet", glyph: g(0xF0219), hint: "github.com/go-nick/kalango › docs/shortcuts.md", run: { url: "https://github.com/go-nick/kalango/blob/main/docs/shortcuts.md" } },
                    { label: "openSUSE Docs", glyph: g(0xF0314), hint: "doc.opensuse.org", run: { url: "https://doc.opensuse.org/" } },
                    { label: "Tumbleweed Portal", glyph: g(0xF0314), hint: "en.opensuse.org › Portal:Tumbleweed", run: { url: "https://en.opensuse.org/Portal:Tumbleweed" } },
                    { label: "KDE Help Center", icon: "help-browser", hint: "KHelpCenter: manuals for KDE apps", run: { cmd: ["khelpcenter"] } },
                ],
            },
            {
                id: "appearance", label: "Appearance", glyph: g(0xF03D8), hint: "Colors, fonts, windows",
                children: [
                    settingsPage("Colors", "kcm_colors", "preferences-desktop-color", "Colors & Themes › Colors"),
                    settingsPage("Fonts", "kcm_fonts", "preferences-desktop-font", "Text & Fonts"),
                    settingsPage("Wallpaper", "kcm_wallpaper", "preferences-desktop-wallpaper"),
                    settingsPage("Window Effects & Borders", "kcm_kwin_effects", "preferences-desktop-effects", "Desktop Effects › Rounded Corners"),
                    settingsPage("Tiling & Gaps", "kcm_kwin_scripts", "preferences-system-windows-effect", "KWin Scripts › Krohnkite"),
                    { label: "Spinning Border On", glyph: g(0xF0453), hint: "kwinrc › Round-Corners › OutlineSpinSeconds = 8",
                      run: { sh: "kwriteconfig6 --file kwinrc --group Round-Corners --key OutlineSpinSeconds 8 && qdbus6 org.kde.KWin /KWin reconfigure" } },
                    { label: "Spinning Border Off", glyph: g(0xF04DB), hint: "kwinrc › Round-Corners › OutlineSpinSeconds = 0",
                      run: { sh: "kwriteconfig6 --file kwinrc --group Round-Corners --key OutlineSpinSeconds 0 && qdbus6 org.kde.KWin /KWin reconfigure" } },
                ],
            },
            {
                id: "trigger", label: "Trigger", glyph: g(0xF140B), hint: "Capture, clipboard, toggles",
                children: [
                    { id: "trigger.capture", label: "Capture", glyph: g(0xF0100), hint: "Spectacle", children: [
                        { label: "Screenshot Region", icon: "spectacle", hint: "Spectacle › Rectangular region", run: { cmd: ["spectacle", "-r"] } },
                        { label: "Screenshot Monitor", icon: "spectacle", hint: "Spectacle › Current monitor", run: { cmd: ["spectacle", "-m"] } },
                        { label: "Screenshot Window", icon: "spectacle", hint: "Spectacle › Active window", run: { cmd: ["spectacle", "-a"] } },
                        { label: "Record Region", icon: "media-record", hint: "Spectacle › Record region", run: { cmd: ["spectacle", "-R", "region"] } },
                        { label: "Record Screen", icon: "media-record", hint: "Spectacle › Record screen", run: { cmd: ["spectacle", "-R", "screen"] } },
                    ] },
                    { label: "Clipboard History", icon: "klipper", hint: "Klipper (clipboard in the system tray)", run: { cmd: ["qdbus6", "org.kde.klipper", "/klipper", "org.kde.klipper.klipper.showKlipperPopupMenu"] } },
                    { label: "Emoji", icon: "preferences-desktop-emoticons", hint: "Emoji Selector (plasma-emojier)", run: { cmd: ["plasma-emojier"] } },
                    { label: "Night Light", icon: "redshift-status-on", hint: "Toggle · settings in System Settings › Night Light", run: { shortcut: ["kwin", "Toggle Night Color"] } },
                    { label: "Do Not Disturb", icon: "notifications-disabled", hint: "Toggle · settings in System Settings › Notifications", run: { shortcut: ["plasmashell", "toggle do not disturb"] } },
                ],
            },
            {
                id: "settings", label: "Settings", glyph: g(0xF0493), hint: "System Settings and YaST",
                children: [
                    { label: "All System Settings", icon: "systemsettings", hint: "System Settings (KDE): your desktop and hardware", run: { cmd: ["systemsettings"] } },
                    settingsPage("Display & Monitors", "kcm_kscreen", "preferences-desktop-display", "Display & Monitor"),
                    settingsPage("Sound", "kcm_pulseaudio", "audio-volume-high"),
                    settingsPage("Network", "kcm_networkmanagement", "network-wired", "Wi-Fi & Internet"),
                    settingsPage("Bluetooth", "kcm_bluetooth", "preferences-system-bluetooth"),
                    settingsPage("Keyboard", "kcm_keyboard", "input-keyboard"),
                    settingsPage("Shortcuts", "kcm_keys", "preferences-desktop-keyboard-shortcuts", "Keyboard › Shortcuts"),
                    settingsPage("Mouse", "kcm_mouse", "input-mouse"),
                    settingsPage("Touchpad", "kcm_touchpad", "input-touchpad"),
                    settingsPage("Power", "kcm_powerdevilprofilesconfig", "preferences-system-power-management", "Power Management"),
                    settingsPage("Printers", "kcm_printer_manager", "printer"),
                    settingsPage("Users", "kcm_users", "system-users"),
                    settingsPage("Region & Language", "kcm_regionandlang", "preferences-desktop-locale"),
                    settingsPage("Notifications", "kcm_notifications", "preferences-desktop-notification"),
                    settingsPage("Autostart", "kcm_autostart", "system-run"),
                    { id: "settings.yast", label: "Administration (YaST)", glyph: g(0xF0483), hint: "YaST: openSUSE system administration (asks for root)",
                      children: [{ label: "YaST Control Center", icon: "yast", hint: "YaST: all modules", run: { desktop: "org.opensuse.YaST" } }].concat(yastGroups) },
                ],
            },
            {
                id: "software", label: "Software", glyph: g(0xF03D6), hint: "Install, remove, update",
                children: [
                    { label: "Update System", glyph: g(0xF06B0), hint: "sudo zypper dup · snapper snapshots before & after automatically",
                      run: { terminal: "sudo zypper dup" } },
                    { label: "Install or Remove Software", icon: "yast-sw_single", hint: "YaST › Software Management (official openSUSE repos)", run: { desktop: "YaST2-org.opensuse.yast.SWSingle" } },
                    { label: "Software Repositories", icon: "yast-sw_source", hint: "YaST › Software Repositories", run: { desktop: "YaST2-org.opensuse.yast.SWSource" } },
                    { label: "Discover", icon: "plasmadiscover", hint: "KDE Discover: app store style installer", run: { cmd: ["plasma-discover"] } },
                ],
            },
            {
                id: "system", label: "System", glyph: g(0xF0425), hint: "Lock, power, snapshots",
                children: [
                    { label: "Lock", icon: "system-lock-screen", keys: "Meta + Esc", hint: "Lock the session", run: { cmd: ["loginctl", "lock-session"] } },
                    { label: "Suspend", icon: "system-suspend", hint: "Sleep", run: { cmd: ["systemctl", "suspend"] } },
                    { label: "Log Out", icon: "system-log-out", hint: "End the Plasma session", confirm: true, run: { cmd: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logout"] } },
                    { label: "Restart", icon: "system-reboot", hint: "Reboot the computer", confirm: true, run: { cmd: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logoutAndReboot"] } },
                    { label: "Shut Down", icon: "system-shutdown", hint: "Power off", confirm: true, run: { cmd: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logoutAndShutdown"] } },
                    { label: "Snapshots & Rollback", icon: "yast-snapper", hint: "YaST › Filesystem Snapshots (snapper)", run: { desktop: "YaST2-org.opensuse.yast.Snapper" } },
                    { label: "System Log", icon: "utilities-log-viewer", hint: "YaST › Systemd Journal", run: { desktop: "YaST2-org.opensuse.yast.Journal" } },
                    settingsPage("About This System", "kcm_about-distro", "help-about", "About this System"),
                ],
            },
        ],
    };
}

// Hint mode (lone Meta tap): the main Meta actions needed to drive the system.
// Hard-coded for now. Each row runs the existing KDE global shortcut, after the
// launcher closes, so it acts on the window that was focused before.
function hints() {
    const kwin = (action) => ({ shortcut: ["kwin", action] });
    return [
        { label: "Menu & Search", glyph: g(0xF0349), keys: "Meta + Space", hint: "Apps, settings, YaST, capture, power", run: { menu: true } },
        { label: "All Shortcuts", glyph: g(0xF030C), keys: "Meta + /", hint: "NickKeys: every shortcut, searchable", run: { cmd: ["~/.local/bin/nickkeys", "--gui"] } },
        { label: "Focus Left", glyph: g(0xF004D), keys: "Meta + H", hint: "Tiling: move focus", run: kwin("KrohnkiteFocusLeft") },
        { label: "Focus Down", glyph: g(0xF0045), keys: "Meta + J", hint: "Tiling: move focus", run: kwin("KrohnkiteFocusDown") },
        { label: "Focus Up", glyph: g(0xF005D), keys: "Meta + K", hint: "Tiling: move focus", run: kwin("KrohnkiteFocusUp") },
        { label: "Focus Right", glyph: g(0xF0054), keys: "Meta + L", hint: "Tiling: move focus (also across monitors)", run: kwin("KrohnkiteFocusRight") },
        { label: "Move Window Left", glyph: g(0xF0B28), keys: "Meta + Shift + H", hint: "Tiling: swap with neighbor", run: kwin("KrohnkiteShiftLeft") },
        { label: "Move Window Down", glyph: g(0xF0B26), keys: "Meta + Shift + J", hint: "Tiling: swap with neighbor", run: kwin("KrohnkiteShiftDown") },
        { label: "Move Window Up", glyph: g(0xF0B29), keys: "Meta + Shift + K", hint: "Tiling: swap with neighbor", run: kwin("KrohnkiteShiftUp") },
        { label: "Move Window Right", glyph: g(0xF0B27), keys: "Meta + Shift + L", hint: "Tiling: swap with neighbor", run: kwin("KrohnkiteShiftRight") },
        { label: "Make Main Window", glyph: g(0xF0E45), keys: "Meta + Return", hint: "Tiling: move to the big area", run: kwin("KrohnkiteSetMaster") },
        { label: "Float / Unfloat Window", glyph: g(0xF0B19), keys: "Meta + F", hint: "Tiling: free placement with the mouse", run: kwin("KrohnkiteToggleFloat") },
        { label: "Float / Unfloat All", glyph: g(0xF1009), keys: "Meta + Shift + F", hint: "Tiling: quick normal-desktop mode", run: kwin("KrohnkiteFloatAll") },
        { label: "Monocle", glyph: g(0xF0293), keys: "Meta + M", hint: "Tiling: one window fills the screen", run: kwin("KrohnkiteMonocleLayout") },
        { label: "Close Window", glyph: g(0xF05AD), keys: "Meta + Q", hint: "Closes the window, not always the app", run: kwin("Window Close") },
        { label: "Overview", glyph: g(0xF0568), keys: "Meta + W", hint: "All windows and desktops", run: kwin("Overview") },
        { label: "Lock Screen", glyph: g(0xF033E), keys: "Meta + Esc", hint: "Lock the session", run: { shortcut: ["ksmserver", "Lock Session"] } },
    ];
}

// Every runnable leaf under `node`, with its menu path (used for search)
function leaves(node, path) {
    path = path || [];
    if (!node.children) return [{ item: node, path: path }];
    const here = node.id === "root" ? path : path.concat([node.label]);
    return node.children.reduce((acc, c) => acc.concat(leaves(c, here)), []);
}

// Nodes from the root down to the node with `id` (e.g. "system", "settings.yast"),
// or null if there is no such node
function pathTo(node, id) {
    if (node.id === id) return [node];
    for (const c of node.children || []) {
        const rest = pathTo(c, id);
        if (rest) return [node].concat(rest);
    }
    return null;
}
