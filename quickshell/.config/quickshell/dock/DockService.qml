pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Everything the dock knows about applications: which are pinned, which are
// running, and how a window gets back to the .desktop entry that describes it.
// The views only draw what this exposes, so the dock and its context menu can
// never disagree about what an icon stands for.
//
// Windows come from the wlr foreign-toplevel protocol rather than from
// Hyprland's IPC: it is the same list every compositor publishes, so nothing
// here is tied to this machine's window manager.
QtObject {
    id: root

    // ------------------------------------------------------------------- pins

    // What hypr/keybinds.lua reaches for, in the order it binds them. A machine
    // that has just been installed should have a dock worth looking at before
    // anything has been pinned by hand.
    readonly property var defaultPinned: [
        "com.mitchellh.ghostty", "chromium", "org.gnome.Nautilus", "emacsclient"
    ]

    readonly property var pinned: settings.apps ?? []

    // State, not config: this is the record of what the user put on their own
    // dock and how they like it behaving, so it lives beside the rest of the
    // shell's state rather than in the repo. `watchChanges` is what keeps a
    // second monitor's dock - a separate window with its own view of this
    // singleton - in step with the first.
    property FileView store: FileView {
        id: store

        path: Quickshell.statePath("dock.json")
        watchChanges: true
        onFileChanged: store.reload()
        onAdapterUpdated: store.writeAdapter()

        onLoadFailed: error => {
            // First run: seed the file rather than leaving the dock empty and
            // the user with nothing to click.
            if (error === FileViewError.FileNotFound) store.writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property var apps: root.defaultPinned.slice()

            // "auto" reveals on hover, "pinned" stays up, "hidden" is off.
            property string mode: "auto"
            // An empty workspace is the one time a hidden dock is worth
            // showing without being asked for.
            property bool showOnDesktop: true
            // Drops pinned apps that are not running, which turns the dock
            // from a launcher into a window switcher.
            property bool runningOnly: false
            // The "Medium" preset below. A literal rather than a Theme token
            // because the size is the user's to change at runtime, so this
            // file is where it lives.
            property int iconSize: 40
        }
    }

    // --------------------------------------------------------------- settings

    // Every one of these falls back rather than reading the adapter straight.
    // A key the stored file does not have yet comes back undefined - which is
    // what happens to all of these the first time a dock.json written by an
    // older version of this file is loaded, and to any of them if the file is
    // edited by hand.
    readonly property string mode: settings.mode ?? "auto"
    readonly property bool showOnDesktop: settings.showOnDesktop ?? true
    readonly property bool runningOnly: settings.runningOnly ?? false

    // Clamped on read for the same reason: a typo in the file should not be
    // able to produce a dock with no icons on it.
    readonly property int iconSize: Math.max(24, Math.min(64, settings.iconSize ?? 40))

    readonly property var modes: [
        { id: "pinned", text: "Always show" },
        { id: "auto",   text: "Hide until hovered" },
        { id: "hidden", text: "Off" }
    ]

    function setMode(mode) { settings.mode = mode; }

    // What the bar button's click does. Off is deliberately not in the cycle:
    // it is reachable from the menu, and a stray click that made the dock
    // vanish with no visible way back would be a trap.
    function toggleMode() {
        settings.mode = settings.mode === "pinned" ? "auto" : "pinned";
    }

    function toggleShowOnDesktop() { settings.showOnDesktop = !settings.showOnDesktop; }
    function toggleRunningOnly() { settings.runningOnly = !settings.runningOnly; }

    readonly property var sizes: [
        { size: 32, text: "Small" },
        { size: 40, text: "Medium" },
        { size: 52, text: "Large" }
    ]

    function setIconSize(size) { settings.iconSize = size; }

    function isPinned(key) {
        return root.pinned.indexOf(key) >= 0;
    }

    // Every one of these assigns a fresh array. Mutating `settings.apps` in
    // place would change the value without changing the property, so nothing
    // would redraw and nothing would be written back to disk.
    function pin(key) {
        if (!key || root.isPinned(key)) return;
        settings.apps = [...root.pinned, key];
    }

    function unpin(key) {
        settings.apps = root.pinned.filter(other => other !== key);
    }

    function togglePin(key) {
        if (root.isPinned(key)) root.unpin(key);
        else root.pin(key);
    }

    // ------------------------------------------------------------------ entry

    // Resolving an app id walks the whole application list in the worst case,
    // and the dock asks for every window on every rebuild, so answers are kept.
    property var entryCache: ({})

    property Connections catalogue: Connections {
        target: DesktopEntries

        // An app installed mid-session would otherwise stay unrecognised - and
        // iconless - until the shell was reloaded.
        function onApplicationsChanged() {
            root.entryCache = ({});
        }
    }

    function entryFor(appId) {
        if (!appId) return null;
        if (appId in root.entryCache) return root.entryCache[appId];

        const bare = appId.endsWith(".desktop") ? appId.slice(0, -8) : appId;
        let entry = DesktopEntries.byId(bare);
        if (!entry) entry = DesktopEntries.byId(bare.toLowerCase());

        // StartupWMClass is the entry's own claim about the app id its windows
        // will carry. It is the only reliable link for the apps whose window
        // class has nothing to do with the name of their desktop file.
        if (!entry) {
            const wanted = bare.toLowerCase();
            for (const candidate of DesktopEntries.applications.values) {
                const claim = candidate.startupClass;
                if (claim && claim.toLowerCase() === wanted) {
                    entry = candidate;
                    break;
                }
            }
        }

        // Guesses, and documented as such upstream - last resort, after both
        // of the answers the app told us itself.
        if (!entry) entry = DesktopEntries.heuristicLookup(bare);

        root.entryCache[appId] = entry;
        return entry;
    }

    // Which tile a window belongs on. Pinned tiles get first claim on their own
    // id and on the window class they declare, so a pinned launcher and the
    // windows it opens stay one icon even when the two are named differently -
    // emacsclient.desktop opening windows classed `Emacs` is the usual case.
    function keyFor(appId) {
        if (!appId) return "";
        const lower = appId.toLowerCase();

        for (const key of root.pinned) {
            if (key.toLowerCase() === lower) return key;
            const entry = root.entryFor(key);
            const claim = entry ? entry.startupClass : "";
            if (claim && claim.toLowerCase() === lower) return key;
        }

        const entry = root.entryFor(appId);
        return entry ? entry.id : lower;
    }

    // ------------------------------------------------------------------ tiles

    function describe(key, windows, pinned) {
        const entry = root.entryFor(key);
        const icon = entry && entry.icon
            ? Quickshell.iconPath(entry.icon, true)
            : Quickshell.iconPath(key.toLowerCase(), true);

        return {
            key: key,
            entry: entry,
            name: (entry && entry.name) || key,
            icon: icon,
            windows: windows,
            pinned: pinned
        };
    }

    // Pinned tiles first, in the order they were pinned, then everything else
    // that happens to be running - the layout every dock has settled on, and
    // the reason a pinned icon never moves out from under the pointer just
    // because something else was launched.
    readonly property var items: {
        const groups = {};
        const running = [];

        for (const toplevel of ToplevelManager.toplevels.values) {
            // Reading appId here is also what makes this rebuild when an app
            // sets its id late, which several toolkits do a frame after the
            // window is first mapped.
            const key = root.keyFor(toplevel.appId);
            if (!(key in groups)) {
                groups[key] = [];
                running.push(key);
            }
            groups[key].push(toplevel);
        }

        const tiles = [];
        for (const key of root.pinned) {
            const windows = groups[key] ?? [];
            if (root.runningOnly && windows.length === 0) continue;
            tiles.push(root.describe(key, windows, true));
        }
        for (const key of running)
            if (!root.isPinned(key)) tiles.push(root.describe(key, groups[key], false));
        return tiles;
    }

    // Where the divider goes. Counted off the tiles actually on the dock rather
    // than off the pin list, which are not the same number once `runningOnly`
    // has dropped the pinned apps that are closed.
    readonly property int pinnedCount: {
        let count = 0;
        for (const tile of root.items) if (tile.pinned) count++;
        return count;
    }

    // ---------------------------------------------------------------- actions

    // The tile whose icon is bouncing because it was just asked to start. One
    // at a time on purpose: a queue of bouncing icons is noise, and the bounce
    // only has to answer "did my click land".
    property string launching: ""

    property Timer launchTimer: Timer {
        // Long enough for a cold start on a slow disk. This is the backstop -
        // the bounce normally ends the moment the app's first window appears.
        interval: 8000
        onTriggered: root.launching = ""
    }

    onItemsChanged: {
        if (root.launching === "") return;
        for (const tile of root.items) {
            if (tile.key === root.launching && tile.windows.length > 0) {
                root.launching = "";
                root.launchTimer.stop();
                return;
            }
        }
    }

    function launch(tile) {
        if (!tile.entry) return;
        tile.entry.execute();
        root.launching = tile.key;
        root.launchTimer.restart();
    }

    function focus(toplevel) {
        if (!toplevel) return;
        // A minimised window that is only activated comes back focused but
        // still hidden, which reads as the click having done nothing.
        if (toplevel.minimized) toplevel.minimized = false;
        toplevel.activate();
    }

    // Clicking a tile that is already focused steps to that app's next window.
    // `indexOf` returning -1 for a window we do not own lands on the first one,
    // which is what a click from anywhere else should do.
    function activate(tile) {
        if (tile.windows.length === 0) {
            root.launch(tile);
            return;
        }

        const active = ToplevelManager.activeToplevel;
        const at = tile.windows.indexOf(active);
        root.focus(tile.windows[(at + 1) % tile.windows.length]);
    }

    function cycle(tile, step) {
        if (tile.windows.length < 2) return;
        const active = ToplevelManager.activeToplevel;
        const at = tile.windows.indexOf(active);
        const count = tile.windows.length;
        root.focus(tile.windows[((at + step) % count + count) % count]);
    }

    function quit(tile) {
        // A copy: closing a window takes it out of the live list mid-loop.
        for (const toplevel of tile.windows.slice()) toplevel.close();
    }
}
