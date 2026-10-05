import QtQuick
import "../.."
import "../../ui"

// Pending updates count as "active", so the item stays pinned in red even
// while its collapsible neighbours are tucked away.
BarItem {
    id: root

    active: UpdatesService.available

    onClicked: button => {
        if (button === Qt.RightButton) UpdatesService.refresh();
        else panel.visible = !panel.visible;
    }

    ShellText {
        text: Icons.packageUp
        color: root.active ? Theme.red
            : root.hovered || panel.visible ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }

        // Same slow pulse as the Claude usage alert.
        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.45; duration: 1600; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InOutQuad }
        }
    }

    UpdatesPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }
}
