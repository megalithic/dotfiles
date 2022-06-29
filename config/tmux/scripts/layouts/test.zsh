#!/usr/local/bin/zsh

# Clear rbenv variables before starting tmux
unset RBENV_VERSION
unset RBENV_DIR

tmux -2 start-server;

cd $DOTS

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
TMUX= tmux -2 new-session -d -s test -n chats
tmux -2 send-keys -t test:1 cd\ $DOTS C-m

# Create other windows.
tmux -2 new-window -c $DOTS -t test:2 -n code

# Window "chats"
tmux -2 send-keys -t test:1 tmux\ link-window\ -s\ mega:chats\ -t\ 0\ \&\&\ exit C-m

# Window "code"
tmux -2 send-keys -t test:2.1 et\ seth-dev\ -c\ \""cd ~/.dotfiles && ls"\" C-m
# tmux -2 send-keys -t test:2.1 cd\ \~/.dotfiles C-m

tmux -2 select-layout -t test:2 tiled

tmux -2 select-layout -t test:2 main-vertical
tmux -2 select-pane -t test:2.1

# focus
tmux -2 select-window -t test:2
tmux -2 select-pane -t test:2.1

# Run on_project_exit command.
