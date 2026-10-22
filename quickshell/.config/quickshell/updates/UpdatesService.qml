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
    // At most one entry: a newer release of the dotfiles repo itself.
    property var dotfiles: []
    property bool failed: false
    property date lastChecked

    readonly property int count: repo.length + aur.length + dotfiles.length
    readonly property bool available: count > 0
    readonly property bool checking: repoCheck.running || aurCheck.running || dotfilesCheck.running
    readonly property bool checked: !isNaN(lastChecked.getTime())

    // Not in onExited: a Process still reports running inside its own handler.
    onCheckingChanged: if (!root.checking) root.lastChecked = new Date()

    function refresh() {
        if (root.checking) return;
        root.failed = false;
        repoCheck.running = true;
        aurCheck.running = true;
        dotfilesCheck.running = true;
    }

    // Packages first, then the dotfiles: a release may expect packages the
    // system doesn't have yet. `dotfiles update` is a no-op when up to date.
    function upgrade() {
        Quickshell.execDetached([
            "ghostty", "--gtk-single-instance=false",
            "--class=org.dotfiles.updates", "--title=System update",
            "--wait-after-command=true", "-e", "sh", "-c", "paru && " + root.dotfilesCli + " update"
        ]);
    }

    // By path: the session's PATH (from the display manager) lacks ~/.local/bin.
    readonly property string dotfilesCli: Quickshell.env("HOME") + "/.local/bin/dotfiles"

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

    // Prints `dotfiles vA -> vB` when a newer release (or, on the edge channel,
    // a newer main) is published, nothing when up to date. ls-remote only: no
    // fetch, nothing changes in the repo.
    property Process dotfilesCheck: Process {
        id: dotfilesCheck

        command: [root.dotfilesCli, "status", "--porcelain"]
        stdout: StdioCollector { id: dotfilesOut }

        onExited: code => {
            if (code === 0) root.dotfiles = root.parse(dotfilesOut.text);
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
