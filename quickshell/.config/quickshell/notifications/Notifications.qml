import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

// The toast stack. Everything about *what* is on screen lives in
// NotificationsService; this file only knows how a card arrives, counts down
// and leaves.
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

        // The Repeater counts as a child of the layout, so the popup list is
        // the only honest test for "is anything on screen".
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

                    // 0 is fully out of the way, 1 is settled in place. One
                    // driver for the fade, the slide and the height the stack
                    // reserves, so a card leaving collapses the gap above it
                    // rather than letting the rest jump.
                    property real reveal: 0
                    // 1 when the countdown starts, 0 when it runs out.
                    property real remaining: 1

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(card.implicitHeight * slot.reveal)
                    clip: true
                    opacity: slot.reveal

                    transform: Translate {
                        x: (1 - slot.reveal) * 26
                    }

                    // Both driven off `closing` rather than started by hand, so
                    // a card rebuilt part way through an exit picks the
                    // animation back up instead of freezing where it was.
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

                    // How much of the toast's life had already gone by the time
                    // this card was built. Zero in the normal case; only a
                    // rebuild of the stack makes it anything else.
                    readonly property int spent: Math.min(slot.modelData.timeout,
                        Date.now() - slot.modelData.popupAt)

                    // A timeout of 0 means the sender asked for no expiry, or
                    // the notification is critical - either way it stays until
                    // it is dealt with, exactly as GNOME and KDE do.
                    NumberAnimation {
                        id: countdown
                        target: slot
                        property: "remaining"
                        from: 1 - slot.spent / Math.max(1, slot.modelData.timeout)
                        to: 0
                        duration: Math.max(1, slot.modelData.timeout - slot.spent)
                        easing.type: Easing.Linear
                        running: slot.modelData.timeout > 0 && !slot.modelData.closing
                        // Reading `running` here keeps Qt from being asked to
                        // pause an animation that never started.
                        paused: countdown.running && card.hovered
                        onFinished: NotificationsService.hidePopup(slot.modelData)
                    }

                    Connections {
                        target: slot.modelData

                        // The sender replaced this notification, so the time it
                        // already spent on screen no longer applies. `from` and
                        // `duration` have re-read the new start by now; the
                        // animation just has to be told to pick them up.
                        function onGenerationChanged() {
                            if (countdown.running) countdown.restart();
                        }
                    }
                }
            }
        }
    }
}
