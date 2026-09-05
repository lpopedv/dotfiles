import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

// One level of a system tray item's context menu: the top-level popup below
// the tray icon (Steam, Mullvad, ...) or a submenu hanging off one of its
// rows. QsMenuAnchor renders nothing by itself - it is just a positioner -
// so the actual rows are built here from the item's live DBus menu via
// QsMenuOpener and styled the way every other popup on this bar is
// (Theme.glass panel, MenuRow rows), rather than left to look like a bare
// native menu.
PopupWindow {
    id: root

    property var menu: null
    property var anchorItem: null
    // A submenu grows to the right of the row that opened it instead of
    // hanging below the tray icon.
    property bool nested: false

    // Emitted once, by whichever level is deepest when a leaf entry is
    // chosen. Each ancestor level forwards it upward (see the Connections
    // below) so the whole chain closes together instead of leaving stale
    // submenus open behind the tray icon.
    signal dismissed()

    function closeSelf() {
        root.dismissed();
        root.visible = false;
    }

    anchor.item: root.anchorItem
    anchor.edges: root.nested ? Edges.Right : Edges.Bottom
    anchor.gravity: root.nested ? Edges.Right : Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    implicitWidth: 220
    // The gap under the bar is transparent space inside the popup rather
    // than an anchor offset, same reasoning as every other bar popup: the
    // compositor clamps an anchored popup to the bar's own edge.
    implicitHeight: layout.implicitHeight + 20 + (root.nested ? 0 : Theme.popupInset)
    color: "transparent"

    // Which row (if any) currently has its submenu open.
    property var openRow: null

    onVisibleChanged: {
        if (!root.visible) {
            panel.opacity = 0;
            root.openRow = null;
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.menu
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.topMargin: root.nested ? 0 : Theme.popupInset
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

            Repeater {
                model: opener.children

                Item {
                    id: entry
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: entry.modelData.isSeparator ? 9 : row.implicitHeight

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1
                        color: Theme.divider
                    }

                    MenuRow {
                        id: row

                        visible: !entry.modelData.isSeparator
                        anchors.left: parent.left
                        anchors.right: parent.right
                        enabled: entry.modelData.enabled
                        text: entry.modelData.text
                        gutter: entry.modelData.buttonType !== QsMenuButtonType.None
                        mark: entry.modelData.buttonType === QsMenuButtonType.CheckBox
                            ? (entry.modelData.checkState === Qt.Checked ? Icons.check : "")
                            : entry.modelData.buttonType === QsMenuButtonType.RadioButton
                                ? (entry.modelData.checkState === Qt.Checked ? Icons.radioOn : Icons.radioOff)
                                : ""
                        trailing: entry.modelData.hasChildren ? Icons.chevronRight : ""

                        HoverHandler {
                            enabled: entry.modelData.hasChildren
                            onHoveredChanged: if (hovered) root.openRow = entry
                        }

                        onTriggered: {
                            if (entry.modelData.hasChildren) {
                                root.openRow = entry;
                            } else {
                                entry.modelData.triggered();
                                root.closeSelf();
                            }
                        }
                    }

                    // A plain nested `TrayMenu {}` here would make the type
                    // instantiate itself recursively, which quickshell
                    // refuses at load time even wrapped in a LazyLoader's
                    // inline delegate (still the same static type graph).
                    // Loading this same file by URL instead compiles it as
                    // its own unit, resolved only once a submenu actually
                    // opens, which breaks the cycle.
                    Loader {
                        id: submenuLoader
                        active: entry.modelData.hasChildren && root.openRow === entry
                        source: active ? Qt.resolvedUrl("TrayMenu.qml") : ""

                        onLoaded: {
                            item.anchorItem = row;
                            item.nested = true;
                            item.menu = entry.modelData;
                            item.grabFocus = true;
                            item.visible = true;
                        }
                    }

                    Connections {
                        target: submenuLoader.item
                        function onDismissed() { root.closeSelf(); }
                    }
                }
            }
        }
    }
}
