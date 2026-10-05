import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"
PopupWindow {
    id: root

    property var tile: null
    property var anchorItem: null
    // Tile centre along the dock's long axis, in anchorItem coordinates.
    property real centre: 0
    readonly property string side: DockService.position

    readonly property var windows: root.tile ? root.tile.windows : []
    readonly property bool running: root.windows.length > 0

    anchor.item: root.anchorItem
    // 1px anchor rect: compositor centres the menu on it and grows away from the screen edge.
    readonly property int away: root.side === "left" ? Edges.Right
        : root.side === "right" ? Edges.Left
        : Edges.Top
    anchor.rect.x: root.side === "left" ? (root.anchorItem ? root.anchorItem.width - 1 : 0)
        : root.side === "right" ? 0
        : root.centre
    anchor.rect.y: DockService.vertical ? root.centre : 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: root.away
    anchor.gravity: root.away
    anchor.adjustment: DockService.vertical ? PopupAdjustment.SlideY : PopupAdjustment.SlideX

    // Gap off the dock is transparent space inside the popup: compositor
    // clamps an anchored popup to its anchor edge, so a margin can't do it.
    implicitWidth: 250 + (DockService.vertical ? Theme.popupGap : 0)
    implicitHeight: layout.implicitHeight + 20 + (DockService.vertical ? 0 : Theme.popupGap)
    color: "transparent"

    function act(action) {
        root.visible = false;
        action();
    }

    onVisibleChanged: {
        if (!root.visible) panel.opacity = 0;
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.bottomMargin: root.side === "bottom" ? Theme.popupGap : 0
        anchors.leftMargin: root.side === "left" ? Theme.popupGap : 0
        anchors.rightMargin: root.side === "right" ? Theme.popupGap : 0
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
