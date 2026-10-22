import QtQuick
import Quickshell
import qs
import qs.services
import qs.ui

BarItem {
    id: root

    readonly property real worst: ClaudeUsageService.worst / 100

    onClicked: button => {
        if (button === Qt.RightButton) {
            ClaudeUsageService.refresh(true);
        } else {
            panel.active = !panel.active;
            if (panel.active) ClaudeUsageService.refresh(false);
        }
    }

    // Built on open, destroyed on close: a hidden popup still runs all its bindings.
    LazyLoader {
        id: panel

        ClaudeUsagePanel {
            record: ClaudeUsageService.record
            anchorItem: root
            visible: true
            onDismissed: panel.active = false
        }
    }

    ShellText {
        id: glyph

        text: Icons.robot
        color: !ClaudeUsageService.ready
            ? Theme.border
            : Theme.alertColor(root.worst, root.hovered || panel.active ? Theme.fgAct : Theme.fg)
        font.weight: Theme.isAlert(root.worst) ? Font.DemiBold : Font.Normal

        Pulse {
            target: glyph
            when: ClaudeUsageService.ready && root.worst >= Theme.dangerAt
            halfMs: 1600
        }
    }
}
