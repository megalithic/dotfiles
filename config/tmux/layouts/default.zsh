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
# SESSION_PATH="${2:$CODE}"
CODE="${1:~/code}"
CWD="$(zoxide query "$SESSION")"

if [[ -n $SESSION ]]; then
  # CWD="${2:-$CODE}"
  # CWD="$(zoxide query "$SESSION"):-$CODE"


  export SESSION_ICON="󱃸" # alts: 󱃷  󰲌 󱃸
  export SESSION_FG="#eeeeee"

  cd $CWD

  # Create the session and the first window. Manually switch to root
  # directory if required to support tmux < 1.9
  # tmux new-session -d -s "$SESSION" -n chats
tmux -2 new-session -d -s "$SESSION" -n dots
  tmux send-keys -t "$SESSION":1 "cd $CWD" "C-m"
  # tmux send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:chats -t 0 && exit" "C-m"
tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:dots -t 0 && exit" "C-m"

  # Window "code"
  tmux new-window -c "$CWD" -t "$SESSION":2 -n code
  tmux send-keys -t "$SESSION":2.1 "cd $CWD" "C-m"
  tmux send-keys -t "$SESSION":2.1 ls "C-m"

  tmux select-layout -t "$SESSION":2 tiled

  tmux select-layout -t "$SESSION":2 main-vertical
  tmux select-pane -t "$SESSION":2.1
  #
  # tmux new-window -c "$CWD" -t "$SESSION":3 -n services
  # tmux send-keys -t "$SESSION":3.1 "cd $CODE" "C-m"

  # focus
  tmux select-window -t "$SESSION":2
  tmux select-pane -t "$SESSION":2.1

  tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
  tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
fi
