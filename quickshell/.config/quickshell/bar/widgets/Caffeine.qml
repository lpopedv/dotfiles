import QtQuick
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    onClicked: root.active = !root.active

    Process {
        command: [
            "systemd-inhibit",
            "--what=idle",
            "--who=quickshell",
            "--why=Caffeine mode (manual)",
            "sleep", "infinity"
        ]
        running: root.active
    }

    ShellText {
        text: Icons.coffee
        color: root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
