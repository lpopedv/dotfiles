pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

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
            property bool pinned: false
        }
    }

    // Keeps the collapsed indicators out as if the bar were hovered, e.g. to glance at
    // which workspaces are in use without reaching for the mouse.
    readonly property bool pinned: settings.pinned

    function togglePinned() {
        settings.pinned = !settings.pinned;
    }

    readonly property var positions: [
        { id: "top",    text: "Top" },
        { id: "bottom", text: "Bottom" },
        { id: "left",   text: "Left" },
        { id: "right",  text: "Right" }
    ]

    // Validated like the dock's: an unknown value in the file falls back to bottom.
    readonly property string position: root.positions.some(p => p.id === settings.position)
        ? settings.position : "bottom"
    readonly property bool top: root.position === "top"
    readonly property bool bottom: root.position === "bottom"
    readonly property bool left: root.position === "left"
    readonly property bool right: root.position === "right"
    // Side bars lay their items out in a column; widgets read this to swap axes.
    readonly property bool vertical: root.left || root.right

    // Thickness: the bar's size across the axis it doesn't stretch along.
    readonly property int thickness: root.vertical ? Theme.barWidth : Theme.barHeight

    // Bar popups open away from the screen edge the bar sits on.
    readonly property int popupEdge: root.top ? Edges.Bottom
        : root.bottom ? Edges.Top
        : root.left ? Edges.Right
        : Edges.Left
    readonly property int popupAdjustment: root.vertical
        ? PopupAdjustment.SlideY : PopupAdjustment.SlideX

    // Transparent gap a popup reserves on its bar-facing side; see Theme.popupInset.
    readonly property int insetTop: root.top ? Theme.popupInset : 0
    readonly property int insetBottom: root.bottom ? Theme.popupInset : 0
    readonly property int insetLeft: root.left ? Theme.popupInset : 0
    readonly property int insetRight: root.right ? Theme.popupInset : 0
    readonly property int insetX: root.insetLeft + root.insetRight
    readonly property int insetY: root.insetTop + root.insetBottom

    // Where items sit across the bar's axis.
    readonly property int crossAlign: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter

    // 0 = settled, 1 = faded out. The bar leaves, the position changes while it is unseen,
    // then it comes back in from the new edge; a bare re-anchor would just jump.
    property real leaving: 0
    property string pending: ""

    Behavior on leaving {
        id: leavingBehavior

        // Direction from the behavior's own target, as in BarItem.
        readonly property bool out: leavingBehavior.targetValue > 0.5

        NumberAnimation {
            duration: leavingBehavior.out ? root.leaveMs : Theme.revealMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: leavingBehavior.out ? Theme.leaveCurve : Theme.revealCurve
        }
    }

    readonly property int leaveMs: 160

    property Timer switcher: Timer {
        // A touch longer than the fade, so the switch lands on a fully hidden bar.
        interval: root.leaveMs + 40
        onTriggered: {
            settings.position = root.pending;
            root.pending = "";
            root.leaving = 0;
        }
    }

    // False for an instant whenever the position changes, whichever way it changed (the
    // panel, IPC or bar.json), so every bar is torn down and rebuilt for the new side.
    property bool built: true

    onPositionChanged: {
        root.built = false;
        Qt.callLater(() => root.built = true);
    }

    // `qs ipc call bar position left`, e.g. for a keybind.
    property IpcHandler ipc: IpcHandler {
        target: "bar"

        function position(edge: string): void {
            if (root.positions.some(p => p.id === edge)) root.setPosition(edge);
        }
        function current(): string { return root.position; }
        function pin(): void { root.togglePinned(); }
    }

    function setPosition(position) {
        if (position === root.position || root.pending !== "") return;
        root.pending = position;
        root.leaving = 1;
        root.switcher.restart();
    }
}
