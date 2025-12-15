#!/usr/bin/env zsh
# shellcheck shell=bash
# zmodload zsh/zprof # -> top of your .zshrc file

# set -o vi
# set -o emacs

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
# zsh_add_plugin "megalithic/zsh-magic-dashboard" "magic_dashboard"
# zsh_add_plugin "MichaelAquilina/zsh-auto-notify" "auto-notify.plugin"
zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "psprint/zsh-sweep" # zsh linting
zsh_add_plugin "ptavares/zsh-direnv"
# zsh_add_plugin "lewis6991/fancy-prompt"

# adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv # builtin zsh rename command

# -- completions
zsh_add_file "lib/completion.zsh"
zsh_add_file "lib/last_working_dir.zsh"

# -- scripts/libs/etc
for file in $ZLIB/{keymaps,opts,aliases,funcs,ssh,tmux,kitty,gpg}.zsh; do
  # for funcs: https://github.com/akinsho/dotfiles/commit/01816d72160e96921e2af9bc3f1c52be7d1f1502
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

if exists zoxide; then
  eval "$(zoxide init zsh)"
fi

# fzf just desparately wants this here
zsh_add_file "lib/fzf.zsh"

# NOTE: https://github.com/jdxcode/rtx#rtx-activate
zsh_add_file "lib/mise.zsh"
zsh_add_file "lib/nix.zsh"

# -- prompt
# if exists starship; then
#
  bindkey -v # enables vi mode, using -e = emacs
  export KEYTIMEOUT=1

  # Add vi-mode text objects e.g. da" ca(
  autoload -Uz select-bracketed select-quoted
  zle -N select-quoted
  zle -N select-bracketed
  for km in viopp visual; do
    bindkey -M $km -- '-' vi-up-line-or-history
    for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
      bindkey -M $km $c select-quoted
    done
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
      bindkey -M $km $c select-bracketed
    done
  done

  # Mimic tpope's vim-surround
  autoload -Uz surround
  zle -N delete-surround surround
  zle -N add-surround surround
  zle -N change-surround surround
  bindkey -M vicmd cs change-surround
  bindkey -M vicmd ds delete-surround
  bindkey -M vicmd ys add-surround
  bindkey -M visual S add-surround

  cursor_mode() {
    # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
    cursor_block='\e[2 q'
    cursor_beam='\e[6 q'

    function zle-keymap-select {
      vim_mode="${${KEYMAP/vicmd/${vim_normal_mode}}/(main|viins)/${vim_insert_mode}}"
      zle && zle reset-prompt

      if [[ ${KEYMAP} == vicmd ]] ||
      [[ $1 = 'block' ]]; then
        echo -ne $cursor_block
      elif [[ ${KEYMAP} == main ]] ||
      [[ ${KEYMAP} == viins ]] ||
      [[ ${KEYMAP} = '' ]] ||
      [[ $1 = 'beam' ]]; then
        echo -ne $cursor_beam
      fi
    }

    zle-line-init() {
      echo -ne $cursor_beam
    }

    zle -N zle-keymap-select
    zle -N zle-line-init
  }

  cursor_mode

  eval "$(starship init zsh)"

# else
#   autoload -U promptinit && promptinit # Enable prompt themes
#   prompt megalithic                    # Set custom megalithic prompt
# fi

# replaces ctrl_r keybinding for faster, more robust history search
# zsh_add_file "lib/mcfly.zsh"

# zprof # -> bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
