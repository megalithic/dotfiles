#!/usr/local/bin/zsh

SESSION="canonize"
CWD="$(zoxide query "$SESSION")"

export SESSION_ICON="" # alts:  󰴓 󰃀   
export SESSION_FG="#e39b7b"
# export SESSION_BG="#626262"

echo "$CWD"
cd "$CWD"

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
tmux -2 new-session -d -s "$SESSION" -n comms
tmux -2 send-keys -t "$SESSION":1 cd\ "$CWD" C-m

# Create other windows.
tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n code
tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n services

# Window "comms"
# tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"
tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:comms -t 0 && exit" "C-m"

# Window "code"
tmux -2 send-keys -t "$SESSION":2.1 "ls" C-m
# tmux -2 send-keys -t "$SESSION":2.1 "ls" C-m

tmux -2 select-layout -t "$SESSION":2 tiled

tmux -2 select-layout -t "$SESSION":2 main-vertical
tmux -2 select-pane -t "$SESSION":2.1

tmux new-window -c "$CWD" -t "$SESSION":3 -n services
tmux send-keys -t "$SESSION":3.1 "just overmind start" "C-m"

tmux splitw -c "$CWD" -t "$SESSION":3
tmux select-layout -t "$SESSION":3 tiled
tmux send-keys -t "$SESSION":3.2 "m s $SESSION-dev" "C-m"

tmux select-layout -t "$SESSION":3 tiled
tmux select-layout -t "$SESSION":3 even-horizontal
tmux select-pane -t "$SESSION":3.2
tmux resize-pane -Z -t "$SESSION":3.2

# Window "services"
# tmux -2 send-keys -t "$SESSION":3.1 "brew link -f postgresql@14 && m s canonize" C-m
#
# tmux -2 splitw -c "$CWD" -t "$SESSION":3
# tmux -2 select-layout -t "$SESSION":3 tiled
#
# tmux -2 send-keys -t "$SESSION":3.2 fwd\ 4000 C-m
#
# tmux -2 select-layout -t "$SESSION":3 tiled
#
# tmux -2 select-layout -t "$SESSION":3 even-horizontal
# tmux -2 select-pane -t "$SESSION":3.1
# tmux -2 resize-pane -Z -t "$SESSION":3.1

# focus
tmux -2 select-window -t "$SESSION":2
tmux -2 select-pane -t "$SESSION":2.1

tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
# tmux setenv -t ${SESSION} 'SESSION_BG' "${SESSION_BG}"
