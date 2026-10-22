import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.ui

BarItem {
    id: root

    active: panel.active

    function togglePanel() {
        panel.active = !panel.active;
        if (panel.active) NotificationsService.markAllRead();
    }

    onClicked: button => {
        if (button === Qt.RightButton) NotificationsService.toggleSilent();
        else root.togglePanel();
    }

    // Assigned, never bound: it must still hold the old count when the change arrives.
    property int lastUnread: 0
    Component.onCompleted: root.lastUnread = NotificationsService.unread

    Connections {
        target: NotificationsService

        function onUnreadChanged() {
            if (NotificationsService.unread > root.lastUnread) ripple.restart();
            root.lastUnread = NotificationsService.unread;
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { root.togglePanel(); }
        function clear(): void { NotificationsService.clearAll(); }
        function dnd(): void { NotificationsService.toggleSilent(); }
    }

    ShellText {
        text: NotificationsService.silent ? Icons.bellOffOutline : Icons.bell
        color: NotificationsService.silent
            ? Theme.subtle
            : root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize

        // Unread dot on the bell's corner, with a soft halo pulsing out of it.
        Item {
            id: badge
            readonly property int size: 6

            visible: NotificationsService.unread > 0
            width: badge.size
            height: badge.size
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -1
            anchors.topMargin: 1

            Rectangle {
                id: halo
                anchors.centerIn: parent
                width: badge.size
                height: badge.size
                radius: width / 2
                color: Theme.red

                // A few ripples per new arrival, then a still dot: an endless one would redraw
                // the bar every frame for as long as anything sits unread.
                SequentialAnimation {
                    id: ripple
                    loops: 3
                    onStopped: halo.opacity = 0

                    ParallelAnimation {
                        NumberAnimation {
                            target: halo; property: "scale"
                            from: 1; to: 2.4; duration: 1400
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: halo; property: "opacity"
                            from: 0.5; to: 0; duration: 1400
                            easing.type: Easing.OutCubic
                        }
                    }
                    PauseAnimation { duration: 600 }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.red
            }
        }
    }

    // Built on open, destroyed on close: a hidden popup still runs all its bindings.
    LazyLoader {
        id: panel

        NotificationHistoryPanel {
            anchorItem: root
            visible: true
            onDismissed: panel.active = false
        }
    }
}
