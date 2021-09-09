#!/usr/bin/env zsh

function refresh_tmux_vars {
	# https://stackoverflow.com/questions/21378569/how-to-auto-update-ssh-agent-environment-variables-when-attaching-to-existing-tm
	# https://chrisdown.name/2013/08/02/fixing-stale-ssh-sockets-in-tmux.html
	# https://blog.testdouble.com/posts/2016-11-18-reconciling-tmux-and-ssh-agent-forwarding/
	# https://werat.dev/blog/happy-ssh-agent-forwarding/
	if [ -n "$TMUX" ]; then
		# eval $(tmux showenv -s | grep -E '^(SSH|DISPLAY)')

		eval $(tmux show-env -s | grep '^(SSH_|DISPLAY|TMUX)')
	fi
}

function preexec {
	refresh_tmux_vars
}

# we're going to update the tmux window title with an icon if we're ssh'd in
if (env | rg starship &>/dev/null); then
	function indicate_ssh_in_tmux() {
		# local -r current_window_title=$(tmux display-message -p '#W')
		# if [[ $(ps -o comm= -p $PPID) == "sshd" ]]; then
		# 	echo "$current_window_title "
		# fi

		# local -r current_title=$(get_tmux_option "@ssh_auto_rename_window" "$ssh_auto_rename_window_default")
		# echo -ne "\033]0; $(basename "$PWD") \007"
		# | awk 'NR%1000==0{system("tmux rename-window -t $TMUX_PANE \""NR/1000"k lines\"")}{print}'
		#
		# echo -ne "\033]0; $(basename "$PWD") \007"
	}
	starship_precmd_user_func="indicate_ssh_in_tmux"
fi

# DANGER!
#
# This is something that may destroy all the things..
#
# TODO: need to have a way to "undo" the window-option setting and put the old
# title back.. 🤦
#
ssh() {
	if [ -n "$TMUX" ]; then
		tmux -2u rename-window "$(echo $* | rev | cut -d '@' -f1 | rev)"
		command ssh "$@"
		tmux -2u set-window-option automatic-rename "on" >/dev/null
	else
		command ssh "$@"
	fi
}
