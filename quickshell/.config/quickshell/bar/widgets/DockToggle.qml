import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.ui

BarItem {
    id: root

    active: DockService.mode === "pinned"

    onClicked: button => {
        if (button === Qt.RightButton) panel.active = !panel.active;
        else DockService.toggleMode();
    }

    IpcHandler {
        target: "dock"

        function pin(): void { DockService.setMode("pinned"); }
        function auto(): void { DockService.setMode("auto"); }
        function off(): void { DockService.setMode("hidden"); }
        function toggle(): void { DockService.toggleMode(); }
        function mode(): string { return DockService.mode; }
    }

    ShellText {
        text: Icons.dock
        color: DockService.mode === "hidden"
            ? Theme.subtle
            : root.active || root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: 1
            visible: DockService.mode === "hidden"
            color: Theme.subtle
            rotation: -20
        }
    }

    // Built on open, destroyed on close: a hidden popup still runs all its bindings.
    LazyLoader {
        id: panel

        DockSettingsPanel {
            anchorItem: root
            visible: true
            onDismissed: panel.active = false
        }
    }
}
