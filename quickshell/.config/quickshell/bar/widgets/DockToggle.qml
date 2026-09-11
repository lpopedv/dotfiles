import QtQuick
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    active: DockService.mode === "pinned"

    onClicked: button => {
        if (button === Qt.RightButton) panel.visible = !panel.visible;
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

    DockSettingsPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }
}
