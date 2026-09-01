import QtQuick
import "../.."
import "../../ui"

BarItem {
    id: root

    active: NotificationsService.silent
    onClicked: NotificationsService.toggleSilent()

    ShellText {
        text: root.active ? Icons.bellOffOutline : Icons.bellOutline
        color: root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
