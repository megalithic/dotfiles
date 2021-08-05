#!/usr/bin/env zsh
# shellcheck shell=bash
# zmodload zsh/zprof # top of your .zshrc file

echo ".zshrc"

bindkey -e # ensures we use emacs/readline keybindings

function log_raw {
	printf '%s%s\n%s' $(tput setaf 4) "$*" $(tput sgr 0)
}

function log {
	printf '%s%s\n%s' $(tput setaf 4) "-> $*" $(tput sgr 0)
}

function log_ok {
	printf '%s[%s] %s\n%s' $(tput setaf 2) "$(date '+%x %X')" "-> [✓] $*" $(tput sgr 0)
}

function log_warn {
	printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 3) "$(date '+%x %X')" "-> [!] $*" $(tput sgr 0)
}

function log_error {
	printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 1) "$(date '+%x %X')" "-> [x] $*" $(tput sgr 0)
}

# source ~/.dotfiles/bin/_helpers.zsh
source "$ZDOTDIR/components/_preload.zsh"

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
for file in $ZDOTDIR/components/{opts,env,asdf,fzf,aliases,functions,colors,keybindings,completion,ssh,zlua}.zsh; do
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
