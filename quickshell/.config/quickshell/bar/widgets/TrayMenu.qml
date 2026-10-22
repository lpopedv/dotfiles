pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.ui

PopupWindow {
    id: root

    property var menu: null
    property var anchorItem: null
    property bool nested: false

    // Forwarded upward by each ancestor (see Connections below) so the whole chain closes together.
    signal dismissed()

    function closeSelf() {
        root.dismissed();
        root.visible = false;
    }

    anchor.item: root.anchorItem
    // Submenus open to the right of their parent, except off a right bar, where that would run off-screen.
    readonly property int nestedEdge: BarService.right ? Edges.Left : Edges.Right

    anchor.edges: root.nested ? root.nestedEdge : BarService.popupEdge
    anchor.gravity: root.nested ? root.nestedEdge : BarService.popupEdge
    anchor.adjustment: PopupAdjustment.Slide

    implicitWidth: 220 + (root.nested ? 0 : BarService.insetX)
    implicitHeight: layout.implicitHeight + 20 + (root.nested ? 0 : BarService.insetY)
    color: "transparent"

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
        anchors.topMargin: root.nested ? 0 : BarService.insetTop
        anchors.bottomMargin: root.nested ? 0 : BarService.insetBottom
        anchors.leftMargin: root.nested ? 0 : BarService.insetLeft
        anchors.rightMargin: root.nested ? 0 : BarService.insetRight
        color: Theme.glass
        border.width: 1
        border.color: Theme.border

        opacity: 0

        NumberAnimation on opacity {
            to: 1
            duration: Theme.animSlideMs
            easing.type: Easing.OutCubic
            running: root.visible
        }

        // Eases out of the bar as it fades in; submenus just fade.
        transform: Translate {
            readonly property real away: Theme.popupSlide * (1 - panel.opacity)
            x: root.nested ? 0 : BarService.left ? -away : BarService.right ? away : 0
            y: root.nested ? 0 : BarService.top ? -away : BarService.bottom ? away : 0
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

                    // Loaded by URL, not `TrayMenu {}`: quickshell refuses direct recursive instantiation.
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
