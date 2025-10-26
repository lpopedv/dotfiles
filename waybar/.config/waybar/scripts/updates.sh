#!/bin/bash

# Check for system updates with beautiful formatting
if ! command -v checkupdates >/dev/null 2>&1; then
    echo '{"text": "󰮯 N/A", "tooltip": "checkupdates not available", "class": "unavailable"}'
    exit 0
fi

updates_arch=$(checkupdates 2>/dev/null | wc -l)
updates_aur=0

# Check AUR updates if yay or paru is available
if command -v yay >/dev/null 2>&1; then
    updates_aur=$(yay -Qum 2>/dev/null | wc -l)
elif command -v paru >/dev/null 2>&1; then
    updates_aur=$(paru -Qum 2>/dev/null | wc -l)
fi

total_updates=$((updates_arch + updates_aur))

if [ "$total_updates" -eq 0 ]; then
    echo '{"text": "󰮯", "tooltip": "System is up to date", "class": "updated"}'
else
    tooltip="󰆇 Arch: $updates_arch\n󰣇 AUR: $updates_aur\n\nClick to update system"
    if [ "$total_updates" -gt 20 ]; then
        class="critical"
        icon="󰦛"
    elif [ "$total_updates" -gt 10 ]; then
        class="warning"
        icon="󰦛"
    else
        class="normal"
        icon="󰆇"
    fi
    echo "{\"text\": \"$icon $total_updates\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
fi