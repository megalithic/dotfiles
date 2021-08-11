#!/usr/bin/env zsh
# shellcheck shell=bash
# zmodload zsh/zprof # top of your .zshrc file

bindkey -e # ensures we use emacs/readline keybindings

if [[ -e $HOME/.znap/znap.zsh ]]; then
	zstyle ':znap:*' repos-dir ~/.znap/plugins
	source $HOME/.znap/znap.zsh
fi

# `znap source` automatically downloads and installs your plugins.
znap source marlonrichert/zsh-autocomplete
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
znap source zsh-users/zsh-history-substring-search

# NOTE: source order matters!
for file in $ZDOTDIR/components/{opts,asdf,fzf,aliases,functions,colors,keybindings,completion,ssh,zlua}.zsh; do
	# shellcheck disable=SC1090
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

autoload -U promptinit
promptinit        # load prompt themes
prompt megalithic # load my prompt

# use .localrc for SUPER SECRET stuff
if [[ -e $HOME/.localrc ]]; then
	source "$HOME/.localrc"
fi

# leave this commented out so fzf won't try to keep adding it on updates
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zprof # bottom of .zshrc
