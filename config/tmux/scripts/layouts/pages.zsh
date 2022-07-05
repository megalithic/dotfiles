#!/usr/local/bin/zsh

cd $CODE/outstand

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
TMUX= tmux -2 new-session -d -s pages -n chats
tmux -2 send-keys -t pages:1 cd\ $CODE/outstand C-m

# Create other windows.
tmux -2 new-window -c $CODE/outstand -t pages:2 -n code
tmux -2 new-window -c $CODE/outstand -t pages:3 -n services

# Window "chats"
tmux -2 send-keys -t pages:1 tmux\ link-window\ -s\ mega:chats\ -t\ 0\ \&\&\ exit C-m

# Window "code"
tmux -2 send-keys -t pages:2.1 et\ -c\ \""cd ~/code/pages && ls; exec /usr/bin/zsh"\"\ seth-dev C-m

tmux -2 select-layout -t pages:2 tiled

tmux -2 select-layout -t pages:2 main-vertical
tmux -2 select-pane -t pages:2.1

# Window "services"
tmux -2 send-keys -t pages:3.1 et\ -c\ \""cd ~/code/pages && ls && dev down --remove-orphans; dev up -d && dev logs -f; exec /usr/bin/zsh"\"\ seth-dev C-m

tmux -2 splitw -c $CODE/outstand -t pages:3
tmux -2 select-layout -t pages:3 tiled

tmux -2 send-keys -t pages:3.2 et\ -c\ \""cd ~/code/pages && ls; exec /usr/bin/zsh"\"\ seth-dev C-m

tmux -2 select-layout -t pages:3 tiled

tmux -2 select-layout -t pages:3 even-horizontal
tmux -2 select-pane -t pages:3.1

# focus

tmux -2 select-window -t pages:2
tmux -2 select-pane -t pages:2.1

# Run on_project_exit command.
