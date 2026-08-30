#!/usr/bin/env bash
# Prints "  <icon> <capacity>%" for the first battery found, or nothing on
# machines without one (e.g. desktops), so the tmux status bar stays clean.

bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit 2>/dev/null)
[ -z "$bat" ] && exit 0

capacity=$(cat "$bat/capacity" 2>/dev/null) || exit 0
status=$(cat "$bat/status" 2>/dev/null)

icon="󰁹"
[ "$status" = "Charging" ] && icon="󰂄"

printf '  %s %s%%' "$icon" "$capacity"
