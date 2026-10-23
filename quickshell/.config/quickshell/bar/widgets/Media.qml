pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtQuick.Layouts
import qs
import qs.services
import qs.ui

BarItem {
    id: root

    readonly property var player: MediaService.player

    visible: player !== null
    active: panel.active

    onClicked: button => {
        if (button === Qt.LeftButton) panel.active = !panel.active;
        else if (button === Qt.RightButton && player && player.canTogglePlaying)
            player.togglePlaying();
        else if (button === Qt.MiddleButton && player && player.canGoNext)
            player.next();
    }

    // Built on open, destroyed on close: a hidden popup still runs all its bindings.
    LazyLoader {
        id: panel

        MediaPanel {
            player: root.player
            anchorItem: root
            visible: true
            onDismissed: panel.active = false
        }
    }

    // Clicking the icon toggles playback; the rest of the widget opens the panel.
    // A still glyph, not a live spectrum: that would redraw the bar (and have Hyprland
    // re-blur it) at cava's frame rate for as long as music plays. The panel has one.
    Rectangle {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 22
        radius: Theme.radiusItem
        color: toggle.containsMouse ? Theme.activeFill : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }

        ShellText {
            anchors.centerIn: parent
            text: MediaService.playing ? Icons.pause : Icons.play
            color: root.hovered || toggle.containsMouse || panel.active ? Theme.fgAct : Theme.fg
            font.pixelSize: Theme.iconSize
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
        color: root.hovered || panel.active ? Theme.fgAct : Theme.fg
        elide: Text.ElideRight
        Layout.maximumWidth: 180
        // No room for a title beside a side bar's icon; the panel has it.
        visible: text.length > 0 && !root.vertical
    }
}
