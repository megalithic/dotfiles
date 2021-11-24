#!/usr/bin/env zsh

# try and autoload tmux session
function mux() {
	if [[ $# == 0 ]] && tmux has-session 2>/dev/null; then
		command tmux attach-session
	else
		command tmux "$@"
	fi
}
