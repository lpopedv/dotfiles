pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.notifications
import qs.services
import qs.ui

BarPopup {
    id: root

    panelWidth: 400
    contentHeight: layout.implicitHeight
    padding: 14

    // Keeps the shared age ticker running while the list is on screen.
    onVisibleChanged: NotificationsService.historyOpen = root.visible
    Component.onDestruction: NotificationsService.historyOpen = false

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ShellText {
                text: "Notifications"
                color: Theme.fgAct
                font.weight: Theme.weightMedium
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
                model: ScriptModel {
                    values: Array.from(NotificationsService.history)
                    comparisonMode: ObjectComparison.Identity
                }

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
