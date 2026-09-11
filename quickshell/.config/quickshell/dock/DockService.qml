pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Windows come from wlr foreign-toplevel, not Hyprland IPC: compositor-agnostic.
QtObject {
    id: root

    // Matches what hypr/keybinds.lua binds, so a fresh install has a usable dock.
    readonly property var defaultPinned: [
        "com.mitchellh.ghostty", "chromium", "org.gnome.Nautilus", "emacsclient"
    ]

    readonly property var pinned: settings.apps ?? []

    // State, not config: lives beside shell state, not in the repo.
    // watchChanges keeps a second monitor's dock window in sync with this one.
    property FileView store: FileView {
        id: store

        path: Quickshell.statePath("dock.json")
        watchChanges: true
        onFileChanged: store.reload()
        onAdapterUpdated: store.writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) store.writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property var apps: root.defaultPinned.slice()
            property string mode: "auto"
            property bool showOnDesktop: true
            property bool runningOnly: false
            property int iconSize: 40
        }
    }

    // Fallbacks handle a dock.json missing a key (older version, or hand-edited).
    readonly property string mode: settings.mode ?? "auto"
    readonly property bool showOnDesktop: settings.showOnDesktop ?? true
    readonly property bool runningOnly: settings.runningOnly ?? false

    // Clamped so a bad value in the file can't produce a dock with no icons.
    readonly property int iconSize: Math.max(24, Math.min(64, settings.iconSize ?? 40))

    readonly property var modes: [
        { id: "pinned", text: "Always show" },
        { id: "auto",   text: "Hide until hovered" },
        { id: "hidden", text: "Off" }
    ]

    function setMode(mode) { settings.mode = mode; }

    // "hidden" deliberately excluded: a stray click shouldn't vanish the dock with no way back.
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

    // Fresh array each time: mutating settings.apps in place wouldn't trigger a redraw or a save.
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

    // Resolving an app id can walk the whole application list; the dock asks per rebuild, so cache it.
    property var entryCache: ({})

    property Connections catalogue: Connections {
        target: DesktopEntries

        // Otherwise an app installed mid-session stays unrecognised until reload.
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

        // startupClass is the entry's own claim about its windows' app id - the
        // only reliable link when the window class doesn't match the desktop file name.
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

        // Last resort: a guess, after both of the app's own claims.
        if (!entry) entry = DesktopEntries.heuristicLookup(bare);

        root.entryCache[appId] = entry;
        return entry;
    }

    // Pinned tiles get first claim on their id and startupClass, so a pinned
    // launcher and the windows it opens stay one icon even when named differently.
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

    // Pinned tiles first (pin order), then running ones - a pinned icon never
    // moves under the pointer just because something else launched.
    readonly property var items: {
        const groups = {};
        const running = [];

        for (const toplevel of ToplevelManager.toplevels.values) {
            // Reading appId here is also what triggers a rebuild once a
            // toolkit sets it late, a frame after the window is mapped.
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

    // Counted off actual tiles, not the pin list: runningOnly can make them differ.
    readonly property int pinnedCount: {
        let count = 0;
        for (const tile of root.items) if (tile.pinned) count++;
        return count;
    }

    // One bouncing tile at a time on purpose - a queue would just be noise.
    property string launching: ""

    property Timer launchTimer: Timer {
        // Backstop for a cold start; normally the bounce ends once a window appears.
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
        // activate() alone leaves a minimised window focused but still hidden.
        if (toplevel.minimized) toplevel.minimized = false;
        toplevel.activate();
    }

    // indexOf returning -1 for an unowned window lands on the first one, as intended.
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
        // slice(): closing a window mutates the live list mid-iteration otherwise.
        for (const toplevel of tile.windows.slice()) toplevel.close();
    }
}
