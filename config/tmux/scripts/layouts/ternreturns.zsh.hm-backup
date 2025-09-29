#!/usr/local/bin/zsh

SESSION="ternreturns"
ROOT_DIR="$CODE/tern"
CWD="$ROOT_DIR/$SESSION"

export SESSION_ICON=""
export SESSION_FG="#a7c080"
export SESSION_BG="#4e6053"

cd $CWD

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
tmux new-session -d -s "$SESSION" -n chats
tmux send-keys -t "$SESSION":1 "cd $CWD" "C-m"
tmux send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"

# Window "code"
tmux new-window -c "$CWD" -t "$SESSION":2 -n code
tmux send-keys -t "$SESSION":2.1 ls C-m

tmux select-layout -t "$SESSION":2 tiled

tmux select-layout -t "$SESSION":2 main-vertical
tmux select-pane -t "$SESSION":2.1

# Window "services"
tmux new-window -c "$CWD" -t "$SESSION":3 -n services
tmux send-keys -t "$SESSION":3.1 yarn\ start C-m

tmux splitw -c "$CWD" -t "$SESSION":3
tmux select-layout -t "$SESSION":3 tiled

tmux send-keys -t "$SESSION":3.2 yarn\ test\ --watch C-m

tmux select-layout -t "$SESSION":3 tiled
tmux select-layout -t "$SESSION":3 even-horizontal
tmux select-pane -t "$SESSION":3.1
tmux resize-pane -Z -t "$SESSION":3.1

# focus
tmux select-window -t "$SESSION":2
tmux select-pane -t "$SESSION":2.1

tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
tmux setenv -t ${SESSION} 'SESSION_BG' "${SESSION_BG}"
tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
