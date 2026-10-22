import QtQuick
import qs
import qs.services
import qs.ui

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
        id: glyph

        text: Icons.packageUp
        color: root.active ? Theme.red
            : root.hovered || panel.visible ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }

        // Same slow pulse as the Claude usage alert; the red stays once it settles.
        Pulse {
            target: glyph
            when: root.active
            halfMs: 1600
        }
    }

    UpdatesPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }
}
