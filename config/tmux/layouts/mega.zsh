#!/usr/local/bin/zsh

# REF: https://www.jakeworth.com/tmux-application-startup-script/

SESSION="mega"
CWD="$DOTS"
export SESSION_ICON="󰈸" # alts: 🗿󰈸
export SESSION_FG="#d9bb80"

cd $CWD

# Run on_project_start command.

# Run pre command.

# Run on_project_first_start command.

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
tmux -2 new-session -d -s "$SESSION" -n comms
tmux -2 send-keys -t "$SESSION":1 cd\ "$CWD" C-m

# Window "chats"
# if tmux has-session -t "aerc" 2>/dev/null; then
#   tmux -2 send-keys -t "$SESSION":1 tmux\ link-window\ -s\ aerc:aerc\ -t\ 0\ \&\&\ exit C-m
# else
#   tmux -2 send-keys -t "$SESSION":1 aerc C-m
# fi
tmux -2 send-keys -t "$SESSION":1 ls C-m

# Window "dots-nix"
tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n dots-nix
tmux -2 send-keys -t "$SESSION":2 cd\ ~/.dotfiles-nix C-m

# Window "dots"
tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n dots
tmux -2 send-keys -t "$SESSION":3 cd\ ~/code/dotfiles C-m

# Window "ssh-dots"
# tmux -2 send-keys -t "$SESSION":3 et\ -c\ \""cd ~/.dotfiles && ls; exec /usr/bin/zsh"\"\ seth-dev C-m
# tmux -2 send-keys -t "$SESSION":3 ssh\ seth-dev C-m
# tmux -2 send-keys -t "$SESSION":3 cd\ \~/.dotfiles C-m
# tmux -2 send-keys -t "$SESSION":3 ls C-m

# focus

tmux -2 select-window -t "$SESSION":1
tmux -2 select-pane -t "$SESSION":1.1
# tmux -2 rename-window -t "$SESSION":1 comms

tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"

# Run on_project_exit command.
