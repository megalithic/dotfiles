#!/usr/local/bin/zsh

SESSION="retriever"
ROOT_DIR="$CODE/tern"
CWD="$ROOT_DIR/$SESSION"

export SESSION_ICON="󰩄"
export SESSION_FG="#d39bb6"

cd $CWD

tmux new-session -d -s "$SESSION" -n chats
tmux send-keys -t "$SESSION":1 "cd $CWD" "C-m"
tmux send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"

# Window "code"
tmux new-window -c "$CWD" -t "$SESSION":2 -n code
tmux send-keys -t "$SESSION":2.1 nix-shell\ --run\ zsh "C-m"
tmux send-keys -t "$SESSION":2.1 ls "C-m"

tmux -2 select-layout -t "$SESSION":2 tiled

tmux -2 select-layout -t "$SESSION":2 main-vertical
tmux -2 select-pane -t "$SESSION":2.1

# Window "services"
tmux new-window -c "$CWD" -t "$SESSION":3 -n services
tmux send-keys -t "$SESSION":3.1 "nix-shell --run zsh" "C-m"
tmux send-keys -t "$SESSION":3.1 "m $SESSION-tern" "C-m"

# focus
tmux -2 select-window -t "$SESSION":2
tmux -2 select-pane -t "$SESSION":2.1

tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
