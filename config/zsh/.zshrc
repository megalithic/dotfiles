#!/usr/bin/env zsh
# shellcheck shell=bash

# zmodload zsh/zprof # top of your .zshrc file

# REF:
# Fix zprofile things: https://spin.atomicobject.com/2021/08/02/zprofile-on-macos/
#   (👆describes some of macos' annoying zprofile handling.)

# TERMS:
# exec - replaces the current shell. This means no subshell is
# created and the current process is replaced with this new command.
# fd/FD - file descriptor
# &- closes a FD e.g. "exec 3<&-" closes FD 3
# file descriptor 0 is stdin (the standard input),
# 1 is stdout (the standard output),
# 2 is stderr (the standard error).

bindkey -e # ensures we use emacs/readline keybindings

# -- required helpers and our env variables
[ -f "$HOME/.config/zsh/lib/helpers.zsh" ] && source "$HOME/.config/zsh/lib/helpers.zsh"
[ -f "$HOME/.config/zsh/lib/env.zsh" ] && source "$HOME/.config/zsh/lib/env.zsh"
[ -f "$HOME/.config/zsh/plugins.zsh" ] && source "$HOME/.config/zsh/plugins.zsh"

# -- plugins
zsh_add_plugin    "Aloxaf/fzf-tab"
zsh_add_plugin    "zsh-users/zsh-history-substring-search"
zsh_add_plugin    "zdharma-zmirror/fast-syntax-highlighting"
# zsh_add_plugin    "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin    "zsh-users/zsh-autosuggestions"
zsh_add_plugin    "zsh-users/zsh-completions"
zsh_add_plugin    "djui/alias-tips"
zsh_add_plugin    "MichaelAquilina/zsh-auto-notify" "auto-notify.plugin"
zsh_add_plugin    "hlissner/zsh-autopair"

# adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv # builtin zsh rename command

# -- scripts/libs
for file in $ZDOTDIR/lib/{opts,aliases,funcs,colors,keybindings,completion,ssh,tmux}.zsh; do
  # shellcheck disable=SC1090
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

if exists zoxide; then
  eval "$(zoxide init zsh)"
fi

# if exists starship; then
#   eval "$(starship init zsh)"
# fi

source "$ZDOTDIR/prompt/megaprompt"

# Run compinit and compile its cache
# FIXME: compaudit | xargs chmod g-w

# NOTE: http://asdf-vm.com/learn-more/faq.html#shell-not-detecting-newly-installed-shims
[ -f "$ZDOTDIR/lib/asdf.zsh" ] && source "$ZDOTDIR/lib/asdf.zsh"

# work things
[ -f "/opt/dev-env/ansible/dash_profile" ] && source /opt/dev-env/ansible/dash_profile
[ -n "$DESK_ENV" ] && source "$DESK_ENV" || true

# fzf just desparately wants this here
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -f "$HOME/.config/zsh/lib/fzf.zsh" ]] && source "$HOME/.config/zsh/lib/fzf.zsh"

# zprof # bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
