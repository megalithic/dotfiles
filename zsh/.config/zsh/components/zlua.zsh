#!/usr/bin/env zsh

if (command -v lua &>/dev/null); then
	eval "$(lua $DOTS/bin/z.lua --init zsh enhanced once fzf)"
fi
# eval "$(lua $HOME/.dotfiles/bin/z.lua --init zsh)"
