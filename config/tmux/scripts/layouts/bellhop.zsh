#!/usr/local/bin/zsh

SESSION="bellhop"
CWD="$CODE/bellhop"

cd $CWD

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
TMUX= tmux -2 new-session -d -s "$SESSION" -n chats
tmux -2 send-keys -t "$SESSION":1 cd\ "$CWD" C-m

# Create other windows.
tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n code
tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n services

# Window "chats"
tmux -2 send-keys -t "$SESSION":1 tmux\ link-window\ -s\ mega:chats\ -t\ 0\ \&\&\ exit C-m

# Window "code"
tmux -2 send-keys -t "$SESSION":2.1 nix-shell\ --run\ zsh C-m
tmux -2 send-keys -t "$SESSION":2.1 ls C-m

tmux -2 select-layout -t "$SESSION":2 tiled

tmux -2 select-layout -t "$SESSION":2 main-vertical
tmux -2 select-pane -t "$SESSION":2.1

# Window "services"
tmux -2 send-keys -t "$SESSION":3.1 nix-shell\ --run\ zsh C-m
tmux -2 send-keys -t "$SESSION":3.1 rm\ .overmind.sock C-m
tmux -2 send-keys -t "$SESSION":3.1 overmind\ start C-m

tmux -2 splitw -c "$CWD" -t "$SESSION":3
tmux -2 select-layout -t "$SESSION":3 tiled

tmux -2 send-keys -t "$SESSION":3.2 nix-shell\ --run\ zsh C-m
tmux -2 send-keys -t "$SESSION":3.2 iex\ -S\ mix\ phx.server C-m

tmux -2 select-layout -t "$SESSION":3 tiled

tmux -2 select-layout -t "$SESSION":3 even-horizontal
tmux -2 select-pane -t "$SESSION":3.1

# focus
tmux -2 select-window -t "$SESSION":2
tmux -2 select-pane -t "$SESSION":2.1
