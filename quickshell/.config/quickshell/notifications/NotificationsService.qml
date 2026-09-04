pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The whole notification model lives here so the toast stack and the history
// panel can never disagree about what exists. The behaviour it implements is
// the one GNOME and KDE share:
//
//   - a toast timing out or being closed by hand only takes the *toast* away;
//     the notification stays in history, still alive, so its buttons work
//   - only an explicit removal (the row's x, "Clear all", or invoking an
//     action) tells the sender the notification is gone
//   - a sender withdrawing its own notification removes it everywhere, which
//     is what makes chat apps stop leaving read messages behind
QtObject {
    id: root

    readonly property int maxHistory: 50
    // GNOME and KDE both cap how many toasts are on screen and queue the rest.
    // Without this a burst of notifications papers over the whole desktop.
    readonly property int maxPopups: 4

    // How long a toast takes to animate away. The card and the exit timer both
    // read it, so the two cannot fall out of step and strand a half-faded card.
    readonly property int leaveMs: 110

    // ------------------------------------------------------------ do not disturb

    property bool silent: false
    function toggleSilent() { root.silent = !root.silent; }

    // Critical notifications ignore Do Not Disturb, the way KDE treats them.
    // The point of the urgency level is that it survives being muted.
    function wantsPopup(urgency) {
        return !root.silent || urgency === NotificationUrgency.Critical;
    }

    // ------------------------------------------------------------------ entries

    // Snapshot of a Notification that outlives it. The sender's object is
    // destroyed the moment the notification closes, so `detach` copies the
    // fields into plain values before that happens; until then they are live
    // bindings, because a sender replacing a notification through replaces_id
    // updates this same object in place rather than sending a new one.
    component Notif: QtObject {
        id: wrapper

        // An inline component does not share scope with the file it is
        // declared in, so it cannot reach `root` by id - the service hands
        // itself in at creation instead.
        required property var service

        required property int notifId
        property Notification notification

        property double time: Date.now()
        property bool read: false
        // True while shown as a toast. False once it has timed out or been
        // closed by hand (still in history), or from the start under DND.
        property bool popup: false
        // Set while the toast plays its leaving animation, so the stack
        // collapses smoothly instead of snapping shut.
        property bool closing: false
        // Bumped when the sender replaces the notification, which is the
        // toast's cue to start its countdown over.
        property int generation: 0

        // When the toast's current stretch on screen began. `popupList` is a
        // plain array, so any change to it rebuilds every card from scratch;
        // the countdown measures from here rather than starting over each time
        // that happens.
        property double popupAt: Date.now()
        onPopupChanged: if (wrapper.popup) wrapper.popupAt = Date.now();

        // The exit is timed here and not in the card for the same reason: a
        // card destroyed mid-fade would never get round to clearing `popup`,
        // and the toast would sit on screen for good.
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
        // Senders that set these want, respectively, to be left out of history
        // entirely and to survive one of their own actions being invoked.
        property bool isTransient: notification ? notification.transient : false
        property bool isResident: notification ? notification.resident : false
        // Actions cannot be invoked without a live sender, so this empties out
        // on detach and the buttons disappear with it.
        property var actions: notification ? notification.actions : []

        readonly property int timeout: wrapper.service.timeoutFor(wrapper)

        // Only true once the sender's first state is in. Everything after that
        // is a genuine replacement.
        property bool settled: false
        Component.onCompleted: wrapper.settled = true

        property Connections link: Connections {
            target: wrapper.notification

            function onClosed(reason) {
                // Reached both when the sender withdraws the notification and
                // when we close it ourselves; `detach` makes the second case a
                // no-op, so this only ever has real work to do for the first.
                wrapper.detach();
                wrapper.service.remove(wrapper);
            }

            function onSummaryChanged() { wrapper.replaced(); }
            function onBodyChanged() { wrapper.replaced(); }
        }

        // A replaced notification is new information, so it goes back on
        // screen with a fresh countdown - this is what makes now-playing and
        // progress notifications behave instead of flickering past.
        function replaced() {
            if (!wrapper.settled) return;
            wrapper.time = Date.now();
            wrapper.read = false;
            // Set by hand: `popup` may already be true, in which case its own
            // change handler never fires and the countdown would carry on from
            // the superseded notification's start.
            wrapper.popupAt = Date.now();
            wrapper.generation++;
            if (wrapper.service.wantsPopup(wrapper.urgency)) {
                wrapper.closing = false;
                wrapper.popup = true;
                wrapper.service.trimPopups();
            }
        }

        // Freezes the sender's fields into plain values and lets go of it,
        // returning it so the caller can decide whether to close it. Assigning
        // to each property breaks its binding, which is the point: the card
        // keeps rendering real text for the frame it takes to animate away.
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

    // ------------------------------------------------------------------ history

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

    // Oldest first, so a new toast joins at the bottom of the stack nearest the
    // corner and whichever times out first leaves from the top - the toast
    // under the pointer does not shift while it is being read.
    //
    // Toasts on their way out stay in the list past the cap so their leaving
    // animation can finish; without that they would be yanked mid-fade and
    // their `popup` flag would never get cleared.
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

    // Stands the oldest toasts down to history once the screen is full. They
    // are not queued for later: a notification that surfaces half a minute
    // after it happened is no longer news, and critical toasts - which never
    // time out on their own - would otherwise hold every slot forever.
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

    // True while the history panel is on screen; only used to keep the clock
    // below from ticking for nothing.
    property bool historyOpen: false

    property double now: Date.now()

    readonly property Timer clock: Timer {
        // One ticker for every relative timestamp on screen. Per-panel timers
        // are how two lists end up disagreeing about how old something is.
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

    // ---------------------------------------------------------------- lifecycle

    // expireTimeout is already milliseconds (freedesktop spec: -1 means "use
    // the daemon default", 0 means "never expire", positive is the value
    // as-is) - it is NOT seconds, despite what it might look like at a glance.
    // Critical notifications never time out on their own, matching GNOME and
    // KDE; a sender asking for one to expire is deliberately ignored.
    function timeoutFor(notif) {
        if (notif.urgency === NotificationUrgency.Critical) return 0;
        const requested = notif.notification ? notif.notification.expireTimeout : -1;
        if (requested === 0) return 0;
        if (requested > 0) return Math.max(1500, requested);
        return notif.urgency === NotificationUrgency.Low ? 4000 : 5000;
    }

    // Takes the toast off screen and leaves the entry in history, alive. This
    // is what a timeout and the toast's own close button do.
    function hidePopup(notif) {
        if (!notif || !notif.popup || notif.closing) return;
        notif.closing = true;
    }

    // Runs off the entry's own exit timer, once the card has had time to
    // animate away.
    function popupClosed(notif) {
        if (!notif) return;
        notif.closing = false;
        notif.popup = false;
        // Transient notifications are explicitly not meant to be persisted.
        if (notif.isTransient) root.remove(notif);
    }

    // Lets go of an entry for good: tells the sender it is gone and frees the
    // wrapper. Callers take it out of `history` first - this does not touch
    // the list. Without the destroy() these pile up on the singleton for the
    // whole session.
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

    // ------------------------------------------------------------------ actions

    // The "default" action is what clicking the notification body triggers and
    // is never drawn as a button - that is the freedesktop convention every
    // desktop follows.
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
        // A resident sender keeps the notification on purpose (media controls,
        // progress dialogs); anything else is finished once it is actioned.
        if (notif.isResident) root.hidePopup(notif);
        else root.remove(notif);
    }

    function activate(notif) {
        notif.read = true;
        const action = root.defaultAction(notif);
        if (action) root.invoke(notif, action);
        else root.hidePopup(notif);
    }

    // -------------------------------------------------------------------- icons

    // `image` is whatever the sender attached - an avatar, album art, or a raw
    // pixmap handed back as image://qsimage/... - and `appIcon` is an icon
    // name. Neither is checked against the theme, and handing an unknown *name*
    // to Image draws Qt's magenta placeholder, because the icon provider
    // returns that placeholder successfully rather than failing. iconPath's
    // check overload is the only thing that reports a missing icon, so bare
    // names go through it and real URLs are passed straight through.
    readonly property string iconUrlPrefix: "image://icon/"

    function resolveIcon(name) {
        if (!name) return "";
        if (name.startsWith(iconUrlPrefix))
            return Quickshell.iconPath(name.substring(iconUrlPrefix.length), true);
        if (name.startsWith("/") || name.indexOf("://") >= 0) return name;
        return Quickshell.iconPath(name, true);
    }

    // Senders that set no icon name usually still declare their desktop entry,
    // which is where GNOME and KDE go looking next.
    function appIconFor(notif) {
        const direct = root.resolveIcon(notif.appIcon);
        if (direct) return direct;

        let entry = null;
        if (notif.desktopEntry) entry = DesktopEntries.byId(notif.desktopEntry);
        if (!entry && notif.appName) entry = DesktopEntries.heuristicLookup(notif.appName);
        return entry ? root.resolveIcon(entry.icon) : "";
    }

    // ------------------------------------------------------------------- server

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: false
        // We keep a history, so senders may say so in their own UI.
        persistenceSupported: true
        bodySupported: true
        // The spec's body markup is the <b>/<i>/<u>/<a> subset, which is
        // exactly what Text.StyledText renders - see NotificationCard.
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
            // Evicted entries would otherwise stay tracked - and so alive - on
            // the server forever, just invisible to the history UI.
            for (const evicted of updated.splice(root.maxHistory)) root.discard(evicted);
            root.history = updated;
            root.trimPopups();
        }
    }
}
