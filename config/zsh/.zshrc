#!/usr/bin/env zsh
# shellcheck shell=bash

# zmodload zsh/zprof # -> top of your .zshrc file

# -- required helpers and our env variables
ZLIB="$ZDOTDIR/lib"
[[ -f "$ZLIB/env.zsh" ]] && source "$ZLIB/env.zsh"
[[ -f "$ZLIB/helpers.zsh" ]] && source "$ZLIB/helpers.zsh"
[[ -f "$ZDOTDIR/plugins.zsh" ]] && source "$ZDOTDIR/plugins.zsh"

# -- plugins
zsh_add_plugin "mafredri/zsh-async" "async.plugin"
zsh_add_plugin "Aloxaf/fzf-tab"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "zsh-users/zsh-history-substring-search"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-completions"
zsh_add_plugin "djui/alias-tips"
# zsh_add_plugin "MichaelAquilina/zsh-auto-notify" "auto-notify.plugin"
zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "psprint/zsh-sweep" # zsh linting

# adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv # builtin zsh rename command

# -- completions
zsh_add_file "lib/completion.zsh"
zsh_add_file "lib/last_working_dir.zsh"

# -- prompt
autoload -U promptinit && promptinit # Enable prompt themes
prompt megalithic                    # Set prompt

# -- scripts/libs/etc
for file in $ZLIB/{nix,keybindings,opts,aliases,funcs,ssh,tmux,kitty,gpg}.zsh; do
  # for funcs: https://github.com/akinsho/dotfiles/commit/01816d72160e96921e2af9bc3f1c52be7d1f1502
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

if exists zoxide; then
  eval "$(zoxide init zsh)"
fi

# NOTE: https://github.com/jdxcode/rtx#rtx-activate
zsh_add_file "lib/rtx.zsh"

# NOTE: http://asdf-vm.com/learn-more/faq.html#shell-not-detecting-newly-installed-shims
# FIXME: some libs (elixir-ls, lulwat?) still require this
# zsh_add_file "lib/asdf.zsh"

# work things
[[ -n "$DESK_ENV" ]] && source "$DESK_ENV" || true

# fzf just desparately wants this here
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
zsh_add_file "lib/fzf.zsh"

# zprof # -> bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
