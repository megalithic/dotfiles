#!/usr/bin/env zsh
# shellcheck shell=bash
# zmodload zsh/zprof # top of your .zshrc file

# REF:
# https://spin.atomicobject.com/2021/08/02/zprofile-on-macos/
#   (👆describes some of macos' annoying zprofile handling.)

bindkey -e # ensures we use emacs/readline keybindings

# use .localrc for SUPER SECRET stuff
if [[ -e $HOME/.localrc ]]; then
	source "$HOME/.localrc"
fi

if [[ $PLATFORM == "macos" ]]; then
	source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
	source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ $PLATFORM == "linux" ]]; then
	source "$HOME/builds/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	source "$HOME/builds/zsh-history-substring-search/zsh-history-substring-search.zsh"
	source "$HOME/builds/zsh-autosuggestions/zsh-autosuggestions.zsh"

	[[ -d "/home/linuxbrew/.linuxbrew" ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NOTE: source order matters!
for file in $ZDOTDIR/components/{opts,asdf,fzf,aliases,functions,colors,keybindings,completion,ssh,tmux}.zsh; do
	# shellcheck disable=SC1090
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# autoload -U promptinit
# promptinit        # load prompt themes
# prompt megalithic # load my prompt

# zprof # bottom of .zshrc
