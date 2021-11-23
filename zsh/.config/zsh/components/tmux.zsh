#!/usr/bin/env zsh

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
		tmux $change -t "$1" 2>/dev/null || (
			tmuxinator start $1 --no-attach && tmux $change -t "$1" && exit
		)
		# tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1")
		return
	fi
	session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height=10% --preview-window=right:0 --exit-0) && tmux $change -t "$session" || echo "No sessions found."
}
