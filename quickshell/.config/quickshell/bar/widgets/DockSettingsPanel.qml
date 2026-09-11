import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

PopupWindow {
    id: root

    property var anchorItem: null

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 250
    // Gap under the bar is transparent space inside the popup: the compositor
    // clamps an anchored popup to the bar's edge, so anchor.margins can't do it.
    implicitHeight: layout.implicitHeight + 20 + Theme.popupInset
    color: "transparent"

    // Resets the fade-in for next open; can close via focus grab too, not just the button.
    onVisibleChanged: if (!root.visible) panel.opacity = 0;

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.topMargin: Theme.popupInset
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
                text: "Dock"
                color: Theme.fgAct
                font.weight: Font.DemiBold
            }

            // Radio circles, not ticks: the three modes are mutually exclusive.
            Repeater {
                model: DockService.modes

                MenuRow {
                    required property var modelData

                    text: modelData.text
                    gutter: true
                    mark: DockService.mode === modelData.id
                        ? Icons.radioOn : Icons.radioOff
                    onTriggered: DockService.setMode(modelData.id)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                implicitHeight: 1
                color: Theme.divider
            }

            MenuRow {
                enabled: DockService.mode === "auto"
                opacity: enabled ? 1 : Theme.dimmedOpacity
                text: "Show on empty workspace"
                gutter: true
                mark: DockService.showOnDesktop ? Icons.check : ""
                onTriggered: DockService.toggleShowOnDesktop()
            }

            MenuRow {
                text: "Only running apps"
                gutter: true
                mark: DockService.runningOnly ? Icons.check : ""
                onTriggered: DockService.toggleRunningOnly()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                implicitHeight: 1
                color: Theme.divider
            }

            ShellText {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.bottomMargin: 4
                text: "Icon size"
                color: Theme.subtle
                font.pixelSize: Theme.fontSize - 2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 6

                Repeater {
                    model: DockService.sizes

                    Chip {
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.text
                        active: DockService.iconSize === modelData.size
                        onClicked: DockService.setIconSize(modelData.size)
                    }
                }
            }
        }
    }
}
