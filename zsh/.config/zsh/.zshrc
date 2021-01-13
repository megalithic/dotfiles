#!/usr/bin/env zsh
# shellcheck shell=bash

# ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#
#   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
#   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > zshrc
#   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
#   Brought to you by: Seth Messer / @megalithic
#
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#

bindkey -e                          # ensures we use emacs/readline keybindings

if [[ "$PLATFORM" == "macos" ]]; then
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ "$PLATFORM" == "linux" ]]; then
  source "$HOME/builds/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  source "$HOME/builds/zsh-history-substring-search/zsh-history-substring-search.zsh"
  source "$HOME/builds/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# NOTE: source order matters!
for file in $ZDOTDIR/components/{env,aliases,functions,colors,opts,keybindings,completion,git,tmux,ssh,kitty,fzf,zlua,asdf}.zsh; do
  # shellcheck disable=SC1090
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# autoload -Uz compinit; compinit     # load completion system - remove? handled in completion.zsh
autoload -U promptinit; promptinit  # load prompt themes
prompt megalithic                   # load my prompt

# use .localrc for SUPER SECRET stuff
if [[ -a $HOME/.localrc ]]
then
  source "$HOME/.localrc"
fi

# leave this commented out so fzf won't try to keep adding it on updates
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
