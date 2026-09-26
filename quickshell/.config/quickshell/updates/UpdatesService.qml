pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One checker for every screen's bar: a per-widget Process would sync the
// mirrors once per monitor.
QtObject {
    id: root

    readonly property int pollMs: 30 * 60 * 1000
    // Short so a check that raced the network coming up at login recovers fast.
    readonly property int retryMs: 2 * 60 * 1000
    // pacman appends to its log throughout a transaction; wait for it to go quiet.
    readonly property int settleMs: 5000

    // Each entry: { name, from, to }.
    property var repo: []
    property var aur: []
    property bool failed: false
    property date lastChecked

    readonly property int count: repo.length + aur.length
    readonly property bool available: count > 0
    readonly property bool checking: repoCheck.running || aurCheck.running
    readonly property bool checked: !isNaN(lastChecked.getTime())

    // Not in onExited: a Process still reports running inside its own handler.
    onCheckingChanged: if (!root.checking) root.lastChecked = new Date()

    function refresh() {
        if (root.checking) return;
        root.failed = false;
        repoCheck.running = true;
        aurCheck.running = true;
    }

    function upgrade() {
        Quickshell.execDetached([
            "ghostty", "--gtk-single-instance=false",
            "--class=org.dotfiles.updates", "--title=System update",
            "--wait-after-command=true", "-e", "paru"
        ]);
    }

    // Both checkers print `name old -> new`; paru may append ` [ignored]`.
    function parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const match = line.match(/^(\S+) (\S+) -> (\S+)/);
            if (match) out.push({ name: match[1], from: match[2], to: match[3] });
        }
        return out;
    }

    // checkupdates, not `pacman -Sy`: syncs into a throwaway db, so it needs no
    // root and never leaves the system in a partial-upgrade state.
    property Process repoCheck: Process {
        id: repoCheck

        command: ["checkupdates", "--nocolor"]
        stdout: StdioCollector { id: repoOut }

        // 0 = updates, 2 = none, anything else = mirrors unreachable. Keep the
        // last good list on failure rather than falsely reporting "up to date".
        onExited: code => {
            if (code === 0 || code === 2) root.repo = root.parse(repoOut.text);
            else root.failed = true;
        }
    }

    // paru exits 1 both for "nothing to update" and for errors, so stderr is
    // the only way to tell them apart.
    property Process aurCheck: Process {
        id: aurCheck

        command: ["paru", "-Qua", "--color", "never"]
        stdout: StdioCollector { id: aurOut }
        stderr: StdioCollector { id: aurErr }

        onExited: code => {
            if (code === 0 || aurErr.text.trim() === "") root.aur = root.parse(aurOut.text);
            else root.failed = true;
        }
    }

    property Timer poll: Timer {
        interval: root.failed ? root.retryMs : root.pollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Clears the indicator as soon as an upgrade lands, however it was run.
    property FileView pacmanLog: FileView {
        path: "/var/log/pacman.log"
        preload: false
        watchChanges: true
        onFileChanged: settle.restart()
    }

    property Timer settle: Timer {
        id: settle

        interval: root.settleMs
        onTriggered: root.refresh()
    }

    property IpcHandler ipc: IpcHandler {
        target: "updates"

        function refresh(): void { root.refresh(); }
        function upgrade(): void { root.upgrade(); }
        function count(): int { return root.count; }
    }
}
