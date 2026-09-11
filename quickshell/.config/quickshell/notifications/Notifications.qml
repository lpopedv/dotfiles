import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

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

        implicitWidth: 400
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // Repeater counts as a layout child, so check the list, not implicitHeight.
        visible: NotificationsService.popupList.length > 0

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: 8

            Repeater {
                model: NotificationsService.popupList

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

                    // Driven off `closing`, not started by hand, so a rebuilt card resumes mid-exit.
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

                    // Nonzero only when a stack rebuild reconstructs an already-aging toast.
                    readonly property int spent: Math.min(slot.modelData.timeout,
                        Date.now() - slot.modelData.popupAt)

                    // timeout of 0 = no expiry or critical: stays until dismissed.
                    NumberAnimation {
                        id: countdown
                        target: slot
                        property: "remaining"
                        from: 1 - slot.spent / Math.max(1, slot.modelData.timeout)
                        to: 0
                        duration: Math.max(1, slot.modelData.timeout - slot.spent)
                        easing.type: Easing.Linear
                        running: slot.modelData.timeout > 0 && !slot.modelData.closing
                        // Guards against pausing an animation that never started.
                        paused: countdown.running && card.hovered
                        onFinished: NotificationsService.hidePopup(slot.modelData)
                    }

                    Connections {
                        target: slot.modelData

                        // Sender replaced the notification; from/duration already re-read, just needs a restart.
                        function onGenerationChanged() {
                            if (countdown.running) countdown.restart();
                        }
                    }
                }
            }
        }
    }
}
