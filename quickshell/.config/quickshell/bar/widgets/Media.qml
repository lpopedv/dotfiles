import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../.."
import "../../ui"

BarItem {
    id: root

    // Prefer whatever is playing; otherwise the first player so a paused
    // track stays controllable.
    readonly property var player: {
        const list = Mpris.players.values;
        for (const p of list)
            if (p.isPlaying) return p;
        return list.length > 0 ? list[0] : null;
    }

    visible: player !== null

    Binding {
        target: CavaService
        property: "enabled"
        value: root.player !== null && root.player.isPlaying
    }
    active: panel.visible

    onClicked: button => {
        if (button === Qt.LeftButton) panel.visible = !panel.visible;
        else if (button === Qt.RightButton && player && player.canTogglePlaying)
            player.togglePlaying();
        else if (button === Qt.MiddleButton && player && player.canGoNext)
            player.next();
    }

    MediaPanel {
        id: panel
        player: root.player
        anchorItem: root
        visible: false
        grabFocus: true
    }

    // Clicking the icon toggles playback; the rest of the widget opens the panel.
    Rectangle {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 22
        color: toggle.containsMouse ? Theme.activeFill : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }

        ShellText {
            anchors.centerIn: parent
            visible: !(root.player && root.player.isPlaying)
            text: Icons.play
            color: root.hovered || toggle.containsMouse || panel.visible ? Theme.fgAct : Theme.fg
            font.pixelSize: Theme.iconSize
        }

        Spectrum {
            anchors.centerIn: parent
            width: 22
            height: 14
            visible: root.player && root.player.isPlaying
            count: 6
            spacing: 2
        }

        MouseArea {
            id: toggle
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.player !== null && root.player.canTogglePlaying
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.player.togglePlaying()
        }
    }

    ShellText {
        text: root.player
            ? (root.player.trackTitle || root.player.identity || "")
            : ""
        color: root.hovered || panel.visible ? Theme.fgAct : Theme.fg
        elide: Text.ElideRight
        Layout.maximumWidth: 180
        visible: text.length > 0
    }
}
