import QtQuick
import QtQuick.Layouts
import "../.."
import "../../ui"

BarItem {
    id: root

    onClicked: {
        panel.visible = !panel.visible;
        if (panel.visible) NotificationsService.markAllRead();
    }

    RowLayout {
        spacing: 4

        ShellText {
            text: Icons.bell
            color: root.active || root.hovered ? Theme.fgAct : Theme.fg
            font.pixelSize: Theme.iconSize
        }

        ShellText {
            visible: NotificationsService.unread > 0
            text: String(NotificationsService.unread)
            color: Theme.red
            font.weight: Font.DemiBold
        }
    }

    NotificationHistoryPanel {
        id: panel
        anchorItem: root
        visible: false
    }

    active: panel.visible
}
