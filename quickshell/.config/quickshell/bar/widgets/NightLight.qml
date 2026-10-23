import QtQuick
import qs
import qs.services
import qs.ui

BarItem {
    id: root

    active: NightLightService.enabled
    onClicked: NightLightService.toggle()

    ShellText {
        text: Icons.moon
        color: root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
