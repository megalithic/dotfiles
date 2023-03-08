#!/usr/local/bin/zsh

# REF: https://www.jakeworth.com/tmux-application-startup-script/
# = layouts --------------------------------------------------------------------
# HOWTO:
#  tmux list-windows
# 1: dots* (1 panes) [352x84] [layout e2b3,352x84,0,0,62] @56 (active)
# 2: ssh-atlas- (3 panes) [352x84] [layout 7fc6,352x84,0,0[352x63,0,0,76,352x20,0,64{176x20,0,64,80,175x20,177,64,81}]] @67
# 3: ssh-app (2 panes) [352x84] [layout d30c,352x84,0,0[352x63,0,0,77,352x20,0,64,79]] @68
#
# tmux select-layout 7fc6,352x84,0,0[352x63,0,0,76,352x20,0,64{176x20,0,64,80,175x20,177,64,81}]
# -or-
# tmux select-layout a59c,206x60,0,0[206x51,0,0,0,206x8,0,52,1]

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
