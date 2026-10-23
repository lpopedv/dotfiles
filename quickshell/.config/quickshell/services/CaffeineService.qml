pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One inhibitor for every screen's bar, and state that outlives the bar: it is
// rebuilt whenever it changes side, which would otherwise switch caffeine off.
Singleton {
    id: root

    // State, not config: beside bar.json in the shell's state dir, so it survives a
    // reboot as well as a config reload, and the machine comes back as it was left.
    FileView {
        id: store

        path: Quickshell.statePath("caffeine.json")
        watchChanges: true
        onFileChanged: store.reload()
        onAdapterUpdated: store.writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) store.writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property bool enabled: false
        }
    }

    readonly property bool enabled: settings.enabled

    function toggle() { settings.enabled = !settings.enabled; }
    function setEnabled(enabled) { settings.enabled = enabled; }

    Process {
        command: [
            "systemd-inhibit",
            "--what=idle",
            "--who=quickshell",
            "--why=Caffeine mode (manual)",
            "sleep", "infinity"
        ]
        running: root.enabled
    }

    IpcHandler {
        target: "caffeine"

        function toggle(): void { root.toggle(); }
        function on(): void { root.setEnabled(true); }
        function off(): void { root.setEnabled(false); }
        function status(): bool { return root.enabled; }
    }
}
