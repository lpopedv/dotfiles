import QtQuick
import Quickshell.Io
import "../.."
import "../../ui"

BarItem {
    id: root

    // Lit while the dock is held on screen, dimmed while it hides itself, and
    // struck through when it is off entirely - so the button says which of the
    // three modes is on without having to be opened.
    active: DockService.mode === "pinned"

    onClicked: button => {
        // Left click flips between the two modes worth having a shortcut for.
        // Turning the dock off is a decision, so it stays in the menu.
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

        // Cheaper and sharper than a second glyph: one hairline across the
        // icon, which is how every other shell says a thing is switched off.
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
