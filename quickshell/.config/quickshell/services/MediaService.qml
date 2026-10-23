pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The player the bar shows, picked once for every screen's bar rather than by each of them.
Singleton {
    id: root

    // Prefer whatever is playing; otherwise the first player so a paused
    // track stays controllable.
    readonly property MprisPlayer player: {
        const list = Mpris.players.values;
        for (const p of list)
            if (p.isPlaying) return p;
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool playing: root.player !== null && root.player.isPlaying
}
