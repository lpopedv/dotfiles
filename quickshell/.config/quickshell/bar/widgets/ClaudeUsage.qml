import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.ui

BarItem {
    id: root

    readonly property string collector:
        Quickshell.shellPath("scripts/claude-usage-collect.py")

    property var record: null
    readonly property bool ready:
        record !== null && record.ready === true
        && record.limits !== undefined && record.limits.length > 0

    function limitPct(window) {
        if (!ready) return 0;
        for (const limit of record.limits)
            if (limit.label.indexOf(window) >= 0)
                return Math.round((limit.percent || 0) * 100);
        return 0;
    }

    readonly property int sessionPct: limitPct("5-hour")
    readonly property int weeklyPct: limitPct("7-day")
    readonly property int worst: Math.max(sessionPct, weeklyPct)

    function refresh(force) {
        if (probe.running) return;
        probe.command = force
            ? ["python3", collector, "--force"]
            : ["python3", collector, "--limits-only"];
        probe.running = true;
    }

    onClicked: button => {
        if (button === Qt.RightButton) {
            root.refresh(true);
        } else {
            panel.active = !panel.active;
            if (panel.active) root.refresh(false);
        }
    }

    Component.onCompleted: root.refresh(false)

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh(false)
    }

    Process {
        id: probe
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.record = JSON.parse(this.text);
                } catch (e) {
                    root.record = null;
                }
            }
        }
    }

    // Built on open, destroyed on close: a hidden popup still runs all its bindings.
    LazyLoader {
        id: panel

        ClaudeUsagePanel {
            record: root.record
            anchorItem: root
            visible: true
            onDismissed: panel.active = false
        }
    }

    IpcHandler {
        target: "claude"

        function refresh(): void { root.refresh(true); }
    }

    ShellText {
        id: glyph

        text: Icons.robot
        color: !root.ready
            ? Theme.border
            : Theme.alertColor(root.worst / 100,
                root.hovered || panel.active ? Theme.fgAct : Theme.fg)
        font.weight: Theme.isAlert(root.worst / 100) ? Font.DemiBold : Font.Normal

        Pulse {
            target: glyph
            when: root.ready && root.worst / 100 >= Theme.dangerAt
            halfMs: 1600
        }
    }
}
