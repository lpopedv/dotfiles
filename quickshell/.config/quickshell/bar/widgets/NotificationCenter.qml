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

    Item {
        implicitWidth: bellIcon.implicitWidth
        implicitHeight: bellIcon.implicitHeight

        ShellText {
            id: bellIcon
            text: Icons.bell
            color: root.active || root.hovered ? Theme.fgAct : Theme.fg
            font.pixelSize: Theme.iconSize
        }

        Rectangle {
            visible: NotificationsService.unread > 0
            width: 6
            height: 6
            radius: 3
            color: Theme.red
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -1
            anchors.rightMargin: -1

            SequentialAnimation on opacity {
                running: NotificationsService.unread > 0
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 900; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
            }
        }
    }

    NotificationHistoryPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }

    active: panel.visible
}
