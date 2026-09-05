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
    // The gap under the bar is transparent space inside the popup rather than
    // an anchor offset: the compositor clamps an anchored popup to the bar's
    // own edge, so anchor.margins has nothing to give here.
    implicitHeight: layout.implicitHeight + 28 + Theme.popupInset
    color: "transparent"

    onVisibleChanged: {
        // Lets the service park its clock while nothing shows a relative time.
        NotificationsService.historyOpen = root.visible;
        // Reset so the fade below plays again on the next open. The window is
        // hidden by the focus grab as well as by the bar button, so this
        // cannot live in whatever opened it.
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

                // Both GNOME and KDE keep the Do Not Disturb switch in the
                // notification list itself rather than out in the bar, where it
                // is a mystery icon you have to remember the meaning of.
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

            // The indicator below has to be a sibling of the list, not a child:
            // a Flickable puts declared children inside its content item, where
            // it would scroll away with the notifications.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(520, list.contentHeight)
                visible: NotificationsService.history.length > 0

                ListView {
                    id: list

                    anchors.fill: parent
                    // A fixed gutter for the indicator. Sizing it to whether
                    // the list actually overflows would loop, since a card's
                    // height depends on the width it wraps its body at.
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

                // Hand-drawn rather than a QtQuick.Controls ScrollBar: the rest
                // of the shell draws its own chrome, and this avoids pulling a
                // Controls style into the config for one 2px rectangle.
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
