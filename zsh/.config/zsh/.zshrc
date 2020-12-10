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
source "$ZDOTDIR/zsh/components/env.zsh"
source "$ZDOTDIR/zsh/components/aliases.zsh"
source "$ZDOTDIR/zsh/components/functions.zsh"
source "$ZDOTDIR/zsh/components/colors.zsh"
source "$ZDOTDIR/zsh/components/opts.zsh"
source "$ZDOTDIR/zsh/components/keybindings.zsh"
source "$ZDOTDIR/zsh/components/completion.zsh"

# -- ancillary config
source "$ZDOTDIR/zsh/components/git.zsh"
source "$ZDOTDIR/zsh/components/tmux.zsh"
source "$ZDOTDIR/zsh/components/ssh.zsh"
source "$ZDOTDIR/zsh/components/kitty.zsh"

# -- plugin config
source "$ZDOTDIR/zsh/components/fzf.zsh"
source "$ZDOTDIR/zsh/components/zlua.zsh"
source "$ZDOTDIR/zsh/components/asdf.zsh"
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# source "$ZDOTDIR/zsh/components/prompt.zsh"

# use .localrc for SUPER SECRET STUFF that you don't
# want in your public, versioned repo.
if [[ -a ~/.localrc ]]
then
  source ~/.localrc
fi

# leave this commented out so fzf won't try to keep adding it on updates
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
