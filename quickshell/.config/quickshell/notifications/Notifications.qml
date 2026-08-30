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
            top: true
            right: true
        }

        margins {
            top: 16
            right: 16
        }

        implicitWidth: 370
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: stack.children.length > 0

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: 8

            Repeater {
                model: server.trackedNotifications

                Rectangle {
                    id: card

                    required property var modelData
                    readonly property bool critical:
                        modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low:
                        modelData.urgency === NotificationUrgency.Low

                    Layout.fillWidth: true
                    implicitHeight: Math.min(200, body.implicitHeight + 24)

                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.78)
                    border.width: 1
                    border.color: card.critical
                        ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.45)
                        : card.low ? Qt.rgba(1, 1, 1, 0.06)
                        : Qt.rgba(1, 1, 1, 0.10)

                    opacity: 0
                    Component.onCompleted: opacity = 1
                    Behavior on opacity {
                        NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
                    }

                    Timer {
                        interval: root.timeoutFor(card.modelData)
                        running: interval > 0
                        onTriggered: card.modelData.expire()
                    }

                    RowLayout {
                        id: body
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        IconImage {
                            visible: source !== ""
                            source: root.resolveIcon(card.modelData.image)
                                || root.resolveIcon(card.modelData.appIcon)
                            implicitSize: 32
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

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

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: card.modelData.expire()
                    }
                }
            }
        }
    }
}
