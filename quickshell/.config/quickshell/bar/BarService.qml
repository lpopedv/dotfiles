pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // State, not config: lives beside shell state, not in the repo (same as dock.json).
    property FileView store: FileView {
        id: store

        path: Quickshell.statePath("bar.json")
        watchChanges: true
        onFileChanged: store.reload()
        onAdapterUpdated: store.writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) store.writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property string position: "bottom"
        }
    }

    readonly property var positions: [
        { id: "top",    text: "Top" },
        { id: "bottom", text: "Bottom" }
    ]

    // An unknown value in the file falls back to bottom.
    readonly property string position: settings.position === "top" ? "top" : "bottom"
    readonly property bool top: root.position === "top"

    // Bar popups open away from the screen edge the bar sits on.
    readonly property int popupEdge: root.top ? Edges.Bottom : Edges.Top

    function setPosition(position) { settings.position = position; }
}
