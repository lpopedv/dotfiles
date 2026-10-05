import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

PopupWindow {
    id: root

    property var anchorItem: null

    anchor.item: root.anchorItem
    anchor.edges: BarService.popupEdge
    anchor.gravity: BarService.popupEdge
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 200
    // Gap off the bar is transparent space inside the popup: the compositor
    // clamps an anchored popup to the bar's edge, so anchor.margins can't do it.
    implicitHeight: layout.implicitHeight + 20 + Theme.popupInset
    color: "transparent"

    // Resets the fade-in for next open; can close via focus grab too, not just the button.
    onVisibleChanged: if (!root.visible) panel.opacity = 0;

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.topMargin: BarService.top ? Theme.popupInset : 0
        anchors.bottomMargin: BarService.top ? 0 : Theme.popupInset
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
                text: "Bar"
                color: Theme.fgAct
                font.weight: Font.DemiBold
            }

            ShellText {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.bottomMargin: 4
                text: "Position"
                color: Theme.subtle
                font.pixelSize: Theme.fontSize - 2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 6

                Repeater {
                    model: BarService.positions

                    Chip {
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.text
                        active: BarService.position === modelData.id
                        onClicked: BarService.setPosition(modelData.id)
                    }
                }
            }
        }
    }
}
