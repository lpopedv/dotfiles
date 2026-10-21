pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One hyprsunset for every screen's bar, kept outside the bar for the same reason as
// CaffeineService: the bar is rebuilt whenever it changes side.
QtObject {
    id: root

    readonly property int warmTemp: 4000

    // State, not config: beside bar.json in the shell's state dir, so it survives a
    // reboot as well as a config reload, and the machine comes back as it was left.
    property FileView store: FileView {
        id: store

        path: Quickshell.statePath("nightlight.json")
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

    property Process sunset: Process {
        command: ["hyprsunset", "-t", String(root.warmTemp)]
        running: root.enabled
    }
}
