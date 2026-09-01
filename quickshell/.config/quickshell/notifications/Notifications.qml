import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import ".."
import "../ui"

Scope {
    id: root

    PanelWindow {
        anchors {
            bottom: true
            right: true
        }

        margins {
            bottom: 16
            right: 16
        }

        implicitWidth: 380
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: stack.children.length > 0

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: 10

            Repeater {
                model: NotificationsService.popupList

                Rectangle {
                    id: card

                    required property var modelData
                    readonly property bool critical:
                        modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low:
                        modelData.urgency === NotificationUrgency.Low
                    readonly property int timeout: modelData.notification
                        ? NotificationsService.timeoutFor(modelData.notification) : 0
                    readonly property color accent:
                        card.critical ? Theme.red : card.low ? Theme.fg : Theme.fgAct
                    readonly property bool hovered: hoverArea.containsMouse

                    property real remaining: 1
                    property bool entered: false

                    Layout.fillWidth: true
                    implicitHeight: Math.min(220, contentColumn.implicitHeight + 28)

                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)
                    border.width: 1
                    border.color: card.critical
                        ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.40)
                        : Qt.rgba(1, 1, 1, 0.09)

                    opacity: card.entered ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    transform: Translate {
                        y: card.entered ? 0 : 14
                        Behavior on y {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                    }
                    Component.onCompleted: card.entered = true

                    NumberAnimation {
                        target: card
                        property: "remaining"
                        from: 1
                        to: 0
                        duration: card.timeout
                        easing.type: Easing.Linear
                        running: card.timeout > 0
                        paused: card.hovered
                        onFinished: NotificationsService.archive(card.modelData)
                    }

                    Rectangle {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: parent.height - 20
                        color: card.accent
                        opacity: 0.85
                    }

                    ColumnLayout {
                        id: contentColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 22
                        anchors.rightMargin: 16
                        anchors.topMargin: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                visible: icon.status === Image.Ready
                                implicitWidth: 36
                                implicitHeight: 36
                                color: Qt.rgba(1, 1, 1, 0.06)

                                IconImage {
                                    id: icon
                                    anchors.centerIn: parent
                                    source: NotificationsService.resolveIcon(card.modelData.image)
                                        || NotificationsService.resolveIcon(card.modelData.appIcon)
                                    implicitSize: 22
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                ShellText {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: card.modelData.summary
                                    color: card.low ? Theme.fg : Theme.fgAct
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideMiddle
                                }

                                ShellText {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: card.modelData.body
                                    color: card.low ? "#6b6b6b" : Theme.fg
                                    textFormat: Text.MarkdownText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 6
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            implicitHeight: 3
                            visible: card.timeout > 0

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(1, 1, 1, 0.08)
                            }

                            Rectangle {
                                width: parent.width * card.remaining
                                height: parent.height
                                color: card.accent
                                opacity: 0.85
                            }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: NotificationsService.dismiss(card.modelData)
                    }
                }
            }
        }
    }
}
