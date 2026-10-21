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
    anchor.adjustment: BarService.popupAdjustment

    implicitWidth: 200 + BarService.insetX
    // Gap off the bar is transparent space inside the popup: the compositor
    // clamps an anchored popup to the bar's edge, so anchor.margins can't do it.
    implicitHeight: layout.implicitHeight + 20 + BarService.insetY
    color: "transparent"

    // Resets the fade-in for next open; can close via focus grab too, not just the button.
    onVisibleChanged: if (!root.visible) panel.opacity = 0;

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.topMargin: BarService.insetTop
        anchors.bottomMargin: BarService.insetBottom
        anchors.leftMargin: BarService.insetLeft
        anchors.rightMargin: BarService.insetRight
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

            // Two by two: four chips side by side wouldn't fit the panel.
            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                columns: 2
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: BarService.positions

                    Chip {
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.text
                        active: BarService.position === modelData.id
                        onClicked: {
                            BarService.setPosition(modelData.id);
                            // The bar is about to move out from under this popup.
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }
}
