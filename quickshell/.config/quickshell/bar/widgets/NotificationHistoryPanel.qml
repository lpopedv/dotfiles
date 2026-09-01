import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../.."
import "../../ui"

PopupWindow {
    id: root

    property var anchorItem: null
    property date now: new Date()

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 380
    implicitHeight: layout.implicitHeight + 28
    color: "transparent"

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    function elapsed(ms) {
        let secs = Math.floor((root.now - ms) / 1000);
        if (secs < 5) return "now";
        if (secs < 60) return secs + "s";
        const mins = Math.floor(secs / 60);
        if (mins < 60) return mins + "m";
        const hours = Math.floor(mins / 60);
        if (hours < 24) return hours + "h";
        return Math.floor(hours / 24) + "d";
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
        border.width: 1
        border.color: Theme.border

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

                Item { Layout.fillWidth: true }

                ShellText {
                    visible: NotificationsService.history.length > 0
                    text: "Clear all"
                    color: clearArea.containsMouse ? Theme.fgAct : Theme.border

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationsService.clearAll()
                    }
                }
            }

            ShellText {
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.bottomMargin: 20
                visible: NotificationsService.history.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: Theme.border
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(420, contentHeight)
                visible: NotificationsService.history.length > 0
                clip: true
                spacing: 8
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                model: NotificationsService.history

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    readonly property bool critical:
                        modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low:
                        modelData.urgency === NotificationUrgency.Low
                    readonly property color accent:
                        row.critical ? Theme.red : row.low ? Theme.fg : Theme.fgAct

                    width: list.width
                    implicitHeight: rowContent.implicitHeight + 16
                    color: rowHover.containsMouse ? Theme.hoverFill : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: parent.height - 14
                        color: row.accent
                        opacity: 0.85
                    }

                    ColumnLayout {
                        id: rowContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 20
                        anchors.rightMargin: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                visible: icon.status === Image.Ready
                                implicitWidth: 24
                                implicitHeight: 24
                                color: Qt.rgba(1, 1, 1, 0.06)

                                IconImage {
                                    id: icon
                                    anchors.centerIn: parent
                                    source: NotificationsService.resolveIcon(row.modelData.image)
                                        || NotificationsService.resolveIcon(row.modelData.appIcon)
                                    implicitSize: 16
                                }
                            }

                            ShellText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.summary
                                color: row.low ? Theme.fg : Theme.fgAct
                                font.weight: Font.DemiBold
                                elide: Text.ElideMiddle
                            }

                            ShellText {
                                text: root.elapsed(row.modelData.time)
                                color: Theme.border
                            }

                            ShellText {
                                text: "×"
                                color: dismissArea.containsMouse ? Theme.fgAct : Theme.border

                                MouseArea {
                                    id: dismissArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationsService.dismiss(row.modelData)
                                }
                            }
                        }

                        ShellText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: row.modelData.body
                            color: row.low ? "#6b6b6b" : Theme.fg
                            textFormat: Text.MarkdownText
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: row.modelData.actions.length > 0

                            Repeater {
                                model: row.modelData.actions

                                Rectangle {
                                    id: actionChip
                                    required property var modelData

                                    implicitWidth: actionLabel.implicitWidth + 16
                                    implicitHeight: actionLabel.implicitHeight + 8
                                    color: actionArea.containsMouse ? Theme.hoverFill : Theme.activeFill
                                    border.width: 1
                                    border.color: Theme.accentLine

                                    ShellText {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: actionChip.modelData.text
                                    }

                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            actionChip.modelData.invoke();
                                            NotificationsService.dismiss(row.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }
}
