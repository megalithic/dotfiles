#!/usr/bin/env zsh

# abort if we're already inside a TMUX session
# [ "$TMUX" == "" ] || exit 0

if [[ -z $TMUX ]]; then
	# 	if [ -n "$TMUX" ]; then
	#
	# present menu for user to choose which workspace to open
	function tm() {
		PS3="Please choose your session: "
		# shellcheck disable=SC2207
		IFS=$'\n' && options=("New Session" $(tmux list-sessions -F "#S" 2>/dev/null))
		echo "Available sessions"
		echo "------------------"
		echo " "
		select opt in "${options[@]}"; do
			case $opt in
				"New Session")
					read -rp "Enter new session name: " SESSION_NAME
					tmux new -s "$SESSION_NAME"
					break
					;;
				*)
					tmux attach-session -t "$opt"
					break
					;;
			esac
		done
	}

	#
	# try and autoload tmux session
	function mux() {
		if [[ $# == 0 ]] && tmux has-session 2>/dev/null; then
			command tmux attach-session
		else
			command tmux "$@"
		fi
	}

	# DANGER!
	#
	# This is something that may destroy all the things..
	#
	# TODO: need to have a way to "undo" the window-option setting and put the old
	# title back.. 🤦
	#
	ssh() {
		# start lemonade!
		# 		if (command -v lemonade &>/dev/null); then
		# 			server_running=$(pgrep -l lemonade)

		# 			if ! (echo "$server_running" | rg lemonade); then
		# 				# lemonade server &
		# 			else
		# 				log_warn "lemonade server already running.."
		# 			fi
		# 		fi

		# TODO: get old window name, store it as a local; then be able to rename
		# once exiting?
		tmux -2u rename-window "$(echo $* | rev | cut -d '@' -f1 | rev)"
		command ssh "$@"
		tmux -2u set-window-option automatic-rename "on" >/dev/null
	}
fi
