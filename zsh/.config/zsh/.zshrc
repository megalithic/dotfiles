#!/usr/bin/env zsh
# shellcheck shell=bash
# zmodload zsh/zprof # top of your .zshrc file

# REF:
# https://spin.atomicobject.com/2021/08/02/zprofile-on-macos/
#   (👆describes some of macos' annoying zprofile handling.)

bindkey -e # ensures we use emacs/readline keybindings

if [[ $PLATFORM == "macos" ]]; then
	source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
	source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ $PLATFORM == "linux" ]]; then
	source "$HOME/builds/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	source "$HOME/builds/zsh-history-substring-search/zsh-history-substring-search.zsh"
	source "$HOME/builds/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# NOTE: source order matters!
for file in $ZDOTDIR/components/{opts,asdf,fzf,aliases,functions,colors,keybindings,completion,ssh,zlua}.zsh; do
	# shellcheck disable=SC1090
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# autoload -U promptinit
# promptinit        # load prompt themes
# prompt megalithic # load my prompt

eval "$(starship init zsh)"

# use .localrc for SUPER SECRET stuff
if [[ -e $HOME/.localrc ]]; then
	source "$HOME/.localrc"
fi

# zprof # bottom of .zshrc
