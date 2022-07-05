#!/usr/bin/env zsh

# zmodload zsh/zprof # -> top of your .zshrc file

# -- required helpers and our env variables
ZLIB="$ZDOTDIR/lib"
[[ -f "$ZLIB/env.zsh" ]] && source "$ZLIB/env.zsh"
[[ -f "$ZLIB/helpers.zsh" ]] && source "$ZLIB/helpers.zsh"
[[ -f "$ZDOTDIR/plugins.zsh" ]] && source "$ZDOTDIR/plugins.zsh"

# -- plugins
zsh_add_plugin "Aloxaf/fzf-tab"
zsh_add_plugin "zsh-users/zsh-history-substring-search"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-completions"
zsh_add_plugin "djui/alias-tips"
zsh_add_plugin "MichaelAquilina/zsh-auto-notify" "auto-notify.plugin"
# zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"

# adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv # builtin zsh rename command

# -- completions
[[ -f "$ZLIB/completion.zsh" ]] && source "$ZLIB/completion.zsh"

# -- prompt
[[ -f "$ZDOTDIR/prompt/megaprompt.zsh" ]] && source "$ZDOTDIR/prompt/megaprompt.zsh"

# -- scripts/libs/etc
for file in $ZLIB/{keybindings,opts,aliases,funcs,ssh,tmux,kitty,gpg}.zsh; do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

if exists zoxide; then
  eval "$(zoxide init zsh)"
fi

# NOTE: http://asdf-vm.com/learn-more/faq.html#shell-not-detecting-newly-installed-shims
[[ -f "$ZLIB/asdf.zsh" ]] && source "$ZLIB/asdf.zsh"

# work things
[[ -f "/opt/dev-env/ansible/dash_profile" ]] && source /opt/dev-env/ansible/dash_profile
[[ -n "$DESK_ENV" ]] && source "$DESK_ENV" || true

# fzf just desparately wants this here
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f "$ZLIB/fzf.zsh" ]] && source "$ZLIB/fzf.zsh"

# zprof # -> bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
