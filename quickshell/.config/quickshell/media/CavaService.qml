pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum from cava. Only runs while `enabled`, so it costs nothing
// when nothing is playing.
QtObject {
    id: root

    readonly property int barCount: 28
    property bool enabled: false
    property var bars: new Array(barCount).fill(0)

    function silence() {
        root.bars = new Array(root.barCount).fill(0);
    }

    onEnabledChanged: if (!enabled) silence()

    property Process proc: Process {
        running: root.enabled
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = new Array(root.barCount);
                for (let i = 0; i < root.barCount; i++)
                    out[i] = Math.min(1, (parseInt(parts[i]) || 0) / 1000);
                root.bars = out;
            }
        }
    }
}
