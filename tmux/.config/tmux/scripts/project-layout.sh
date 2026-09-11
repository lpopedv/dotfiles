#!/usr/bin/env bash
# Builds a 3-column top row (editor/agent/git) over a full-width server pane.
# --tools also starts those three commands; bare splits otherwise.

set -euo pipefail

server_height="30%"

# Sent via send-keys, not split-window's command arg, so quitting the tool leaves the pane open.
editor_cmd="nvim"
agent_cmd="claude"
git_cmd="lazygit"

tools=false
origin=""
for arg in "$@"; do
  case "$arg" in
    --tools) tools=true ;;
    *) origin="$arg" ;;
  esac
done

[ -n "$origin" ] || origin="${TMUX_PANE:-}"
[ -n "$origin" ] || origin=$(tmux display-message -p '#{pane_id}')

path=$(tmux display-message -p -t "$origin" '#{pane_current_path}')
panes=$(tmux display-message -p -t "$origin" '#{window_panes}')
window=$(tmux display-message -p -t "$origin" '#{window_id}')

if [ "$panes" -gt 1 ]; then
  # -t "$window" keeps the new window in the origin pane's own session, not tmux's current one.
  left=$(tmux new-window -a -t "$window" -c "$path" -P -F '#{pane_id}')
else
  left="$origin"
fi

tmux split-window -v -f -l "$server_height" -c "$path" -t "$left"

# Cells, not percentages, so the 3 columns come out equal width instead of rounding unevenly.
width=$(tmux display-message -p -t "$left" '#{window_width}')
column=$(( (width - 2) / 3 ))

middle=$(tmux split-window -h -l "$(( column * 2 + 1 ))" -c "$path" -t "$left" -P -F '#{pane_id}')
right=$(tmux split-window -h -l "$column" -c "$path" -t "$middle" -P -F '#{pane_id}')

if [ "$tools" = true ]; then
  tmux send-keys -t "$left" "$editor_cmd" C-m
  tmux send-keys -t "$middle" "$agent_cmd" C-m
  tmux send-keys -t "$right" "$git_cmd" C-m
fi

tmux select-pane -t "$left"
