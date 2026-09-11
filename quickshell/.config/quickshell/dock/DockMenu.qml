import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"
PopupWindow {
    id: root

    property var tile: null
    property var anchorItem: null
    property real centreX: 0

    readonly property var windows: root.tile ? root.tile.windows : []
    readonly property bool running: root.windows.length > 0

    anchor.item: root.anchorItem
    // 1px anchor rect: compositor centres the menu on it and grows upward.
    anchor.rect.x: root.centreX
    anchor.rect.y: 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 250
    // Gap above the dock is transparent space inside the popup: compositor
    // clamps an anchored popup to its anchor edge, so a margin can't do it.
    implicitHeight: layout.implicitHeight + 20 + Theme.popupGap
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
