#!/usr/bin/env bash
# Waits for the bar's tray to register on the session bus, so apps launched right after it in
# autostart.lua don't lose their tray icon to the registration race (mullvad/mullvadvpn-app#8848).
set -euo pipefail

for _ in $(seq 1 50); do
    busctl --user list 2>/dev/null | grep -q org.kde.StatusNotifierWatcher && exit 0
    sleep 0.1
done

exit 1
