#!/usr/bin/env zsh
# shellcheck shell=bash

# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv' should not contain commands that produce output or assume the shell is attached to a tty.
#
# Since .zshenv is always sourced, it often contains exported variables that should be available
# to other programs. For example, $PATH, $EDITOR, and $PAGER are often set in .zshenv.
# Also, you can set $ZDOTDIR in .zshenv to specify an alternative location for the rest of your zsh configuration.

# set our working zsh directory
XDG_CONFIG_HOME=~/.config
ZDOTDIR=$XDG_CONFIG_HOME/zsh

# TODO from https://github.com/dbernheisel/dotfiles/blob/master/.zshenv#L9-L11
# Ensure that a non-login, non-interactive shell has a defined environment.
# if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
#   source "${ZDOTDIR:-$HOME}/.zprofile"
# fi

# REF: https://gist.github.com/junegunn/f4fca918e937e6bf5bad#gistcomment-3484821
function valid() {
	local cmd="${@:-}"
	$cmd >&/dev/null

	# REF: https://access.redhat.com/solutions/196563
	if [[ $? -eq 128 ]]; then
		return
	fi
}

function has() {
	type "$1" &>/dev/null
}

function log_raw {
	printf '%s%s\n%s' $(tput setaf 4) "$*" $(tput sgr 0)
}

function log {
	printf '%s%s\n%s' $(tput setaf 4) "-> $*" $(tput sgr 0)
}

function log_ok {
	printf '%s[%s] %s\n%s' $(tput setaf 2) "$(date '+%x %X')" "-> [✓] $*" $(tput sgr 0)
}

function log_warn {
	printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 3) "$(date '+%x %X')" "-> [!] $*" $(tput sgr 0)
}

function log_error {
	printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 1) "$(date '+%x %X')" "-> [x] $*" $(tput sgr 0)
}

# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
