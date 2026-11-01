// kalango notification server: receives every desktop notification and keeps
// the history behind the top bar's bell.
//   unread: everything not opened, acted on or marked read yet (the bell's count)
//   popups: shown under the bell for a few seconds; critical ones stay until handled
//   dnd:    popups are muted (except critical); notifications still land in the list
// An update from the same app (e.g. a download's progress) changes the same entry.
// History survives logout in ~/.local/state/kalango/notifications.json (private folder,
// newest 200). Restored entries keep their text and read state, but the app's buttons
// are gone with its connection.
// Sounds: normal and critical popups only, muted with DND, low priority or the Sound button.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Newest first: { key, n: Notification, time: Date, read: bool, popup: bool }.
    // Views use ScriptModel with objectProp "key" so delegates survive refreshes, and
    // read entry fields through `Notifications.entries` to stay reactive.
    property var entries: []
    readonly property var popups: entries.filter(e => e.popup)
    readonly property int unread: entries.filter(e => !e.read).length
    property bool dnd: false
    property bool listOpen: false

    // Ticks every minute so "5 min ago" labels stay current
    readonly property date now: clock.date
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // "Today 21:53 · 5 min ago", "Yesterday 18:02", "Saturday 09:15", "Mon 12 Oct 09:15"
    function when(t) {
        const day = d => new Date(d.getFullYear(), d.getMonth(), d.getDate());
        const days = Math.round((day(now) - day(t)) / 86400000);
        const hm = Qt.formatTime(t, "HH:mm");
        if (days === 0) {
            const mins = Math.floor((now - t) / 60000);
            return "Today " + hm + (mins < 1 ? " · now" : mins < 60 ? ` · ${mins} min ago` : "");
        }
        if (days === 1) return "Yesterday " + hm;
        if (days < 7) return Qt.formatDate(t, "dddd") + " " + hm;
        return Qt.formatDate(t, t.getFullYear() === now.getFullYear() ? "ddd d MMM" : "d MMM yyyy") + " " + hm;
    }

    // Entries are plain JS objects; reassigning the array refreshes every binding
    function refresh() { entries = entries.slice(); }

    function isCritical(n) { return n.urgency === NotificationUrgency.Critical; }

    function add(n) {
        restore();
        const entry = { key: n.id, n: n, time: new Date(), read: false, popup: !dnd || isCritical(n) };
        // After a hot reload the server hands back live notifications we also restored
        if (n.lastGeneration) {
            const copy = entries.find(e => e.restored && e.n.appName === n.appName
                                      && e.n.summary === n.summary && e.n.body === n.body);
            if (copy) {
                entry.time = copy.time;
                entry.read = copy.read;
                entries = entries.filter(e => e !== copy);
            }
            entry.popup = false;
        }
        n.closed.connect(() => { entries = entries.filter(e => e !== entry); });
        // New text from the same notification is news again: unread, on top, popped up
        const renew = () => {
            entry.time = new Date();
            entry.read = false;
            entry.popup = !dnd || isCritical(n);
            entries = [entry].concat(entries.filter(e => e !== entry));
        };
        if (entry.popup && !n.lastGeneration) playSound(n);
        n.summaryChanged.connect(renew);
        n.bodyChanged.connect(renew);
        entries = [entry].concat(entries).sort((a, b) => b.time - a.time);
    }

    // ── sounds ──
    property bool sounds: true
    onSoundsChanged: if (restored) saver.restart()
    function toggleSounds() { sounds = !sounds; }
    property real lastSound: 0

    // Apps can ask for silence or name their own sound (sound-file, sound-name)
    function playSound(n) {
        if (!sounds || n.urgency === NotificationUrgency.Low || n.hints["suppress-sound"]) return;
        // A burst of notifications makes one sound, not ten
        if (Date.now() - lastSound < 500) return;
        lastSound = Date.now();
        const ocean = name => `/usr/share/sounds/ocean/stereo/${name}.oga`;
        const fallback = ocean(isCritical(n) ? "dialog-warning" : "message-new-instant");
        const wanted = String(n.hints["sound-file"] || "").replace(/^file:\/\//, "")
                       || (n.hints["sound-name"] ? ocean(n.hints["sound-name"]) : fallback);
        Quickshell.execDetached(["sh", "-c", '[ -f "$1" ] && exec pw-play "$1"; exec pw-play "$2"',
                                 "sh", wanted, fallback]);
    }

    // ── history on disk ──
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
                                        || Quickshell.env("HOME") + "/.local/state") + "/kalango"
    property bool restored: false
    onEntriesChanged: if (restored) saver.restart()

    function restore() {
        if (restored) return;
        restored = true;
        Quickshell.execDetached(["mkdir", "-pm", "700", stateDir]);
        try {
            const saved = JSON.parse(history.text());
            sounds = saved.sounds !== false;
            entries = saved.notifications.map(fromDisk);
        } catch (e) {
            // No history yet, or an unreadable file: start empty
        }
    }

    // Stands in for a live Notification, with the fields NotificationCard reads
    function fromDisk(s, i) {
        const entry = { key: `saved-${i}-${s.time}`, time: new Date(s.time), read: s.read,
                        popup: false, restored: true };
        entry.n = { appName: s.appName, appIcon: s.appIcon, desktopEntry: s.desktopEntry,
                    summary: s.summary, body: s.body, urgency: s.urgency, image: s.image,
                    actions: [], hints: {}, hasInlineReply: false, inlineReplyPlaceholder: "",
                    transient: false,
                    dismiss: () => { entries = entries.filter(e => e !== entry); } };
        return entry;
    }

    function save() {
        // image:// URLs only exist in this process; files and icon names outlive it
        const lasting = url => url && url.includes("image://") ? "" : url;
        history.setText(JSON.stringify({
            sounds: sounds,
            notifications: entries.filter(e => !e.n.transient).slice(0, 200).map(e => ({
                appName: e.n.appName, appIcon: lasting(e.n.appIcon), desktopEntry: e.n.desktopEntry,
                summary: e.n.summary, body: e.n.body, urgency: e.n.urgency,
                image: lasting(e.n.image), time: e.time.toISOString(), read: e.read,
            })),
        }));
    }

    FileView {
        id: history
        path: root.stateDir + "/notifications.json"
        blockLoading: true
        blockWrites: true
        printErrors: false
    }
    Timer { id: saver; interval: 500; onTriggered: root.save() }
    Component.onCompleted: restore()
    Component.onDestruction: if (saver.running) save()

    function hidePopup(entry) {
        entry.popup = false;
        // Transient notifications only make sense as a popup
        if (entry.n.transient) entry.n.dismiss();
        else refresh();
    }

    function markRead(entry) {
        entry.read = true;
        entry.popup = false;
        refresh();
    }

    function markAllRead() {
        for (const e of entries) { e.read = true; e.popup = false; }
        refresh();
    }

    // Closing a notification removes it through its closed signal
    function dismiss(entry) { entry.n.dismiss(); }
    function clearAll() { for (const e of entries.slice()) e.n.dismiss(); }

    // Clicking a notification runs its default action, if the app gave one
    function activate(entry) {
        const action = entry.n.actions.find(a => a.identifier === "default");
        markRead(entry);
        if (action) action.invoke();
    }

    function toggleList() { listOpen = !listOpen; }
    function toggleDnd() {
        dnd = !dnd;
        if (dnd) {
            for (const e of entries) if (!isCritical(e.n)) e.popup = false;
            refresh();
        }
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: n => {
            n.tracked = true;
            root.add(n);
        }
    }
}
