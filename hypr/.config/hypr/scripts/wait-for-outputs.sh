#!/usr/bin/env bash
#
# wait-for-outputs.sh
#
# Blocks until Hyprland reports at least one configured (non-placeholder)
# monitor, i.e. until its output pipeline - not just its IPC socket - is
# actually live.
#
# Why this exists: `hyprland.start` fires the moment Hyprland's config has
# loaded, which is earlier than its outputs finish being set up. A
# layer-shell client launched in that gap (quickshell, in this repo's case)
# can get its very first surface commit - reveal state, exclusive zone -
# latched against not-yet-final output state. Hyprland doesn't always
# recompute that until something forces a fresh commit later, which is why
# the dock only comes right by toggling its mode once by hand. Waiting
# here closes the gap instead of requiring that manual fix every boot. See:
#   https://github.com/hyprwm/Hyprland/discussions/12055
#
# Usage: ./wait-for-outputs.sh; exec "some-layer-shell-client"
# (`;` not `&&`: a client central to the desktop, like the shell itself,
# should still launch on timeout - just without the race having been given
# a chance to clear.)
#
set -euo pipefail

for _ in $(seq 1 50); do
    hyprctl monitors 2>/dev/null | grep -qE '^\s+[0-9]+x[0-9]+@' && exit 0
    sleep 0.1
done

# Outputs never came up in time - let the caller decide whether to proceed.
exit 1
