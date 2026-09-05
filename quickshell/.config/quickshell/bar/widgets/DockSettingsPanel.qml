import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

// The dock's settings, hung off the bar button. Everything here is state the
// user owns, so every row writes straight through to DockService and is on
// disk before the panel closes.
PopupWindow {
    id: root

    property var anchorItem: null

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 250
    // The gap under the bar is transparent space inside the popup rather than
    // an anchor offset: the compositor clamps an anchored popup to the bar's
    // own edge, so anchor.margins has nothing to give here.
    implicitHeight: layout.implicitHeight + 20 + Theme.popupInset
    color: "transparent"

    // Reset so the fade below plays again on the next open. The window is
    // hidden by the focus grab as well as by the bar button, so this cannot
    // live in whatever opened it.
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

            // The three reveal modes exclude each other, so they get circles
            // rather than ticks and the panel stays open as they are tried -
            // picking between them is a comparison, not a single decision.
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
                // Only means anything while the dock hides in the first place.
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

            // Wide enough targets to pick from without reading, and the dock
            // resizes under the panel as they are pressed.
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
