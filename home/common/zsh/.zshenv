#!/usr/bin/env zsh
# shellcheck shell=bash

export ZDOTDIR="$HOME/.config/zsh"

# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv' should not contain commands that produce output or assume the shell is attached to a tty.
#
# Since .zshenv is always sourced, it often contains exported variables that should be available
# to other programs. For example, $PATH, $EDITOR, and $PAGER are often set in .zshenv.
# Also, you can set $ZDOTDIR in .zshenv to specify an alternative location for the rest of your zsh configuration.

# set our working zsh directory
# XDG_CONFIG_HOME="$HOME/.config"
# XDG_CACHE_HOME="$HOME/.cache"
# XDG_DATA_HOME="$HOME/.local/share"

# ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

# if [ ! -d "$ZSH_CACHE_DIR" ]; then
# 	mkdir -p "$ZSH_CACHE_DIR"
# fi

# TODO from https://github.com/dbernheisel/dotfiles/blob/master/.zshenv#L9-L11
# Ensure that a non-login, non-interactive shell has a defined environment.
# if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
#   source "${ZDOTDIR:-$HOME}/.zprofile"
# fi

# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
#
#
