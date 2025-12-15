#!/usr/bin/env zsh

# REF: https://github.com/kovidgoyal/kitty/blob/master/shell-integration/zsh/kitty-integration#L3-L22
if [[ -n $KITTY_INSTALLATION_DIR ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

# try and autoload tmux session
function mux() {
	if [[ $# == 0 ]] && tmux has-session 2>/dev/null; then
		command tmux attach-session
	else
		command tmux "$@"
	fi
}
