import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../.."

RowLayout {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 4
    Layout.rightMargin: 10
    spacing: 8

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property var modelData

            Layout.alignment: Qt.AlignVCenter
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: event => {
                    const item = entry.modelData;
                    if (event.button === Qt.LeftButton) {
                        if (item.onlyMenu) menuAnchor.visible = true;
                        else item.activate();
                    } else if (event.button === Qt.RightButton) {
                        if (item.hasMenu) menuAnchor.visible = true;
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

            QsMenuAnchor {
                id: menuAnchor
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.edges: Edges.Bottom
            }
        }
    }
}
