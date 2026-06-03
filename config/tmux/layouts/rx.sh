#!/usr/bin/env bash

SESSION="rx"
CWD="$(zoxide query "$SESSION" 2>/dev/null || printf '%s\n' "$HOME/code")"

export SESSION_ICON="󰐂" # alts:  󰴓 󰃀   
export SESSION_FG="#1e64f1"
export SESSION_BG="#ffffff"

tmux -2 new-session -d -s "$SESSION" -n dots
tmux -2 send-keys -t "$SESSION":1 cd\ "$CWD" "C-m"

# Create other windows.
tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n code
tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n agent
tmux -2 new-window -c "$CWD" -t "$SESSION":4 -n services

# tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"
tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:dots -t 0 && exit" "C-m"

tmux -2 send-keys -t "$SESSION":2.1 "ls" "C-m"
tmux -2 select-layout -t "$SESSION":2 tiled
tmux -2 select-layout -t "$SESSION":2 main-vertical
tmux -2 select-pane -t "$SESSION":2.1

tmux send-keys -t "$SESSION":3.1 "p" "C-m"

tmux send-keys -t "$SESSION":4.1 "m s ${SESSION}-dev" "C-m"
tmux select-layout -t "$SESSION":4 tiled
tmux select-layout -t "$SESSION":4 even-horizontal
tmux select-pane -t "$SESSION":4.2
tmux resize-pane -Z -t "$SESSION":4.2

# focus
tmux -2 select-window -t "$SESSION":2
tmux -2 select-pane -t "$SESSION":2.1

# session closed hook to stop running devenv processes
tmux set-hook -g -n 'session-closed' 'run "devenv down 2>/dev/null"'

tmux setenv -t "${SESSION}" 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t "${SESSION}" 'SESSION_FG' "${SESSION_FG}"
# tmux setenv -t "${SESSION}" 'SESSION_BG' "${SESSION_BG}"
