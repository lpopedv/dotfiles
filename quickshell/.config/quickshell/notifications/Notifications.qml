import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import ".."
import "../ui"

Scope {
    id: root

    readonly property int maxVisible: 5

    // `image` arrives pre-wrapped as image://icon/<name> and `appIcon` as a bare
    // name, and neither is checked against the theme. Handing either to Image
    // unvalidated draws Qt's magenta placeholder, because the provider returns
    // that placeholder successfully rather than failing. iconPath's check
    // overload is the only thing that reports a missing icon, so every form is
    // unwrapped down to a name and run through it.
    readonly property string iconUrlPrefix: "image://icon/"

    function resolveIcon(name) {
        if (!name) return "";
        if (name.startsWith(iconUrlPrefix))
            return Quickshell.iconPath(name.substring(iconUrlPrefix.length), true);
        if (name.startsWith("/") || name.startsWith("file:"))
            return name;
        return Quickshell.iconPath(name, true);
    }

    function timeoutFor(notification) {
        if (notification.urgency === NotificationUrgency.Critical) return 0;
        if (notification.expireTimeout > 0) return notification.expireTimeout * 1000;
        return notification.urgency === NotificationUrgency.Low ? 4000 : 5000;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }

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
                model: server.trackedNotifications

                Rectangle {
                    id: card

                    required property var modelData
                    readonly property bool critical:
                        modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low:
                        modelData.urgency === NotificationUrgency.Low
                    readonly property int timeout: root.timeoutFor(modelData)
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
                        onFinished: card.modelData.expire()
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
                                    source: root.resolveIcon(card.modelData.image)
                                        || root.resolveIcon(card.modelData.appIcon)
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
                        onClicked: card.modelData.expire()
                    }
                }
            }
        }
    }
}
