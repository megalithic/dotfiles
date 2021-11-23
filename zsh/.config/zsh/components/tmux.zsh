#!/usr/bin/env zsh

#
# try and autoload tmux session
function mux() {
	if [[ $# == 0 ]] && tmux has-session 2>/dev/null; then
		command tmux attach-session
	else
		command tmux "$@"
	fi
}

# tm with no sessions open it will create a session called "new".
# tm irc it will attach to the irc session (if it exists), else it will create it.
# tm with one session open, it will attach to that session.
# tm with more than one session open it will let you select the session via fzf.
tm() {
	[[ -n $TMUX ]] && change="switch-client" || change="attach-session"
	if [ $1 ]; then
		tmux $change -t "$1" 2>/dev/null || (tmuxinator start $1 --no-attach && tmux $change -t "$1")
		# tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1")
		return
	fi
	session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) && tmux $change -t "$session" || echo "No sessions found."
}

# DANGER!
#
# This is something that may destroy all the things..
#
# TODO: need to have a way to "undo" the window-option setting and put the old
# title back.. 🤦
#
# 	ssh() {
# 		# start lemonade!
# 		# 		if (command -v lemonade &>/dev/null); then
# 		# 			server_running=$(pgrep -l lemonade)

# 		# 			if ! (echo "$server_running" | rg lemonade); then
# 		# 				# lemonade server &
# 		# 			else
# 		# 				log_warn "lemonade server already running.."
# 		# 			fi
# 		# 		fi

# 		# TODO: get old window name, store it as a local; then be able to rename
# 		# once exiting?
# 		tmux -2u rename-window "$(echo $* | rev | cut -d '@' -f1 | rev)"
# 		command ssh "$@"
# 		tmux -2u set-window-option automatic-rename "on" >/dev/null
# 	}

# # Automatically start tmux on remote server when logging in via SSH
# if [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ]; then
# 	tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
# fi

# # Automatically start tmux on local machine if not running yet
# if [ -z "$SSH_CONNECTION" ] && ! tmux info &> /dev/null; then
#   tmux
# fi
