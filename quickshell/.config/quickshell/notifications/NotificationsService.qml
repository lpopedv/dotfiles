pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    readonly property int maxHistory: 30

    property bool silent: false
    function toggleSilent() { root.silent = !root.silent; }

    property int unread: 0
    function markAllRead() { root.unread = 0; }

    // Snapshots a Notification's fields once, since the underlying object is
    // destroyed as soon as it closes (ours via archive/dismiss, or the
    // sender's own doing - plenty of apps self-close after their own
    // timeout). History needs to survive that regardless of who closed it,
    // so fields are captured up front instead of bound live to `notification`.
    component Notif: QtObject {
        id: wrapper

        required property int notifId
        property Notification notification
        property double time: Date.now()
        // True while shown as a toast; false once auto-timed-out (still
        // kept in history) or never true at all when arriving under DND.
        property bool popup: false

        property string appName: ""
        property string appIcon: ""
        property string image: ""
        property string summary: ""
        property string body: ""
        property int urgency: NotificationUrgency.Normal
        // Actions stop working once the sender is gone - can't invoke them
        // without a live object - so this naturally empties out on close.
        readonly property var actions: notification?.actions ?? []

        Component.onCompleted: {
            if (!notification) return;
            appName = notification.appName;
            appIcon = notification.appIcon;
            image = notification.image;
            summary = notification.summary;
            body = notification.body;
            urgency = notification.urgency;
        }
    }

    property list<Notif> history: []
    readonly property var popupList: root.history.filter(n => n.popup)

    property Component notifComponent: Component { Notif {} }

    // `image` arrives pre-wrapped as image://icon/<name> and `appIcon` as a
    // bare name, neither checked against the theme. Handing either to Image
    // unvalidated draws Qt's magenta placeholder, because the provider
    // returns that placeholder successfully rather than failing. iconPath's
    // check overload is the only thing that reports a missing icon, so every
    // form is unwrapped down to a name and run through it.
    readonly property string iconUrlPrefix: "image://icon/"

    function resolveIcon(name) {
        if (!name) return "";
        if (name.startsWith(iconUrlPrefix))
            return Quickshell.iconPath(name.substring(iconUrlPrefix.length), true);
        if (name.startsWith("/") || name.startsWith("file:"))
            return name;
        return Quickshell.iconPath(name, true);
    }

    // expireTimeout is already milliseconds (freedesktop spec: -1 means "use
    // the daemon default", 0 means "never expire", positive is the value
    // as-is) - it is NOT seconds, despite what it might look like at a glance.
    function timeoutFor(notification) {
        if (notification.expireTimeout === 0) return 0;
        if (notification.expireTimeout > 0) return notification.expireTimeout;
        if (notification.urgency === NotificationUrgency.Critical) return 8000;
        return notification.urgency === NotificationUrgency.Low ? 4000 : 5000;
    }

    function dropExpired(notifId) {
        root.history = root.history.filter(n => n.notifId !== notifId);
    }

    // Archives a toast into history without closing it, so it survives
    // to be read/actioned later. Used on toast auto-timeout.
    function archive(notif) {
        notif.popup = false;
    }

    // Explicit user dismissal: closes the real notification (if still
    // alive) and always drops it from history - unlike a sender-side
    // close, this one is meant to be final.
    function dismiss(notif) {
        if (notif.notification) notif.notification.dismiss();
        root.dropExpired(notif.notifId);
    }

    function clearAll() {
        for (const notif of root.history) {
            if (notif.notification) notif.notification.dismiss();
        }
        root.history = [];
    }

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const wrapper = root.notifComponent.createObject(root, {
                notifId: notification.id,
                notification: notification,
                popup: !root.silent
            });

            const updated = [wrapper, ...root.history];
            // Evicted entries would otherwise stay tracked (and thus alive)
            // on the server forever, just invisible to the history UI.
            for (const evicted of updated.splice(root.maxHistory)) {
                if (evicted.notification) evicted.notification.dismiss();
            }
            root.history = updated;
            if (!root.silent) root.unread++;
        }
    }
}
