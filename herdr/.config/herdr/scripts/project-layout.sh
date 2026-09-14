#!/usr/bin/env bash
# herdr port of tmux/.config/tmux/scripts/project-layout.sh.
# Builds a 3-column top row (editor/agent/git) over a full-width bottom pane,
# in a fresh tab. --tools also starts those three commands; bare splits otherwise.
#
# The full-width bottom split only comes for free because it's the FIRST split
# of a brand-new, solitary tab pane -- herdr has no equivalent to tmux's
# `split-window -f` to break out of an existing layout later.

set -euo pipefail

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

cwd="${HERDR_ACTIVE_PANE_CWD:-$PWD}"

json() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d$1)"; }

root=$(herdr tab create --cwd "$cwd" --focus | json "['result']['root_pane']['pane_id']")

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
