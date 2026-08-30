import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../.."
import "../../ui"

RowLayout {
    id: root

    readonly property int count: 6

    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 2
    spacing: 0

    function workspaceAt(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i];
        }
        return null;
    }

    Repeater {
        model: root.count

        Rectangle {
            id: slot

            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: root.workspaceAt(wsId)
            readonly property bool occupied: ws !== null
            readonly property bool focused: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === wsId

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: label.implicitWidth + 26
            Layout.leftMargin: 3
            Layout.rightMargin: 3
            implicitHeight: Theme.barHeight - 8
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 2
                color: slot.focused
                    ? Theme.accentLine
                    : mouse.containsMouse ? Theme.border : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.animMs }
                }
            }

            ShellText {
                id: label
                anchors.centerIn: parent
                text: slot.focused ? Icons.workspaceDot : String(slot.wsId)
                color: slot.focused || slot.occupied || mouse.containsMouse
                    ? Theme.fgAct
                    : Theme.fg
                font.pixelSize: slot.focused ? 17 : Theme.fontSize
                font.weight: slot.occupied && !slot.focused ? Font.DemiBold : Font.Normal

                Behavior on font.pixelSize {
                    NumberAnimation { duration: Theme.animMs }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + slot.wsId)
            }
        }
    }
}
