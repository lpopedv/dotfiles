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
    }

    ShellText {
        visible: root.active
        text: UpdatesService.count
        color: Theme.red
        font.weight: Font.DemiBold
    }

    UpdatesPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }
}
