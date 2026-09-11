import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".."
import "../ui"

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

    width: DockService.iconSize + Theme.dockIconGap
    height: parent.height

    IconImage {
        id: glyph

        anchors.centerIn: parent
        implicitSize: DockService.iconSize
        source: root.tile.icon
        visible: status === Image.Ready

        opacity: root.running || root.hovered ? 1 : 0.62

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMs }
        }

        transform: Translate { y: -bounce.value }
    }

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
            else if (event.button === Qt.MiddleButton) DockService.launch(root.tile);
            else DockService.activate(root.tile);
        }

        onWheel: event => DockService.cycle(root.tile, event.angleDelta.y > 0 ? -1 : 1)
    }
}
