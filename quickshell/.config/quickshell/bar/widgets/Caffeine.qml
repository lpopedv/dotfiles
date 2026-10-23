import QtQuick
import qs
import qs.services
import qs.ui

BarItem {
    id: root

    active: CaffeineService.enabled
    onClicked: CaffeineService.toggle()

    ShellText {
        text: Icons.coffee
        color: root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
