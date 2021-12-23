#!/usr/bin/env zsh
# shellcheck shell=bash

# zmodload zsh/zprof # top of your .zshrc file

# REF:
# Fix zprofile things: https://spin.atomicobject.com/2021/08/02/zprofile-on-macos/
#   (👆describes some of macos' annoying zprofile handling.)

bindkey -e # ensures we use emacs/readline keybindings

# use .localrc for SUPER SECRET stuff
if [[ -e $HOME/.localrc ]]; then
	source "$HOME/.localrc"
fi

# zcomet for plugin install and management
if [[ ! -f ${ZDOTDIR:-${HOME}}/.zcomet/bin/zcomet.zsh ]]; then
	command git clone https://github.com/agkozak/zcomet.git ${ZDOTDIR:-${HOME}}/.zcomet/bin
fi
source ${ZDOTDIR:-${HOME}}/.zcomet/bin/zcomet.zsh

# zcomet snippet https://github.com/lincheney/fzf-tab-completion/blob/master/zsh/fzf-zsh-completion.sh
# zcomet load xPMo/zsh-ls-colors
# zcomet load jeffreytse/zsh-vi-mode
# TODO: this instead: https://github.com/jose-elias-alvarez/dotfiles/commit/1b1d725459df1ba1fc62b1bacc510fe8f28b3eaa
zcomet load Aloxaf/fzf-tab
zcomet load djui/alias-tips
zcomet load olets/zsh-abbr
zcomet load zsh-users/zsh-completions
zcomet load zsh-users/zsh-history-substring-search
zcomet load zsh-users/zsh-autosuggestions
zcomet load zdharma-zmirror/fast-syntax-highlighting
zcomet load wfxr/emoji-cli
zcomet load wfxr/forgit
zcomet load ohmyzsh plugins/colored-man-pages
# zcomet load ohmyzsh plugins/mix
# zcomet load ohmyzsh plugins/mix-fast
# zcomet load ohmyzsh plugins/rake
# zcomet load ohmyzsh plugins/rake-fast

if [[ $PLATFORM == "linux" ]]; then
	[[ -d "/home/linuxbrew/.linuxbrew" ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NOTE: source order matters!
for file in $ZDOTDIR/components/{opts,asdf,fzf,aliases,funcs,colors,keybindings,completion,ssh,tmux,zvm}.zsh; do
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

# zprof # bottom of .zshrc
