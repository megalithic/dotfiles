#!/usr/bin/env bash

# REF: https://www.jakeworth.com/tmux-application-startup-script/

SESSION="mega"

CWD="/Users/seth/.dotfiles"

export SESSION_ICON="󰈸" # alts: 🗿󰈸
export SESSION_FG="#d9bb80"

tmux -2 new-session -d -s "$SESSION" -n dots
tmux -2 send-keys -t "$SESSION":1 cd\ "$CWD" C-m
tmux -2 send-keys -t "$SESSION":1 ls C-m

# tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"
# tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:dots -t 0 && exit" "C-m"
# if tmux has-session -t "aerc" 2>/dev/null; then
#   tmux -2 send-keys -t "$SESSION":1 tmux\ link-window\ -s\ aerc:aerc\ -t\ 0\ \&\&\ exit C-m
# else
#   tmux -2 send-keys -t "$SESSION":1 aerc C-m
# fi

tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n code
tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n agent

tmux -2 send-keys -t "$SESSION":2.1 "ls" "C-m"
tmux -2 select-layout -t "$SESSION":2 tiled
tmux -2 select-layout -t "$SESSION":2 main-vertical
tmux -2 select-pane -t "$SESSION":2.1

tmux send-keys -t "$SESSION":3.1 "p" "C-m"

# focus
tmux -2 select-window -t "$SESSION":2
tmux -2 select-pane -t "$SESSION":2.1

tmux setenv -t "${SESSION}" 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t "${SESSION}" 'SESSION_FG' "${SESSION_FG}"
# tmux setenv -t "${SESSION}" 'SESSION_BG' "${SESSION_BG}"
