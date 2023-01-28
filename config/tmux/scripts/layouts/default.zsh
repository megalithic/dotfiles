#!/usr/local/bin/zsh

# REF: https://www.jakeworth.com/tmux-application-startup-script/

SESSION="${1:-}"

cd $DOTS

if [[ -n $SESSION ]]; then
  # Run on_project_start command.

  # Run pre command.

  # Run on_project_first_start command.

  # Create the session and the first window. Manually switch to root
  # directory if required to support tmux < 1.9
  TMUX= tmux -2 new-session -d -s "$SESSION" -n chats
  tmux -2 send-keys -t "$SESSION":1 cd\ "$DOTS" C-m

  # Create other windows.
  tmux -2 new-window -c "$DOTS" -t "$SESSION":2 -n code
  tmux -2 new-window -c "$DOTS" -t "$SESSION":3 -n services

  # Window "chats"
  if ! tmux has-session -t "weechat" 2>/dev/null; then
    tmux -2 send-keys -t "$SESSION":1 tmux\ link-window\ -s\ mega:chats\ -t\ 0\ \&\&\ exit C-m
  else
    tmux -2 send-keys -t "$SESSION":1 weechat C-m
  fi

  # Window "code"
  tmux -2 send-keys -t "$SESSION":2 ls C-m

  # Window "services"
  # tmux -2 send-keys -t "$SESSION":3 et\ -c\ \""cd ~/.dotfiles && ls; exec /usr/bin/zsh"\"\ seth-dev C-m
  tmux -2 send-keys -t "$SESSION":3 ls C-m
  # tmux -2 send-keys -t mega:3 ssh\ seth-dev C-m
  # tmux -2 send-keys -t mega:3 cd\ \~/.dotfiles C-m
  # tmux -2 send-keys -t mega:3 ls C-m

  # focus

  tmux -2 select-window -t "$SESSION":1
  tmux -2 select-pane -t "$SESSION":1.1

  # Run on_project_exit command.
fi
