#!/usr/bin/env zsh
# shellcheck shell=bash

# zmodload zsh/zprof # top of your .zshrc file

# REF:
# Fix zprofile things: https://spin.atomicobject.com/2021/08/02/zprofile-on-macos/
#   (👆describes some of macos' annoying zprofile handling.)

bindkey -e # ensures we use emacs/readline keybindings

# zcomet for plugin install and management
# if [[ ! -f ${ZDOTDIR:-${HOME}}/.zcomet/bin/zcomet.zsh ]]; then
# 	command git clone https://github.com/agkozak/zcomet.git ${ZDOTDIR:-${HOME}}/.zcomet/bin
# fi
# source ${ZDOTDIR:-${HOME}}/.zcomet/bin/zcomet.zsh
if [[ ! -f $HOME/.zcomet/bin/zcomet.zsh ]]; then
  command git clone https://github.com/agkozak/zcomet.git $HOME/.zcomet/bin
fi

source $HOME/.zcomet/bin/zcomet.zsh
zstyle ':zcomet:*' home-dir $HOME/.zcomet
zstyle ':zcomet:*' repos-dir $HOME/.zcomet/repos
zstyle ':zcomet:*' snippets-dir $HOME/.zcomet/snippets

zcomet load Aloxaf/fzf-tab
zcomet load hlissner/zsh-autopair
zcomet load djui/alias-tips
zcomet load olets/zsh-abbr
zcomet load zsh-users/zsh-completions
zcomet load zsh-users/zsh-history-substring-search
zcomet load zsh-users/zsh-autosuggestions
zcomet load zdharma-zmirror/fast-syntax-highlighting
zcomet load wfxr/emoji-cli
zcomet load wfxr/forgit
zcomet load ohmyzsh plugins/colored-man-pages

if [[ $PLATFORM == "linux" ]]; then
  [[ -d "/home/linuxbrew/.linuxbrew" ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NOTE: source order matters!
for file in $ZDOTDIR/lib/{opts,vimode,fzf,aliases,funcs,colors,keybindings,completion,ssh,tmux}.zsh; do
  # shellcheck disable=SC1090
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

## adds `zmv` tool (https://twitter.com/wesbos/status/1443570300529086467)
autoload -U zmv

# Run compinit and compile its cache
zcomet compinit

# NOTE: http://asdf-vm.com/learn-more/faq.html#shell-not-detecting-newly-installed-shims
[ -f "$ZDOTDIR/lib/asdf.zsh" ] && source "$ZDOTDIR/lib/asdf.zsh"

source /opt/dev-env/ansible/dash_profile
[ -n "$DESK_ENV" ] && source "$DESK_ENV" || true

# zprof # bottom of .zshrc
# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
