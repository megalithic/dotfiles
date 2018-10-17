#!/usr/bin/env zsh

echo ""
echo ":: setting up terminfo related things"
echo ""

tic -o $HOME/.terminfo $HOME/.dotfiles/terminfo/terminfo.symlink/tmux.terminfo
tic -o $HOME/.terminfo $HOME/.dotfiles/terminfo/terminfo.symlink/tmux-256color.terminfo
tic -o $HOME/.terminfo $HOME/.dotfiles/terminfo/terminfo.symlink/xterm-256color.terminfo

echo ':: veriying italics and standouts work..'
echo `tput sitm`italics`tput ritm` `tput smso`standout`tput rmso`
