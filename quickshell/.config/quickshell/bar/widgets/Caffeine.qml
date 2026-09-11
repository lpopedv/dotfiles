import QtQuick
import Quickshell
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    // Must outlive a config reload, or the inhibitor drops and the machine locks mid-use.
    property PersistentProperties persist: PersistentProperties {
        reloadableId: "caffeine"
        property bool enabled: false
    }

    active: root.persist.enabled
    onClicked: root.persist.enabled = !root.persist.enabled

    IpcHandler {
        target: "caffeine"

        function toggle(): void { root.persist.enabled = !root.persist.enabled; }
        function on(): void { root.persist.enabled = true; }
        function off(): void { root.persist.enabled = false; }
        function status(): bool { return root.persist.enabled; }
    }

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
