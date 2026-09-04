import QtQuick
import ".."

// Small clickable label. Notification actions, "Clear all" and the Do Not
// Disturb switch are all the same affordance at different weights, so they
// share one so their hit targets and hover feedback cannot drift apart.
Rectangle {
    id: root

    property alias text: label.text
    property bool active: false
    // Borderless until hovered - for text that reads as a link rather than a
    // button ("Clear all"), where a permanent box would shout.
    property bool quiet: false
    property color textColor: root.active || mouse.containsMouse ? Theme.fgAct : Theme.fg

    readonly property bool hovered: mouse.containsMouse

    signal clicked

    implicitWidth: label.implicitWidth + (root.quiet ? 14 : 20)
    implicitHeight: label.implicitHeight + 10

    color: root.active ? Theme.activeFill
        : mouse.containsMouse ? Theme.hoverFill
        : root.quiet ? "transparent" : Theme.divider
    border.width: root.quiet && !root.active && !mouse.containsMouse ? 0 : 1
    border.color: root.active ? Theme.accentLine : Theme.divider

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }

    ShellText {
        id: label
        anchors.centerIn: parent
        color: root.textColor

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
