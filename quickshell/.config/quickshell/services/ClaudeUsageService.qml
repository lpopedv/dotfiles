pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One collector for every screen's bar: a per-widget Process would run the script once
// per monitor, every minute, and start over whenever the bar is rebuilt.
Singleton {
    id: root

    readonly property string collector: Quickshell.shellPath("scripts/claude-usage-collect.py")

    property var record: null
    readonly property bool ready: root.record !== null && root.record.ready === true
        && root.record.limits !== undefined && root.record.limits.length > 0

    function limitPct(window) {
        if (!root.ready) return 0;
        for (const limit of root.record.limits)
            if (limit.label.indexOf(window) >= 0)
                return Math.round((limit.percent || 0) * 100);
        return 0;
    }

    readonly property int sessionPct: root.limitPct("5-hour")
    readonly property int weeklyPct: root.limitPct("7-day")
    readonly property int worst: Math.max(root.sessionPct, root.weeklyPct)

    // `force` also rescans the transcripts for the panel's per-day and per-model tallies.
    function refresh(force) {
        if (probe.running) return;
        probe.command = force
            ? ["python3", root.collector, "--force"]
            : ["python3", root.collector, "--limits-only"];
        probe.running = true;
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

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    IpcHandler {
        target: "claude"

        function refresh(): void { root.refresh(true); }
    }
}
