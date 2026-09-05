import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".."
import "../ui"

// One tile: an app, the windows it has open, and what a click on it means.
// Where it sits is handed down by Dock, which owns the row's layout.
//
// Nothing here resizes. The tile is a fixed slot and the icon is drawn at one
// size for the whole life of the dock - the hover feedback is the highlight
// sliding underneath, which belongs to the row rather than to any one tile.
Item {
    id: root

    required property var tile

    readonly property bool running: root.tile.windows.length > 0
    readonly property bool hovered: mouse.containsMouse

    readonly property bool focused: {
        const active = ToplevelManager.activeToplevel;
        if (!active || !active.activated) return false;
        return root.tile.windows.indexOf(active) >= 0;
    }

    signal menuRequested

    // A whole slot wide, so the row has no dead gaps between tiles for the
    // pointer to fall through. The icon is centred in it.
    width: DockService.iconSize + Theme.dockIconGap
    height: parent.height

    IconImage {
        id: glyph

        anchors.centerIn: parent
        implicitSize: DockService.iconSize
        source: root.tile.icon
        visible: status === Image.Ready

        // A pinned app that is not running sits back a little, so the dock
        // says what is open without needing the dots to be read.
        opacity: root.running || root.hovered ? 1 : 0.62

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMs }
        }

        // The hop when an app is asked to start. This is a launch answering
        // the click, not hover feedback - it is the one thing on the dock that
        // moves without the pointer having caused it.
        transform: Translate { y: -bounce.value }
    }

    // Apps with no usable icon still get a tile rather than a hole in the row.
    ShellText {
        anchors.centerIn: parent
        visible: !glyph.visible
        text: (root.tile.name || root.tile.key).charAt(0).toUpperCase()
        color: root.focused ? Theme.fgAct : Theme.fg
        font.pixelSize: Math.round(DockService.iconSize * 0.42)
        font.weight: Font.DemiBold
    }

    QtObject {
        id: bounce
        property real value: 0
    }

    // Runs until the app's first window shows up, so a slow starter keeps
    // saying it heard the click instead of going quiet after one hop.
    SequentialAnimation {
        id: bounceLoop

        running: DockService.launching === root.tile.key
        loops: Animation.Infinite
        onStopped: bounce.value = 0

        NumberAnimation {
            target: bounce; property: "value"
            to: DockService.iconSize * 0.30
            duration: 260
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: bounce; property: "value"
            to: 0
            duration: 340
            easing.type: Easing.OutBounce
        }
        PauseAnimation { duration: 280 }
    }

    // One mark per window, up to three. A single dot would say "running" and
    // stop there, and the count is the thing worth knowing before clicking: it
    // is the difference between a click that focuses and one that cycles.
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 5
        spacing: 3

        Repeater {
            model: Math.min(3, root.tile.windows.length)

            Rectangle {
                implicitWidth: Theme.dockDot
                implicitHeight: Theme.dockDot
                color: root.focused ? Theme.fgAct : Theme.subtle
                opacity: root.focused ? 1 : 0.75

                Behavior on color {
                    ColorAnimation { duration: Theme.animMs }
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton) root.menuRequested();
            // Middle click opening a second window is the convention every
            // taskbar and dock shares.
            else if (event.button === Qt.MiddleButton) DockService.launch(root.tile);
            else DockService.activate(root.tile);
        }

        onWheel: event => DockService.cycle(root.tile, event.angleDelta.y > 0 ? -1 : 1)
    }
}
