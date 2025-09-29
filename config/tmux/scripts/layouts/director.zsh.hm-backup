#!/usr/local/bin/zsh

SESSION="director"
ROOT_DIR="$CODE/tern"
CWD="$ROOT_DIR/$SESSION"

export SESSION_ICON="󰿎" # alts: 󰂚󰞎󰵚󰵛
export SESSION_FG="#008060"

cd $CWD

tmux new-session -d -s "$SESSION" -n chats
tmux send-keys -t "$SESSION":1 "cd $CWD" "C-m"
tmux send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"

# Window "code"
tmux new-window -c "$CWD" -t "$SESSION":2 -n code
tmux send-keys -t "$SESSION":2.1 "nix-shell --run zsh" "C-m"
# tmux send-keys -t "$SESSION":2.1 "nix-channel --update && nix-shell --run zsh" "C-m"
tmux send-keys -t "$SESSION":2.1 ls "C-m"

tmux select-layout -t "$SESSION":2 tiled

tmux select-layout -t "$SESSION":2 main-vertical
tmux select-pane -t "$SESSION":2.1

tmux new-window -c "$CWD" -t "$SESSION":3 -n services
tmux send-keys -t "$SESSION":3.1 "nix-shell --run zsh && sleep 1 && direnv allow . && sleep 1" C-m
tmux send-keys -t "$SESSION":3.1 "brew unlink postgresql@14 && sleep 1" C-m
tmux send-keys -t "$SESSION":3.1 "rm ./.overmind.sock 2>/dev/null && overmind start || overmind start" "C-m"

tmux splitw -c "$CWD" -t "$SESSION":3
tmux select-layout -t "$SESSION":3 tiled
tmux send-keys -t "$SESSION":3.2 "nix-shell --run zsh && sleep 1 && direnv allow . && sleep 1" "C-m"
tmux send-keys -t "$SESSION":3.2 "ms $SESSION-tern" "C-m"

tmux select-layout -t "$SESSION":3 tiled
tmux select-layout -t "$SESSION":3 even-horizontal
tmux select-pane -t "$SESSION":3.2
tmux resize-pane -Z -t "$SESSION":3.2

# focus
tmux select-window -t "$SESSION":2
tmux select-pane -t "$SESSION":2.1

tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
