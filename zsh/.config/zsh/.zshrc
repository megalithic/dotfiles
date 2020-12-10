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

fpath=($fpath $ZDOTDIR) # Same directory for user defined config and functions
autoload -Uz compinit; compinit    # `New' completion system
autoload -U promptinit; promptinit # Enable prompt themes
prompt megalithic # my own prompt

# Ensures we use emacs/readline keybindings
bindkey -e

echo $ZDOTDIR

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
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# source "$ZDOTDIR/components/prompt.zsh"

# use .localrc for SUPER SECRET STUFF that you don't
# want in your public, versioned repo.
if [[ -a ~/.localrc ]]
then
  source ~/.localrc
fi

# leave this commented out so fzf won't try to keep adding it on updates
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
