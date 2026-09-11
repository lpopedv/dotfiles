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
    }

    // Count, not a bare dot: no tooltip to hover for in the bar.
    ShellText {
        visible: NotificationsService.unread > 0
        text: NotificationsService.unread
        color: NotificationsService.urgent ? Theme.red : Theme.fgAct
        font.weight: Font.DemiBold
    }

    NotificationHistoryPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }
}
