#!/usr/bin/env zsh
# shellcheck shell=bash

# ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#
#   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
#   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > zsh/zshrc.symlink
#   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
#   Brought to you by: Seth Messer / @megalithic
#
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#

fpath=($fpath $ZDOTDIR) # Same directory for user defined config and functions
autoload -Uz compinit; compinit    # `New' completion system
autoload -U promptinit; promptinit # Enable prompt themes

prompt megalithic

# Ensures we use emacs/readline keybindings
bindkey -e

# NOTE: source order matters!
#
# -- zsh core config
source "$ZDOTDIR/components/env.zsh"
source "$ZDOTDIR/components/aliases.zsh"
source "$ZDOTDIR/components/functions.zsh"
source "$ZDOTDIR/components/colors.zsh"
source "$ZDOTDIR/components/opts.zsh"
source "$ZDOTDIR/components/keybindings.zsh"
source "$ZDOTDIR/components/completion.zsh"

# -- ancillary config
source "$ZDOTDIR/components/git.zsh"
source "$ZDOTDIR/components/tmux.zsh"
source "$ZDOTDIR/components/ssh.zsh"
source "$ZDOTDIR/components/kitty.zsh"

# -- plugin config
source "$ZDOTDIR/components/fzf.zsh"
source "$ZDOTDIR/components/zlua.zsh"
source "$ZDOTDIR/components/asdf.zsh"

# for file in ~/.{prompt,zsh_aliases,exports,extra}; do
#   # shellcheck disable=SC1090
#   [ -r "$file" ] && [ -f "$file" ] && source "$file"
# done
# unset file

if [[ "$(uname)" == "Darwin" ]]; then
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
  source "$HOME/builds/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  source "$HOME/builds/zsh-history-substring-search/zsh-history-substring-search.zsh"
  source "$HOME/builds/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# source "$ZDOTDIR/components/prompt.zsh"

# use .localrc for SUPER SECRET STUFF that you don't
# want in your public, versioned repo.
if [[ -a $HOME/.localrc ]]
then
  source "$HOME/.localrc"
fi

# leave this commented out so fzf won't try to keep adding it on updates
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
