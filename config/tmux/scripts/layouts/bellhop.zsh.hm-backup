#!/usr/local/bin/zsh

SESSION="bellhop"
ROOT_DIR="$CODE/tern"
CWD="$ROOT_DIR/$SESSION"

export SESSION_ICON="" # alts: 󰂚󰞎󰵚󰵛
export SESSION_FG="#54816B"

cd $CWD

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
tmux new-session -d -s "$SESSION" -n chats
tmux send-keys -t "$SESSION":1 "cd $CWD" "C-m"
tmux send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"

# Window "code"
tmux new-window -c "$CWD" -t "$SESSION":2 -n code
tmux send-keys -t "$SESSION":2.1 "nix-shell --run zsh" "C-m"
tmux send-keys -t "$SESSION":2.1 ls "C-m"

tmux select-layout -t "$SESSION":2 tiled

tmux select-layout -t "$SESSION":2 main-vertical
tmux select-pane -t "$SESSION":2.1

tmux new-window -c "$CWD" -t "$SESSION":3 -n services
# tmux send-keys -t "$SESSION":3.1 sudo\ launchctl\ unload\ /System/Library/LaunchDaemons/org.apache.httpd.plist\ &>/dev/null; C-m
# tmux send-keys -t "$SESSION":3.1 sudo\ launchctl\ unload\ "/System/Library/LaunchDaemons/org.apache.httpd.plist" C-m
# tmux send-keys -t "$SESSION":3.1 sudo\ apachectl\ -k\ stop C-m
# tmux send-keys -t "$SESSION":3.1 "nix-shell --run zsh && sleep 1 && rm .overmind.sock >/dev/null && overmind start" C-m
tmux send-keys -t "$SESSION":3.1 "nix-shell --run zsh && sleep 1" C-m
# tmux send-keys -t "$SESSION":3.1 "nix-shell --run zsh" "C-m"
# tmux send-keys -t "$SESSION":3.1 "sleep 1" "C-m"
tmux send-keys -t "$SESSION":3.1 "rm ./.overmind.sock 2>/dev/null && overmind start || overmind start" "C-m"
# tmux send-keys -t "$SESSION":3.1 "sleep 1" "C-m"
# # tmux send-keys -t "$SESSION":3.1 "if [ -f ./.overmind.sock ]; then rm .overmind.sock; fi;" "C-m"
# tmux send-keys -t "$SESSION":3.1 "overmind start" "C-m"

tmux splitw -c "$CWD" -t "$SESSION":3
tmux select-layout -t "$SESSION":3 tiled
# tmux send-keys -t "$SESSION":3.2 "nix-shell --run zsh && iex -S mix phx.server" "C-m"
tmux send-keys -t "$SESSION":3.2 "nix-shell --run zsh" "C-m"
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
