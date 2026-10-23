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
    // Claude Code is in use here at all: local stats or limits. Not every Lethe install has
    // it (the `claude` package is the owner's), and the widget hides where it would only
    // ever show a dead icon.
    readonly property bool present: root.record !== null && root.record.ready === true
    readonly property bool ready: root.present
        && root.record.limits !== undefined && root.record.limits.length > 0

    // Every minute where it is used; elsewhere a slow look, so it shows up once it is.
    readonly property int pollMs: 60 * 1000
    readonly property int idlePollMs: 15 * 60 * 1000

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

    // A forced refresh asked for while a plain one runs; run once that one is done,
    // or the click (or IPC call) would be dropped without a word.
    property bool forcePending: false

    // `force` also rescans the transcripts for the panel's per-day and per-model tallies.
    function refresh(force) {
        if (probe.running) {
            if (force) root.forcePending = true;
            return;
        }
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

        // Not in onExited: a Process still reports running inside its own handler.
        onRunningChanged: {
            if (probe.running || !root.forcePending) return;
            root.forcePending = false;
            Qt.callLater(() => root.refresh(true));
        }
    }

    Timer {
        interval: root.present ? root.pollMs : root.idlePollMs
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
