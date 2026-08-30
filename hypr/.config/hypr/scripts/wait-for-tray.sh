#!/usr/bin/env bash
#
# wait-for-tray.sh
#
# Blocks until a StatusNotifierWatcher answers on the session bus, i.e.
# until the bar's tray module has actually initialized - not just started.
#
# Why this exists: apps that register a StatusNotifierItem (system tray
# icon) before the watcher exists lose that registration silently and
# never retry. The bar takes a moment after exec to publish
# org.kde.StatusNotifierWatcher, so any tray app launched in the same
# breath as it in autostart.lua is racing it - most visibly Mullvad's
# GUI, which starts connected but shows no tray icon until manually
# reopened. See:
#   https://github.com/mullvad/mullvadvpn-app/issues/8848
#   https://github.com/Alexays/Waybar/issues/3468
#
# Usage: ./wait-for-tray.sh && exec "some-tray-app"
#
set -euo pipefail

for _ in $(seq 1 50); do
    busctl --user list 2>/dev/null | grep -q org.kde.StatusNotifierWatcher && exit 0
    sleep 0.1
done

# Watcher never showed up (the bar crashed, tray module disabled, etc.) -
# exit non-zero so callers can decide whether to launch anyway.
exit 1
