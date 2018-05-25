#!/usr/bin/env sh

tic -o $HOME/.terminfo $HOME/.dotfiles/terminfo/terminfo.symlink/tmux.terminfo
tic -o $HOME/.terminfo $HOME/.dotfiles/terminfo/terminfo.symlink/tmux-256color.terminfo
tic -o $HOME/.terminfo $HOME/.dotfiles/terminfo/terminfo.symlink/xterm-256color.terminfo

echo 'Veriying italics and standouts work..'
echo `tput sitm`italics`tput ritm` `tput smso`standout`tput rmso`
