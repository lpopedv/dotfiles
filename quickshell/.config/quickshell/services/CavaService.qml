pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum from cava. Runs only while a Spectrum exists to draw it and something is
// playing: every frame redraws the window it sits in (and Hyprland re-blurs it), so it lives
// in panels that are open for a moment, never in the bar, which is up all day.
Singleton {
    id: root

    readonly property int barCount: 28
    property var bars: new Array(barCount).fill(0)

    // Counted by Spectrum itself, so no view has to remember to switch it off.
    property int viewers: 0
    readonly property bool enabled: root.viewers > 0 && MediaService.playing

    function silence() {
        root.bars = new Array(root.barCount).fill(0);
    }

    onEnabledChanged: if (!enabled) silence()

    Process {
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
