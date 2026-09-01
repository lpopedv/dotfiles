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

    // Wraps a live Notification with fields that survive after the sender
    // closes it (the underlying object is destroyed post-close, per
    // Quickshell docs, so `notification` goes null and reads off it would
    // otherwise go blank right when the history panel wants to show them).
    component Notif: QtObject {
        id: wrapper

        required property int notifId
        property Notification notification
        property double time: Date.now()
        // True while shown as a toast; false once auto-timed-out (still
        // kept in history) or never true at all when arriving under DND.
        property bool popup: false

        readonly property string appName: notification?.appName ?? ""
        readonly property string appIcon: notification?.appIcon ?? ""
        readonly property string image: notification?.image ?? ""
        readonly property string summary: notification?.summary ?? ""
        readonly property string body: notification?.body ?? ""
        readonly property int urgency:
            notification ? notification.urgency : NotificationUrgency.Normal
        readonly property var actions: notification?.actions ?? []

        onNotificationChanged: {
            if (!notification) root.dropExpired(wrapper.notifId);
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

    function timeoutFor(notification) {
        if (notification.expireTimeout > 0) return notification.expireTimeout * 1000;
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

    // Explicit user dismissal: closes the real notification, which then
    // removes itself from history via onNotificationChanged above.
    function dismiss(notif) {
        if (notif.notification) notif.notification.dismiss();
        else root.dropExpired(notif.notifId);
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
