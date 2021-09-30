#!/usr/bin/env zsh
# shellcheck shell=bash
#
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

#ft=zsh:foldenable:foldmethod=marker:ft=zsh;ts=2;sts=2;sw=2
