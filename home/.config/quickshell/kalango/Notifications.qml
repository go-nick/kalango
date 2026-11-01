// kalango notification server: receives every desktop notification and keeps
// the history behind the top bar's bell.
//   unread: everything not opened, acted on or marked read yet (the bell's count)
//   popups: shown under the bell for a few seconds; critical ones stay until handled
//   dnd:    popups are muted (except critical); notifications still land in the list
// An update from the same app (e.g. a download's progress) changes the same entry.
pragma Singleton

import QtQuick
import Quickshell
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
        const entry = { key: n.id, n: n, time: new Date(), read: false, popup: !dnd || isCritical(n) };
        n.closed.connect(() => { entries = entries.filter(e => e !== entry); });
        // New text from the same notification is news again: unread, on top, popped up
        const renew = () => {
            entry.time = new Date();
            entry.read = false;
            entry.popup = !dnd || isCritical(n);
            entries = [entry].concat(entries.filter(e => e !== entry));
        };
        n.summaryChanged.connect(renew);
        n.bodyChanged.connect(renew);
        entries = [entry].concat(entries);
    }

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
