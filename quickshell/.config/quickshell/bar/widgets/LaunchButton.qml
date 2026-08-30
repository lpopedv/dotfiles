import QtQuick
import Quickshell
import "../.."
import "../../ui"

BarItem {
    id: root

    property string icon: ""
    property var command: []
    property int iconSize: Theme.iconSize

    onClicked: {
        if (root.command.length > 0) Quickshell.execDetached(root.command);
    }

    ShellText {
        text: root.icon
        color: root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: root.iconSize
    }
}
