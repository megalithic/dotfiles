#!/usr/bin/env zsh

# zmodload zsh/zprof # -> top of your .zshrc file

# REFS:
# exec - replaces the current shell. This means no subshell is
# created and the current process is replaced with this new command.
# fd/FD - file descriptor
# &- closes a FD e.g. "exec 3<&-" closes FD 3
# file descriptor 0 is stdin (the standard input),
# 1 is stdout (the standard output),
# 2 is stderr (the standard error).

# -- required helpers and our env variables
[ -f "$ZDOTDIR/lib/env.zsh" ] && source "$ZDOTDIR/lib/env.zsh"
[ -f "$ZDOTDIR/lib/helpers.zsh" ] && source "$ZDOTDIR/lib/helpers.zsh"
[ -f "$ZDOTDIR/plugins.zsh" ] && source "$ZDOTDIR/plugins.zsh"

# -- plugins
zsh_add_plugin "Aloxaf/fzf-tab"
zsh_add_plugin "zsh-users/zsh-history-substring-search"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-completions"
zsh_add_plugin "djui/alias-tips"
zsh_add_plugin "MichaelAquilina/zsh-auto-notify" "auto-notify.plugin"
zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"

# adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv # builtin zsh rename command

# -- completions
[ -f "$ZDOTDIR/lib/completion.zsh" ] && source "$ZDOTDIR/lib/completion.zsh"

# -- prompt
[[ -f "$ZDOTDIR/prompt/megaprompt.zsh" && "$(uname)" == "Darwin" ]] && source "$ZDOTDIR/prompt/megaprompt.zsh"

# -- scripts/libs
for file in $ZDOTDIR/lib/{keybindings,opts,aliases,funcs,colors,kitty,ssh,tmux}.zsh; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

if exists zoxide; then
  eval "$(zoxide init zsh)"
fi

if [[ "$(uname)" == "Linux" ]]; then
  exists starship && eval "$(starship init zsh)"
fi

# NOTE: http://asdf-vm.com/learn-more/faq.html#shell-not-detecting-newly-installed-shims
[ -f "$ZDOTDIR/lib/asdf.zsh" ] && source "$ZDOTDIR/lib/asdf.zsh"

# work things
[ -f "/opt/dev-env/ansible/dash_profile" ] && source /opt/dev-env/ansible/dash_profile
[ -n "$DESK_ENV" ] && source "$DESK_ENV" || true

# fzf just desparately wants this here
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -f "$ZDOTDIR/lib/fzf.zsh" ]] && source "$ZDOTDIR/lib/fzf.zsh"

# zprof # -> bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
