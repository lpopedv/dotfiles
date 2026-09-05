#!/usr/bin/env bash
# Builds the standard project layout in the current window:
#
#   +----------+----------+----------+
#   |  editor  |  agent   |   git    |   three equal columns (top)
#   +----------+----------+----------+
#   |            server              |   one full-width pane (bottom)
#   +--------------------------------+
#
# Bare splits by default; --tools also starts the three tools in the top row.
# Every pane starts in the directory of the pane the layout was triggered from.
# If the window already has more than one pane, the layout is built in a fresh
# window instead of mangling whatever is on screen.

set -euo pipefail

# Height of the bottom server pane. The top row gets the remaining space.
server_height="30%"

# What --tools starts in each of the three top panes, left to right. These are
# typed into a live shell rather than passed to split-window, so quitting a tool
# leaves the pane open instead of closing it.
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

# Pane the layout was triggered from; tmux expands #{pane_id} in the keybind.
[ -n "$origin" ] || origin="${TMUX_PANE:-}"
[ -n "$origin" ] || origin=$(tmux display-message -p '#{pane_id}')

path=$(tmux display-message -p -t "$origin" '#{pane_current_path}')
panes=$(tmux display-message -p -t "$origin" '#{window_panes}')
window=$(tmux display-message -p -t "$origin" '#{window_id}')

if [ "$panes" -gt 1 ]; then
  # Targeting the origin window keeps the new one in that pane's own session,
  # right after the window it came from — never in whichever session tmux
  # happens to consider current.
  left=$(tmux new-window -a -t "$window" -c "$path" -P -F '#{pane_id}')
else
  left="$origin"
fi

# Bottom full-width pane for the server.
tmux split-window -v -f -l "$server_height" -c "$path" -t "$left"

# Split the top row into three columns of identical width. Percentages would
# round unevenly, so the column width is computed in cells: the two separator
# columns are taken off the top and the remainder is divided three ways.
width=$(tmux display-message -p -t "$left" '#{window_width}')
column=$(( (width - 2) / 3 ))

middle=$(tmux split-window -h -l "$(( column * 2 + 1 ))" -c "$path" -t "$left" -P -F '#{pane_id}')
right=$(tmux split-window -h -l "$column" -c "$path" -t "$middle" -P -F '#{pane_id}')

if [ "$tools" = true ]; then
  tmux send-keys -t "$left" "$editor_cmd" C-m
  tmux send-keys -t "$middle" "$agent_cmd" C-m
  tmux send-keys -t "$right" "$git_cmd" C-m
fi

# Start on the leftmost pane, where the editor goes.
tmux select-pane -t "$left"
