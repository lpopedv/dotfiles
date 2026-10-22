pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    // Picked when the menu opens, not bound: the menu stays on the screen it opened on.
    property ShellScreen screen: null

    // logind's answer, not a guess: "na" without a swap big enough to resume from, which
    // would make the button fail silently. "challenge" means it would ask for a password.
    property bool canHibernate: false

    Process {
        id: hibernateProbe
        command: ["busctl", "--system", "call", "org.freedesktop.login1", "/org/freedesktop/login1",
                  "org.freedesktop.login1.Manager", "CanHibernate"]
        stdout: StdioCollector {
            onStreamFinished: root.canHibernate = /"(yes|challenge)"/.test(this.text)
        }
    }

    function show() {
        root.screen = ScreenService.focused;
        // Asked on every open: swap can be added or removed mid-session.
        hibernateProbe.running = true;
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
