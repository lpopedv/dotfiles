pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    // Picked when the menu opens, not bound: the menu stays on the screen it opened on.
    property ShellScreen screen: null

    function show() {
        root.screen = ScreenService.focused;
        root.open = true;
    }

    function close() {
        root.open = false;
    }

    function toggle() {
        if (root.open) root.close();
        else root.show();
    }

    IpcHandler {
        target: "session"

        function toggle(): void { root.toggle(); }
        function open(): void { root.show(); }
        function close(): void { root.close(); }
    }
}
