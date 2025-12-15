#!/usr/local/bin/zsh

SESSION="launchdeck"
CWD="$CODE/work/cspire/$SESSION"

export SESSION_ICON="󱓞"
export SESSION_FG="#00b6f0"

cd $CWD

# if [ -f $CWD/development/scripts/setup_dev_ips.sh ]; then
#   source $CWD/development/scripts/setup_dev_ips.sh
# fi

# Create the session and the first window. Manually switch to root
# directory if required to support tmux < 1.9
tmux -2 new-session -d -s "$SESSION" -n comms
tmux -2 send-keys -t "$SESSION":1 "cd ~/code/work/cspire/launchdeck" C-m

# COMMUNICATIONS
tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:comms -t 0 && exit" "C-m"

# MANUAL CODE MODE WITH DEBUG
tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n code
# Main pane - Neovim with DAP ready
tmux -2 send-keys -t "$SESSION":2.1 "cd ~/code/work/cspire/launchdeck" C-m
# tmux -2 send-keys -t "$SESSION":2.1 "# Set breakpoints with <localleader>db, then <localleader>dd to attach" C-m
# tmux -2 send-keys -t "$SESSION":2.1 "nvim" C-m

# Split for port forwarding
# tmux -2 split-window -v -t "$SESSION":2 -l 5
# tmux -2 send-keys -t "$SESSION":2.2 "cd ~/code/work/cspire/launchdeck/launchdeck_portal_api" C-m
# tmux -2 send-keys -t "$SESSION":2.2 "sleep 15 && POD=\$(kubectl get pods -n smesser-dev -l app=launchdeck-portal-api -o name | head -1 | cut -d'/' -f2) && echo \"Port forwarding \$POD...\" && kubectl port-forward -n smesser-dev \$POD 5678:5678" C-m
# tmux -2 select-layout -t "$SESSION":2 main-vertical
# tmux -2 select-pane -t "$SESSION":2.1

# AI
tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n agents
tmux send-keys -t "$SESSION":3.1 "cd ~/code/work/cspire/launchdeck" C-m
tmux send-keys -t "$SESSION":3.1 "claude --allow-dangerously-skip-permissions"

# PERSISTENT SERVICES
tmux -2 new-window -c "$CWD" -t "$SESSION":4 -n services
tmux send-keys -t "$SESSION":4.1 "cd ~/code/work/cspire/launchdeck" C-m
# tmux send-keys -t "$SESSION":4.1 "devspace purge" C-m
tmux send-keys -t "$SESSION":4.1 "mprocs" C-m

# ZOOM A PANE:
# tmux resize-pane -Z -t "$SESSION":3.2

# tmux -2 select-window -t "$SESSION":3
tmux -2 select-pane -t "$SESSION":3.1

tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
# tmux setenv -t ${SESSION} 'SESSION_BG' "${SESSION_BG}"

# -----------------------------------------------------------------------------------------------

# #!/usr/local/bin/zsh
#
# SESSION="launchdeck"
# CWD="$CODE/work/cspire/$SESSION"
#
# export SESSION_ICON="󱓞"
# export SESSION_FG="#00b6f0"
#
# cd $CWD
#
# # if [ -f $CWD/development/scripts/setup_dev_ips.sh ]; then
# #   source $CWD/development/scripts/setup_dev_ips.sh
# # fi
#
# # Create the session and the first window. Manually switch to root
# # directory if required to support tmux < 1.9
# tmux -2 new-session -d -s "$SESSION" -n comms
# tmux -2 send-keys -t "$SESSION":1 "cd ~/code/work/cspire/launchdeck" C-m
#
# # COMMUNICATIONS
# tmux -2 send-keys -t "$SESSION":1 C-z "tmux link-window -s mega:comms -t 0 && exit" "C-m"
#
# # MANUAL CODE MODE
# tmux -2 new-window -c "$CWD" -t "$SESSION":2 -n code
# tmux -2 send-keys -t "$SESSION":2.1 "cd ~/code/work/cspire/launchdeck" C-m
# tmux -2 send-keys -t "$SESSION":2.1 "ls" C-m
# tmux -2 select-layout -t "$SESSION":2 main-vertical
# tmux -2 select-pane -t "$SESSION":2.1
#
# # AI
# tmux -2 new-window -c "$CWD" -t "$SESSION":3 -n agents
# tmux send-keys -t "$SESSION":3.1 "cd ~/code/work/cspire/launchdeck" C-m
# tmux send-keys -t "$SESSION":3.1 "opencode "
#
# # PERSISTENT SERVICES
# tmux -2 new-window -c "$CWD" -t "$SESSION":4 -n services
# tmux send-keys -t "$SESSION":4.1 "cd ~/code/work/cspire/launchdeck" C-m
# # tmux send-keys -t "$SESSION":4.1 "devspace purge" C-m
# tmux send-keys -t "$SESSION":4.1 "./start-devspace.sh -p smesser-dev" C-m
#
# # ZOOM A PANE:
# # tmux resize-pane -Z -t "$SESSION":3.2
#
# tmux -2 select-window -t "$SESSION":3
# tmux -2 select-pane -t "$SESSION":3.1
#
# tmux setenv -t ${SESSION} 'SESSION_ICON' "${SESSION_ICON}"
# tmux setenv -t ${SESSION} 'SESSION_FG' "${SESSION_FG}"
# # tmux setenv -t ${SESSION} 'SESSION_BG' "${SESSION_BG}"
