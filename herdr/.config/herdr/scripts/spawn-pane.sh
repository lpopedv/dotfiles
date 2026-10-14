#!/usr/bin/env bash
# Splits the pane the keybinding was pressed from and runs a command in the
# new pane (not zoomed), like tmux's `split-window -h -c ... "cmd"`.

set -euo pipefail
# Debug log in RAM ($XDG_RUNTIME_DIR), not next to the script: it records
# every pane cwd, and is gone at reboot.
exec >> "${XDG_RUNTIME_DIR:-/tmp}/herdr-spawn-pane.log" 2>&1
echo "--- $(date -Iseconds) args=$* pane=${HERDR_ACTIVE_PANE_ID:-unset} cwd=${HERDR_ACTIVE_PANE_CWD:-unset} ---"

pane="${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID not set}"

json() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d$1)"; }

new_pane=$(herdr pane split "$pane" --direction right --ratio 0.5 --focus | json "['result']['pane']['pane_id']")
herdr pane run "$new_pane" "$1"
