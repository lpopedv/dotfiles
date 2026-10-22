pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Toast timeout/close only hides the toast - stays alive in history. Only
// explicit removal (x, Clear all, invoking an action) tells the sender it's
// gone. Sender withdrawing its own notification removes it everywhere.
QtObject {
    id: root

    readonly property int maxHistory: 50
    // Caps toasts on screen; a notification burst shouldn't paper over the whole desktop.
    readonly property int maxPopups: 4

    // Read by both the card and the exit timer so they can't fall out of step.
    readonly property int leaveMs: 110

    property bool silent: false
    function toggleSilent() { root.silent = !root.silent; }

    // Critical notifications ignore Do Not Disturb (KDE convention).
    function wantsPopup(urgency) {
        return !root.silent || urgency === NotificationUrgency.Critical;
    }

    // Snapshot of a Notification that outlives it: the sender's object is
    // destroyed on close, so `detach` copies fields out first. Until then
    // they're live bindings, since replaces_id updates this object in place.
    component Notif: QtObject {
        id: wrapper

        // Inline component can't reach `root` by scope; service hands itself in at creation.
        required property var service

        required property int notifId
        property Notification notification

        property double time: Date.now()
        property bool read: false
        property bool popup: false
        // True while the leaving animation plays, so the stack collapses smoothly.
        property bool closing: false
        // Bumped on replace; the toast's cue to restart its countdown.
        property int generation: 0

        // popupList is a plain array: any change rebuilds every card, so the
        // countdown reads from here instead of restarting each rebuild.
        property double popupAt: Date.now()
        onPopupChanged: if (wrapper.popup) wrapper.popupAt = Date.now();

        // Timed here, not in the card: a card destroyed mid-fade would never clear `popup`.
        property Timer exit: Timer {
            interval: wrapper.service.leaveMs + 20
            running: wrapper.closing
            onTriggered: wrapper.service.popupClosed(wrapper)
        }

        property string appName: notification ? notification.appName : ""
        property string appIcon: notification ? notification.appIcon : ""
        property string desktopEntry: notification ? notification.desktopEntry : ""
        property string image: notification ? notification.image : ""
        property string summary: notification ? notification.summary : ""
        property string body: notification ? notification.body : ""
        property int urgency: notification ? notification.urgency : NotificationUrgency.Normal
        // transient = skip history; resident = survive its own action being invoked.
        property bool isTransient: notification ? notification.transient : false
        property bool isResident: notification ? notification.resident : false
        // Empties on detach (no live sender to invoke), so buttons disappear with it.
        property var actions: notification ? notification.actions : []

        readonly property int timeout: wrapper.service.timeoutFor(wrapper)

        // True once the sender's first state is in; anything after is a genuine replacement.
        property bool settled: false
        Component.onCompleted: wrapper.settled = true

        property Connections link: Connections {
            target: wrapper.notification

            function onClosed(reason) {
                // Fires on both sender withdrawal and our own close; detach() is a no-op for the latter.
                wrapper.detach();
                wrapper.service.remove(wrapper);
            }

            function onSummaryChanged() { wrapper.replaced(); }
            function onBodyChanged() { wrapper.replaced(); }
        }

        function replaced() {
            if (!wrapper.settled) return;
            wrapper.time = Date.now();
            wrapper.read = false;
            // Set by hand: if popup was already true, its onPopupChanged won't refire.
            wrapper.popupAt = Date.now();
            wrapper.generation++;
            if (wrapper.service.wantsPopup(wrapper.urgency)) {
                wrapper.closing = false;
                wrapper.popup = true;
                wrapper.service.trimPopups();
            }
        }

        // Freezes fields into plain values (breaking their bindings) so the card
        // keeps rendering real text during its exit animation.
        function detach() {
            const sender = wrapper.notification;
            if (!sender) return null;
            wrapper.appName = sender.appName;
            wrapper.appIcon = sender.appIcon;
            wrapper.desktopEntry = sender.desktopEntry;
            wrapper.image = sender.image;
            wrapper.summary = sender.summary;
            wrapper.body = sender.body;
            wrapper.urgency = sender.urgency;
            wrapper.isTransient = sender.transient;
            wrapper.isResident = sender.resident;
            wrapper.actions = [];
            // Last: everything above reads through it.
            wrapper.notification = null;
            return sender;
        }
    }

    property Component notifComponent: Component { Notif {} }

    property list<Notif> history: []

    readonly property int unread: {
        let count = 0;
        for (const notif of root.history) if (!notif.read) count++;
        return count;
    }

    readonly property bool urgent: {
        for (const notif of root.history)
            if (!notif.read && notif.urgency === NotificationUrgency.Critical) return true;
        return false;
    }

    // Oldest first so a new toast joins nearest the corner. Closing toasts
    // stay past the cap so their exit animation can finish (else `popup` never clears).
    readonly property var popupList: {
        const shown = [];
        let live = 0;
        for (const notif of root.history) {
            if (!notif.popup) continue;
            if (notif.closing) {
                shown.push(notif);
            } else if (live < root.maxPopups) {
                live++;
                shown.push(notif);
            }
        }
        return shown.reverse();
    }

    // Drops oldest toasts to history when full; not queued (stale news), and
    // critical toasts never time out on their own so they'd hold every slot.
    function trimPopups() {
        let live = 0;
        for (const notif of root.history) {
            if (!notif.popup || notif.closing) continue;
            live++;
            if (live > root.maxPopups) root.hidePopup(notif);
        }
    }

    function markAllRead() {
        for (const notif of root.history) notif.read = true;
    }

    property bool historyOpen: false

    property double now: Date.now()

    // Single shared ticker, not one per panel, so two lists never disagree on age.
    readonly property Timer clock: Timer {
        running: root.popupList.length > 0 || root.historyOpen
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    function elapsed(then) {
        const secs = Math.floor((root.now - then) / 1000);
        if (secs < 45) return "now";
        const mins = Math.round(secs / 60);
        if (mins < 60) return mins + "m";
        const hours = Math.floor(mins / 60);
        if (hours < 24) return hours + "h";
        return Math.floor(hours / 24) + "d";
    }

    // expireTimeout is already milliseconds per the freedesktop spec (-1 =
    // daemon default, 0 = never). Critical notifications ignore any requested expiry.
    function timeoutFor(notif) {
        if (notif.urgency === NotificationUrgency.Critical) return 0;
        const requested = notif.notification ? notif.notification.expireTimeout : -1;
        if (requested === 0) return 0;
        if (requested > 0) return Math.max(1500, requested);
        return notif.urgency === NotificationUrgency.Low ? 4000 : 5000;
    }

    function hidePopup(notif) {
        if (!notif || !notif.popup || notif.closing) return;
        notif.closing = true;
    }

    function popupClosed(notif) {
        if (!notif) return;
        notif.closing = false;
        notif.popup = false;
        if (notif.isTransient) root.remove(notif);
    }

    // Doesn't touch `history` (caller's job); without destroy() wrappers pile up all session.
    function discard(notif) {
        const sender = notif.detach();
        if (sender) sender.dismiss();
        notif.destroy();
    }

    function remove(notif) {
        if (!notif) return;
        const kept = [];
        for (const other of root.history) if (other !== notif) kept.push(other);
        if (kept.length === root.history.length) return;
        root.history = kept;
        root.discard(notif);
    }

    function clearAll() {
        const all = [];
        for (const notif of root.history) all.push(notif);
        root.history = [];
        for (const notif of all) root.discard(notif);
    }

    // Freedesktop convention: "default" is triggered by clicking the body, never drawn as a button.
    function defaultAction(notif) {
        for (const action of notif.actions)
            if (action.identifier === "default") return action;
        return null;
    }

    function buttonActions(notif) {
        const out = [];
        for (const action of notif.actions)
            if (action.identifier !== "default") out.push(action);
        return out;
    }

    function invoke(notif, action) {
        if (!action) return;
        action.invoke();
        // Resident senders (media controls, progress dialogs) keep the notification on purpose.
        if (notif.isResident) root.hidePopup(notif);
        else root.remove(notif);
    }

    function activate(notif) {
        notif.read = true;
        const action = root.defaultAction(notif);
        if (action) root.invoke(notif, action);
        else root.hidePopup(notif);
    }

    // Image draws Qt's magenta placeholder for an unknown icon *name* instead
    // of failing, so bare names must go through iconPath's checked overload; real URLs pass through.
    readonly property string iconUrlPrefix: "image://icon/"

    function resolveIcon(name) {
        if (!name) return "";
        if (name.startsWith(iconUrlPrefix))
            return Quickshell.iconPath(name.substring(iconUrlPrefix.length), true);
        if (name.startsWith("/") || name.indexOf("://") >= 0) return name;
        return Quickshell.iconPath(name, true);
    }

    function appIconFor(notif) {
        const direct = root.resolveIcon(notif.appIcon);
        if (direct) return direct;

        let entry = null;
        if (notif.desktopEntry) entry = DesktopEntries.byId(notif.desktopEntry);
        if (!entry && notif.appName) entry = DesktopEntries.heuristicLookup(notif.appName);
        return entry ? root.resolveIcon(entry.icon) : "";
    }

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        // Matches Text.StyledText in NotificationCard.qml.
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const wrapper = root.notifComponent.createObject(root, {
                service: root,
                notifId: notification.id,
                notification: notification,
                popup: root.wantsPopup(notification.urgency)
            });

            const updated = [wrapper, ...root.history];
            // Otherwise evicted entries stay tracked (and alive) on the server, just invisible.
            for (const evicted of updated.splice(root.maxHistory)) root.discard(evicted);
            root.history = updated;
            root.trimPopups();
        }
    }
}
