import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"


// The right-click menu for one tile. Same shape as the menu every dock puts
// there: the app's own windows first, then what can be done to the app.
PopupWindow {
    id: root

    property var tile: null
    property var anchorItem: null
    // Centre of the tile that opened this, in the anchor item's coordinates.
    property real centreX: 0

    readonly property var windows: root.tile ? root.tile.windows : []
    readonly property bool running: root.windows.length > 0

    anchor.item: root.anchorItem
    // A one-pixel rect on the plate's top edge: anchored and gravitied to Top,
    // the compositor centres the menu on it and grows it upward from there.
    anchor.rect.x: root.centreX
    anchor.rect.y: 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 250
    // The gap above the dock is transparent space inside the popup rather than
    // an anchor margin, for the same reason the notification panel does it:
    // the compositor clamps an anchored popup to the edge it is anchored to.
    implicitHeight: layout.implicitHeight + 20 + Theme.popupGap
    color: "transparent"

    function act(action) {
        root.visible = false;
        action();
    }

    onVisibleChanged: {
        // Reset so the fade plays again next time. The focus grab closes this
        // window as well as the tile does, so it cannot live in the caller.
        if (!root.visible) panel.opacity = 0;
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.bottomMargin: Theme.popupGap
        color: Theme.glass
        border.width: 1
        border.color: Theme.border

        opacity: 0

        NumberAnimation on opacity {
            to: 1
            duration: Theme.animMs
            easing.type: Easing.OutCubic
            running: root.visible
        }

        focus: true
        Keys.onEscapePressed: root.visible = false

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            ShellText {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.bottomMargin: 4
                text: root.tile ? root.tile.name : ""
                color: Theme.fgAct
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            // Only worth listing when there is a choice to make. With a single
            // window the tile itself already goes there.
            Repeater {
                model: root.windows.length > 1 ? root.windows.slice(0, 6) : []

                MenuRow {
                    required property var modelData
                    text: modelData.title || "Untitled window"
                    dim: true
                    onTriggered: root.act(() => DockService.focus(modelData))
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                visible: root.windows.length > 1
                implicitHeight: 1
                color: Theme.divider
            }

            MenuRow {
                visible: root.tile && root.tile.entry
                text: root.running ? "New window" : "Open"
                onTriggered: root.act(() => DockService.launch(root.tile))
            }

            MenuRow {
                text: root.tile && root.tile.pinned ? "Remove from dock" : "Keep in dock"
                onTriggered: root.act(() => DockService.togglePin(root.tile.key))
            }

            MenuRow {
                visible: root.running
                text: root.windows.length > 1
                    ? "Quit (" + root.windows.length + " windows)"
                    : "Quit"
                onTriggered: root.act(() => DockService.quit(root.tile))
            }
        }
    }
}
