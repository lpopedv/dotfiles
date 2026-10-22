import QtQuick
import Quickshell
import qs
import qs.services

// The frame every bar popup shares: anchored to its bar item, opening away from the screen
// edge the bar sits on, a glass panel that fades in, Esc to close. Content goes inside, sized
// by `panelWidth` and `contentHeight`; `padding` is the space around it.
PopupWindow {
    id: root

    property Item anchorItem: null
    property real panelWidth: 200
    property real contentHeight: 0
    property int padding: 10

    default property alias content: body.data

    // Keys the panel doesn't handle itself (it handles Esc, unless a handler accepts it).
    signal keyPressed(var event)
    // However it closes - Esc, the focus grab, the owner - so loaders can drop it.
    signal dismissed

    anchor.item: root.anchorItem
    anchor.edges: BarService.popupEdge
    anchor.gravity: BarService.popupEdge
    anchor.adjustment: BarService.popupAdjustment

    // Gap off the bar is transparent space inside the popup: the compositor
    // clamps an anchored popup to the bar's edge, so anchor.margins can't do it.
    implicitWidth: root.panelWidth + BarService.insetX
    implicitHeight: root.contentHeight + root.padding * 2 + BarService.insetY
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (root.visible) return;
        // Ready to fade in again if the popup is reused rather than rebuilt.
        panel.opacity = 0;
        root.dismissed();
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.topMargin: BarService.insetTop
        anchors.bottomMargin: BarService.insetBottom
        anchors.leftMargin: BarService.insetLeft
        anchors.rightMargin: BarService.insetRight
        color: Theme.glass
        border.width: 1
        border.color: Theme.border

        opacity: 0

        NumberAnimation on opacity {
            to: 1
            duration: Theme.animSlideMs
            easing.type: Easing.OutCubic
            running: root.visible
        }

        // Eases out of the bar it hangs from as it fades in.
        transform: Translate {
            readonly property real away: Theme.popupSlide * (1 - panel.opacity)
            x: BarService.left ? -away : BarService.right ? away : 0
            y: BarService.top ? -away : BarService.bottom ? away : 0
        }

        focus: true
        Keys.onPressed: event => {
            root.keyPressed(event);
            if (event.accepted || event.key !== Qt.Key_Escape) return;
            root.visible = false;
            event.accepted = true;
        }

        Item {
            id: body

            anchors.fill: parent
            anchors.margins: root.padding
        }
    }
}
