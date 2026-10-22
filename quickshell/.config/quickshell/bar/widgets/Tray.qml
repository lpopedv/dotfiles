import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.services

GridLayout {
    id: root

    readonly property bool vertical: BarService.vertical

    Layout.alignment: BarService.crossAlign
    // Matches the glyph-to-glyph rhythm of the BarItems beside it: along a top/bottom
    // bar each one has 11px padding plus a 2px margin per side, so 13 + 13 between
    // glyphs; along a side bar the items are squarer, so the gap is tighter.
    Layout.leftMargin: root.vertical ? 0 : 4
    Layout.rightMargin: root.vertical ? 0 : 13
    Layout.topMargin: root.vertical ? 4 : 0
    Layout.bottomMargin: root.vertical ? 13 : 0

    flow: root.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
    columns: root.vertical ? 1 : -1
    rows: root.vertical ? -1 : 1
    columnSpacing: 26
    rowSpacing: 22

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property var modelData

            Layout.alignment: BarService.crossAlign
            implicitWidth: 16
            implicitHeight: 16

            Image {
                anchors.fill: parent
                source: entry.modelData.icon
                    ? (entry.modelData.icon.startsWith("/") || entry.modelData.icon.startsWith("image://")
                        ? entry.modelData.icon
                        : Quickshell.iconPath(entry.modelData.icon, true))
                    : ""
                sourceSize.width: 32
                sourceSize.height: 32
                smooth: true
                mipmap: true
                opacity: mouse.containsMouse ? 1.0 : 0.85

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animMs }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: event => {
                    const item = entry.modelData;
                    if (event.button === Qt.LeftButton) {
                        if (item.onlyMenu) menu.visible = true;
                        else item.activate();
                    } else if (event.button === Qt.RightButton) {
                        if (item.hasMenu) menu.visible = true;
                    } else {
                        item.secondaryActivate();
                    }
                }

                onWheel: event => {
                    const item = entry.modelData;
                    item.scroll(event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x,
                                event.angleDelta.y === 0);
                }
            }

            TrayMenu {
                id: menu
                menu: entry.modelData.menu
                anchorItem: entry
                visible: false
                grabFocus: true
            }
        }
    }
}
