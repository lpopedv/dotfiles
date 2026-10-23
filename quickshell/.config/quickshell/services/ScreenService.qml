pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// The screen the user is working on, for the surfaces that exist once rather than per
// screen (session menu, OSD, toasts): they belong where the user is looking.
Singleton {
    readonly property ShellScreen focused: {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name) return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }
}
