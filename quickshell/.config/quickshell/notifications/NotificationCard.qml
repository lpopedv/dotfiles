import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import Quickshell.Widgets
import ".."
import "../ui"

// One card, used both as a toast and as a row in the history panel, so the two
// cannot drift apart. The layout is the one GNOME and KDE share: app identity
// and age on a dim header line, then the summary, then the body, then the
// sender's action buttons.
Rectangle {
    id: root

    required property var notif
    // History rows are denser: smaller icon, fewer body lines, no ground of
    // their own since the panel already provides one.
    property bool compact: false
    // 1 while a toast has its full time left, 0 as it times out. Negative
    // hides the bar, which is what critical and never-expiring toasts get.
    property real progress: -1

    readonly property bool critical: root.notif.urgency === NotificationUrgency.Critical
    readonly property bool low: root.notif.urgency === NotificationUrgency.Low
    readonly property color accent: root.critical ? Theme.red : root.low ? Theme.fg : Theme.fgAct
    readonly property bool hovered: hover.hovered

    readonly property string image: NotificationsService.resolveIcon(root.notif.image)
    readonly property string appIcon: NotificationsService.appIconFor(root.notif)
    readonly property var actions: NotificationsService.buttonActions(root.notif)

    readonly property int inset: root.compact ? 12 : 15
    readonly property int iconSize: root.compact ? 26 : 38

    implicitHeight: body.implicitHeight + root.inset * 2

    color: root.compact
        ? (root.hovered ? Theme.hoverFill : "transparent")
        : Theme.overlay
    border.width: 1
    border.color: root.critical
        ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.40)
        : Theme.divider

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }

    // Declared first so it sits *under* everything else: the action buttons
    // and the close button are later siblings and therefore get the click
    // first, which is the only thing keeping a button press from also firing
    // the card's default action.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: NotificationsService.defaultAction(root.notif)
            ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: event => {
            // Middle click closes without acting on it, the way it does
            // everywhere else; left click runs the sender's default action.
            if (event.button === Qt.MiddleButton) {
                if (root.compact) NotificationsService.remove(root.notif);
                else NotificationsService.hidePopup(root.notif);
            } else {
                NotificationsService.activate(root.notif);
            }
        }
    }

    // Urgency stripe. Deliberately flush with the border rather than inset:
    // it reads as an edge marker, not as another element in the layout.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: 3
        color: root.accent
        opacity: root.critical ? 0.9 : 0.55
    }

    RowLayout {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.inset + 8
        anchors.rightMargin: root.inset
        spacing: root.compact ? 10 : 13

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize
            color: Qt.rgba(1, 1, 1, 0.06)

            IconImage {
                id: icon
                anchors.centerIn: parent
                visible: status === Image.Ready
                source: root.image !== "" ? root.image : root.appIcon
                implicitSize: root.iconSize - (root.compact ? 8 : 12)
            }

            // Senders with no usable icon still get a tile, so every card in a
            // stack lines up on the same left edge.
            ShellText {
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: Icons.bell
                color: Theme.subtle
                font.pixelSize: root.compact ? 12 : 16
            }

            // When the sender supplied both a picture and an app icon, the
            // picture is the subject and the icon says who sent it.
            Rectangle {
                visible: !root.compact && root.appIcon !== ""
                    && root.image !== "" && icon.status === Image.Ready
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -3
                implicitWidth: 16
                implicitHeight: 16
                color: Theme.bg
                border.width: 1
                border.color: Theme.divider

                IconImage {
                    anchors.centerIn: parent
                    source: root.appIcon
                    implicitSize: 11
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.compact ? 3 : 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ShellText {
                    Layout.fillWidth: true
                    text: root.notif.appName || "Notification"
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }

                ShellText {
                    text: NotificationsService.elapsed(root.notif.time)
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 2
                }

                // Same affordance as GNOME and KDE: appears on hover, and only
                // takes the toast away - the entry stays in history.
                ShellText {
                    text: "×"
                    color: closeArea.containsMouse ? Theme.fgAct : Theme.subtle
                    font.pixelSize: Theme.fontSize + 2
                    opacity: root.hovered ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animMs }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        enabled: root.hovered
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.compact) NotificationsService.remove(root.notif);
                            else NotificationsService.hidePopup(root.notif);
                        }
                    }
                }
            }

            ShellText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif.summary
                color: root.low ? Theme.fg : Theme.fgAct
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            ShellText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif.body
                color: root.low ? Theme.subtle : Theme.fg
                // The spec's body markup is the <b>/<i>/<u>/<a> subset, which
                // is what StyledText renders - not Markdown, which would eat
                // the asterisks and underscores in ordinary prose.
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.compact ? 3 : 5
                elide: Text.ElideRight
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.actions.length > 0
                spacing: 6

                Repeater {
                    model: root.actions

                    Chip {
                        required property var modelData
                        text: modelData.text
                        onClicked: NotificationsService.invoke(root.notif, modelData)
                    }
                }
            }
        }
    }

    // Time remaining, flush along the bottom edge. Hidden for critical toasts,
    // which have no countdown to show in the first place.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 1
        visible: root.progress >= 0
        height: 2
        color: Theme.divider

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            color: root.accent
            opacity: 0.8
        }
    }

    // A handler rather than another MouseArea: hovering an action button must
    // still count as hovering the card, or the close button would blink out
    // from under the pointer on its way there.
    HoverHandler {
        id: hover
    }
}
