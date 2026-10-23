pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs
import qs.services
import qs.ui

GridLayout {
    id: root

    readonly property bool vertical: BarService.vertical

    // Collapsed, only the focused workspace's number is left; the rest fan out on reveal.
    property bool revealed: true
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // Height with every slot out; Bar.roomToReveal only asks on a side bar, where a
    // slot is a line of text plus its padding (14) and margins (6).
    readonly property real fullExtent: root.count * (Math.ceil(metrics.height) + 14 + 6)

    FontMetrics {
        id: metrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    // Keybinds go up to 10; grows past 6 so a window on ws 8 stays reachable.
    readonly property int minimum: 6
    readonly property int maximum: 10

    readonly property int count: {
        let highest = root.minimum;
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > highest) highest = ws.id;
        return Math.min(root.maximum, highest);
    }

    Layout.alignment: BarService.crossAlign
    Layout.leftMargin: root.vertical ? 0 : 2
    Layout.topMargin: root.vertical ? 2 : 0
    flow: root.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
    columns: root.vertical ? 1 : -1
    rows: root.vertical ? -1 : 1
    columnSpacing: 0
    rowSpacing: 0

    function workspaceAt(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i];
        }
        return null;
    }

    Repeater {
        model: root.count

        Rectangle {
            id: slot

            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: root.workspaceAt(wsId)
            readonly property bool occupied: ws !== null
            readonly property bool focused: root.focusedId === wsId

            // 0 = collapsed away, 1 = settled; width, margins and fade all follow it.
            // The focused slot never leaves, so switching workspace slides one out as one comes in.
            property real shown: focused || root.revealed ? 1 : 0
            // Slots fan out from the focused one rather than all at once.
            readonly property int ripple: Math.abs(wsId - root.focusedId)

            Behavior on shown {
                id: shownBehavior

                // See BarItem: the target, not state derived from `revealed`, which is stale here.
                readonly property bool opening: shownBehavior.targetValue > 0.5

                SequentialAnimation {
                    PauseAnimation {
                        duration: shownBehavior.opening ? slot.ripple * Theme.revealStaggerMs : 0
                    }
                    NumberAnimation {
                        duration: shownBehavior.opening ? Theme.revealMs : Theme.collapseMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: shownBehavior.opening ? Theme.revealCurve : Theme.collapseCurve
                    }
                }
            }

            Layout.alignment: BarService.crossAlign
            Layout.leftMargin: root.vertical ? 0 : 3 * slot.shown
            Layout.rightMargin: root.vertical ? 0 : 3 * slot.shown
            Layout.topMargin: root.vertical ? 3 * slot.shown : 0
            Layout.bottomMargin: root.vertical ? 3 * slot.shown : 0
            // Slots span the bar's thickness less a small inset; along it they hug the number.
            implicitWidth: root.vertical ? BarService.thickness - 8 : (label.implicitWidth + 26) * slot.shown
            implicitHeight: root.vertical ? (label.implicitHeight + 14) * slot.shown : BarService.thickness - 8
            clip: true
            opacity: slot.shown * slot.shown
            color: "transparent"

            // Underline marking the focused workspace, on either orientation.
            Rectangle {
                // Plain geometry rather than conditional anchors, which left it filling the slot.
                // A side bar's slot is wider than its number needs, so the line is inset there.
                width: root.vertical ? parent.width - 12 : parent.width
                height: 2
                x: (parent.width - width) / 2
                y: parent.height - height
                color: slot.focused
                    ? Theme.accentLine
                    : mouse.containsMouse ? Theme.border : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.animMs }
                }
            }

            // The number sizes the slot; the focused one trades it for a dot while the bar is
            // open and shows it again once collapsed, so the bar always says where you are.
            ShellText {
                id: label
                anchors.centerIn: parent
                text: String(slot.wsId)
                color: slot.focused || slot.occupied || mouse.containsMouse
                    ? Theme.fgAct
                    : Theme.fg
                font.weight: slot.occupied && !slot.focused ? Font.DemiBold : Font.Normal
                opacity: slot.focused ? 1 - dot.opacity : 1
            }

            ShellText {
                id: dot
                anchors.centerIn: parent
                text: Icons.workspaceDot
                color: Theme.fgAct
                font.pixelSize: 17
                opacity: slot.focused && root.revealed ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animSlideMs; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + slot.wsId + " })")
            }
        }
    }
}
