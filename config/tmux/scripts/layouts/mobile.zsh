#!/usr/local/bin/zsh

cd $CODE/outstand/mobile

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
TMUX= tmux -2 new-session -d -s mobile -n chats
tmux -2 send-keys -t mobile:1 cd\ $CODE/outstand/mobile C-m

# Create other windows.
tmux -2 new-window -c $CODE/outstand/mobile -t mobile:2 -n code
tmux -2 new-window -c $CODE/outstand/mobile -t mobile:3 -n services

# Window "chats"
tmux -2 send-keys -t mobile:1 tmux\ link-window\ -s\ mega:chats\ -t\ 0\ \&\&\ exit C-m

# Window "code"
tmux -2 send-keys -t mobile:2 ls C-m

# Window "services"
tmux -2 send-keys -t mobile:3 ls\ \&\&\ expo\ start C-m

# focus

tmux -2 select-window -t mobile:2
tmux -2 select-pane -t mobile:2.1

# Run on_project_exit command.
