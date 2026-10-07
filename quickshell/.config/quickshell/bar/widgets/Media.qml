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
    Item {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 14

        ShellText {
            anchors.centerIn: parent
            visible: !(root.player && root.player.isPlaying)
            text: Icons.play
            color: root.hovered || panel.visible ? Theme.fgAct : Theme.fg
            font.pixelSize: Theme.iconSize
        }

        Spectrum {
            anchors.fill: parent
            visible: root.player && root.player.isPlaying
            count: 6
            spacing: 2
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.player !== null && root.player.canTogglePlaying
            acceptedButtons: Qt.LeftButton
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
