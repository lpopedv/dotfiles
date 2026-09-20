#!/usr/bin/env bash
# Builds a 3-column top row (editor/agent/git) over a full-width bottom pane,
# in the CURRENT tab. --tools also starts those three commands; bare splits
# otherwise.
#
# The full-width bottom split only comes for free as the FIRST split of a
# solitary pane -- herdr has no equivalent to tmux's `split-window -f` to
# break out of an existing layout, so we flatten the current tab down to one
# pane ourselves (close every sibling pane) before laying it out.

set -euo pipefail
exec >> "$(dirname "$0")/project-layout.log" 2>&1
echo "--- $(date -Iseconds) args=$* pane=${HERDR_ACTIVE_PANE_ID:-unset} cwd=${HERDR_ACTIVE_PANE_CWD:-unset} ---"

editor_cmd="nvim"
agent_cmd="claude"
git_cmd="lazygit"
server_ratio="0.7"

tools=false
for arg in "$@"; do
  case "$arg" in
    --tools) tools=true ;;
  esac
done

pane="${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID not set}"

json() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d$1)"; }
sibling_panes() { python3 -c "
import sys, json
d = json.load(sys.stdin)
tab, keep = sys.argv[1], sys.argv[2]
for p in d['result']['panes']:
    if p['tab_id'] == tab and p['pane_id'] != keep:
        print(p['pane_id'])
" "$1" "$2"; }

tab_id=$(herdr pane get "$pane" | json "['result']['pane']['tab_id']")
herdr pane list | sibling_panes "$tab_id" "$pane" | while read -r sibling; do
  herdr pane close "$sibling" >/dev/null
done

root="$pane"

herdr pane split "$root" --direction down --ratio "$server_ratio" >/dev/null

left="$root"
mid_right=$(herdr pane split "$left" --direction right --ratio 0.333 | json "['result']['pane']['pane_id']")
right=$(herdr pane split "$mid_right" --direction right --ratio 0.5 | json "['result']['pane']['pane_id']")
middle="$mid_right"

if [ "$tools" = true ]; then
  herdr pane run "$left" "$editor_cmd" >/dev/null
  herdr pane run "$middle" "$agent_cmd" >/dev/null
  herdr pane run "$right" "$git_cmd" >/dev/null
fi
