#!/usr/bin/env zsh

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

# REF:
# - https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout
# - https://github.com/romkatv/zsh4humans

# profile zsh config with the `zshprofile` alias
# [[ $ZPROFILE ]] && zmodload zsh/zprof

fpath=($fpath $ZDOTDIR) # Same directory for user defined config and functions
autoload -Uz compinit; compinit    # `New' completion system
autoload -U promptinit; promptinit # Enable prompt themes
prompt megalithic # my own prompt

# Ensures we use vi-mode keybindings
# bindkey -v

# Ensures we use emacs/readline keybindings
bindkey -e

#
# Executes commands at the start of an interactive session.
#


# NOTE: source order matters!
#
# -- zsh core config
source "$DOTS/zsh/components/env.zsh"
source "$DOTS/zsh/components/aliases.zsh"
source "$DOTS/zsh/components/functions.zsh"
source "$DOTS/zsh/components/colors.zsh"
source "$DOTS/zsh/components/opts.zsh"
source "$DOTS/zsh/components/keybindings.zsh"
source "$DOTS/zsh/components/completion.zsh"

# -- ancillary config
source "$DOTS/zsh/components/git.zsh"
source "$DOTS/zsh/components/tmux.zsh"
source "$DOTS/zsh/components/ssh.zsh"
source "$DOTS/zsh/components/kitty.zsh"

# -- plugin config
source "$DOTS/zsh/components/fzf.zsh"
source "$DOTS/zsh/components/zlua.zsh"
source "$DOTS/zsh/components/asdf.zsh"
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# source "$DOTS/zsh/components/prompt.zsh"

# use .localrc for SUPER SECRET STUFF that you don't
# want in your public, versioned repo.
if [[ -a ~/.localrc ]]
then
  source ~/.localrc
fi

# leave this commented out so fzf won't try to keep adding it on updates
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# [[ $ZPROFILE ]] && zprof
