#!/usr/local/bin/zsh

# Clear rbenv variables before starting tmux
unset RBENV_VERSION
unset RBENV_DIR

tmux -2 start-server

cd $CODE/outstand

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
TMUX= tmux -2 new-session -d -s atlas -n chats
tmux -2 send-keys -t atlas:1 cd\ $CODE/outstand C-m

# Create other windows.
tmux -2 new-window -c $CODE/outstand -t atlas:2 -n code
tmux -2 new-window -c $CODE/outstand -t atlas:3 -n services

# Window "chats"
tmux -2 send-keys -t atlas:1 tmux\ link-window\ -s\ mega:chats\ -t\ 0\ \&\&\ exit C-m

# Window "code"
tmux -2 send-keys -t atlas:2.1 ssh\ seth-dev C-m
sleep 1
tmux -2 send-keys -t atlas:2.1 cd\ \~/code/atlas C-m
tmux -2 send-keys -t atlas:2.1 eval\ \$\(desk\ load\)\;\ ls C-m

tmux -2 select-layout -t atlas:2 tiled

tmux -2 select-layout -t atlas:2 main-vertical
tmux -2 select-pane -t atlas:2.1

# Window "services"
tmux -2 send-keys -t atlas:3.1 ssh\ seth-dev C-m
sleep 1
tmux -2 send-keys -t atlas:3.1 cd\ \~/code/atlas C-m
tmux -2 send-keys -t atlas:3.1 eval\ \$\(desk\ load\) C-m
tmux -2 send-keys -t atlas:3.1 dev\ down\ --remove-orphans\;\ dev\ up\ -d\ \&\&\ dev\ logs\ -f C-m

tmux -2 splitw -c $CODE/outstand -t atlas:3
tmux -2 select-layout -t atlas:3 tiled

tmux -2 send-keys -t atlas:3.2 ssh\ seth-dev C-m
sleep 1
tmux -2 send-keys -t atlas:3.2 cd\ \~/code/atlas C-m
tmux -2 send-keys -t atlas:3.2 eval\ \$\(desk\ load\)\;\ iex\ -S\ mix C-m

tmux -2 select-layout -t atlas:3 tiled

tmux -2 select-layout -t atlas:3 even-horizontal
tmux -2 select-pane -t atlas:3.1

# focus

tmux -2 select-window -t atlas:1
tmux -2 select-pane -t atlas:1.1

# Run on_project_exit command.
