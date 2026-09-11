import QtQuick
import Quickshell
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    readonly property int warmTemp: 4000

    // Must outlive a config reload like Caffeine.qml, or it snaps back to cold white.
    property PersistentProperties persist: PersistentProperties {
        reloadableId: "nightlight"
        property bool enabled: false
    }

    active: root.persist.enabled
    onClicked: root.persist.enabled = !root.persist.enabled

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
