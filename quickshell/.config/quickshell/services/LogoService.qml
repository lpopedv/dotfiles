pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// The clock behind the streak orbiting the bar's logo, one for every screen's bar so they
// all run in step. It ticks at `fps`, not the display's refresh rate: the streak covers a
// few dozen pixels a second, so more frames would look no different and only cost more.
Singleton {
    id: root

    readonly property int lapMs: 3000
    readonly property int fps: 24

    // 0 to 1 round one lap; read off the wall clock, so a late tick never slows the lap.
    property real phase: 0

    // Nobody is looking: no input for a while (caffeine or not; it keeps the screen on,
    // which says nothing about anyone watching it).
    IdleMonitor {
        id: idle
        timeout: 120
        respectInhibitors: false
    }

    // A fullscreen window hides the bar on its monitor (see Logo.qml); with every screen
    // covered, there is nothing to draw on.
    function covered(screen) {
        const monitor = screen ? Hyprland.monitorFor(screen) : null;
        return monitor !== null && monitor.activeWorkspace !== null
            && monitor.activeWorkspace.hasFullscreen;
    }

    readonly property bool anyVisible: {
        for (const screen of Quickshell.screens)
            if (!root.covered(screen)) return true;
        return false;
    }

    // Also still while the bar changes side: it is being torn down and rebuilt.
    readonly property bool running: !idle.isIdle && root.anyVisible && BarService.leaving === 0

    Timer {
        interval: Math.round(1000 / root.fps)
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: root.phase = (Date.now() % root.lapMs) / root.lapMs
    }
}
