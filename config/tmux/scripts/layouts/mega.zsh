#!/usr/local/bin/zsh

cd $DOTS

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
TMUX= tmux -2 new-session -d -s mega -n chats
tmux -2 send-keys -t mega:1 cd\ "$DOTS" C-m

# Create other windows.
tmux -2 new-window -c "$DOTS" -t mega:2 -n dots
tmux -2 new-window -c "$DOTS" -t mega:3 -n ssh-dots

# Window "chats"
tmux -2 send-keys -t mega:1 weechat C-m

# Window "dots"
tmux -2 send-keys -t mega:2 ls C-m

# Window "ssh-dots"
tmux -2 send-keys -t mega:3 et\ -c\ \""cd ~/.dotfiles && ls; exec \$SHELL"\"\ seth-dev C-m

# focus

tmux -2 select-window -t mega:1
tmux -2 select-pane -t mega:1.1

# Run on_project_exit command.
