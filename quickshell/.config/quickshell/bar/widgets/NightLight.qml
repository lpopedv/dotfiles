import QtQuick
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    readonly property int warmTemp: 4000

    onClicked: root.active = !root.active

    Process {
        command: ["hyprsunset", "-t", String(root.warmTemp)]
        running: root.active
    }

    ShellText {
        text: Icons.moon
        color: root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
