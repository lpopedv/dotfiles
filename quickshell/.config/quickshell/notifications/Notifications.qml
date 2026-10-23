pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Scope {
    id: root

    PanelWindow {
        anchors {
            bottom: true
            right: true
        }

        margins {
            bottom: 14
            right: 14
        }

        screen: ScreenService.focused
        implicitWidth: 400
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Normal

        // Repeater counts as a layout child, so check the list, not implicitHeight.
        visible: NotificationsService.popupList.length > 0

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: 8

            // Identity-keyed, so a toast arriving or leaving touches only its own card; a plain
            // array model would rebuild every card, restarting their animations and countdowns.
            Repeater {
                model: ScriptModel {
                    values: NotificationsService.popupList
                    comparisonMode: ObjectComparison.Identity
                }

                Item {
                    id: slot

                    required property var modelData

                    // 0 = out of the way, 1 = settled. Drives fade, slide, and the
                    // stack's reserved height together so a leaving card collapses cleanly.
                    property real reveal: 0
                    property real remaining: 1

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(card.implicitHeight * slot.reveal)
                    clip: true
                    opacity: slot.reveal

                    transform: Translate {
                        x: (1 - slot.reveal) * 26
                    }

                    // Driven off `closing`, not started by hand, so the two can never both run.
                    NumberAnimation on reveal {
                        to: 1
                        duration: Theme.animSlideMs
                        easing.type: Easing.OutCubic
                        running: !slot.modelData.closing
                    }

                    NumberAnimation {
                        target: slot
                        property: "reveal"
                        to: 0
                        duration: NotificationsService.leaveMs
                        easing.type: Easing.InCubic
                        running: slot.modelData.closing
                    }

                    NotificationCard {
                        id: card

                        notif: slot.modelData
                        progress: countdown.running || countdown.paused ? slot.remaining : -1

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                    }

                    // timeout of 0 = no expiry or critical: stays until dismissed.
                    NumberAnimation {
                        id: countdown
                        target: slot
                        property: "remaining"
                        from: 1
                        to: 0
                        duration: Math.max(1, slot.modelData.timeout)
                        easing.type: Easing.Linear
                        running: slot.modelData.timeout > 0 && !slot.modelData.closing
                        // Guards against pausing an animation that never started.
                        paused: countdown.running && card.hovered
                        onFinished: NotificationsService.hidePopup(slot.modelData)
                    }

                    Connections {
                        target: slot.modelData

                        // Sender replaced the notification: its time starts over.
                        function onGenerationChanged() {
                            if (countdown.running) countdown.restart();
                        }
                    }
                }
            }
        }
    }
}
