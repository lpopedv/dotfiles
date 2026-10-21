import QtQuick
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    active: panel.visible

    function togglePanel() {
        panel.visible = !panel.visible;
        if (panel.visible) NotificationsService.markAllRead();
    }

    onClicked: button => {
        if (button === Qt.RightButton) NotificationsService.toggleSilent();
        else root.togglePanel();
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

                SequentialAnimation {
                    running: badge.visible
                    loops: Animation.Infinite

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

    NotificationHistoryPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }
}
