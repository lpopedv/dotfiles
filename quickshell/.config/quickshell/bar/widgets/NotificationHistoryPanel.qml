import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../notifications"
import "../../ui"

PopupWindow {
    id: root

    property var anchorItem: null

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 400
    // Gap under the bar is transparent space inside the popup: the compositor
    // clamps an anchored popup to the bar's edge, so anchor.margins can't do it.
    implicitHeight: layout.implicitHeight + 28 + Theme.popupInset
    color: "transparent"

    onVisibleChanged: {
        NotificationsService.historyOpen = root.visible;
        // Resets the fade-in for next open; can close via focus grab too, not just the button.
        if (!root.visible) panel.opacity = 0;
    }

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
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ShellText {
                    text: "Notifications"
                    color: Theme.fgAct
                    font.weight: Font.DemiBold
                }

                ShellText {
                    visible: NotificationsService.history.length > 0
                    text: NotificationsService.history.length
                    color: Theme.subtle
                }

                Item { Layout.fillWidth: true }

                Chip {
                    text: "Do not disturb"
                    quiet: true
                    active: NotificationsService.silent
                    onClicked: NotificationsService.toggleSilent()
                }

                Chip {
                    visible: NotificationsService.history.length > 0
                    text: "Clear all"
                    quiet: true
                    onClicked: NotificationsService.clearAll()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.divider
            }

            ShellText {
                Layout.fillWidth: true
                Layout.topMargin: 22
                Layout.bottomMargin: 22
                visible: NotificationsService.history.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: NotificationsService.silent
                    ? "Do not disturb is on"
                    : "No notifications"
                color: Theme.subtle
            }

            // Indicator must be a sibling of the list: as a Flickable child it'd scroll away too.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(520, list.contentHeight)
                visible: NotificationsService.history.length > 0

                ListView {
                    id: list

                    anchors.fill: parent
                    // Fixed gutter: sizing to actual overflow would loop (card height depends on wrap width).
                    anchors.rightMargin: 8
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    model: NotificationsService.history

                    delegate: NotificationCard {
                        required property var modelData

                        notif: modelData
                        compact: true
                        width: list.width
                    }
                }

                // Hand-drawn, not QtQuick.Controls ScrollBar: avoids pulling in a Controls style for one rectangle.
                Rectangle {
                    anchors.right: parent.right
                    width: 3
                    y: list.visibleArea.yPosition * list.height
                    height: Math.max(24, list.visibleArea.heightRatio * list.height)
                    visible: list.contentHeight > list.height
                    color: Theme.subtle
                    opacity: list.moving ? 1 : 0.5

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animMs }
                    }
                }
            }
        }
    }
}
