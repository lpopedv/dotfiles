#!/bin/bash

# Beautiful power menu using wofi with cosmic styling
entries="󰐥 Shutdown\n󰜉 Reboot\n󰍃 Logout\n󰒲 Suspend\n󰤄 Hibernate\n󰌾 Lock"

selected=$(echo -e $entries | wofi --dmenu \
    --cache-file /dev/null \
    --width 300 \
    --height 240 \
    --prompt "󰐥 Power Menu" \
    --style ~/.config/waybar/scripts/power-menu.css \
    --conf ~/.config/waybar/scripts/power-menu.conf)

case $selected in
    "󰐥 Shutdown")
        systemctl poweroff
        ;;
    "󰜉 Reboot")
        systemctl reboot
        ;;
    "󰍃 Logout")
        hyprctl dispatch exit
        ;;
    "󰒲 Suspend")
        systemctl suspend
        ;;
    "󰤄 Hibernate")
        systemctl hibernate
        ;;
    "󰌾 Lock")
        # You can replace this with your preferred lock screen
        if command -v swaylock >/dev/null 2>&1; then
            swaylock -f
        elif command -v hyprlock >/dev/null 2>&1; then
            hyprlock
        else
            loginctl lock-session
        fi
        ;;
esac