#!/usr/bin/env zsh

echo ""
echo ":: setting up terminfo related things"
echo ""

if [[ ! -z $TMUX ]]
then
  tic -o $HOME/.terminfo $HOME/.terminfo/tmux.terminfo
  tic -o $HOME/.terminfo $HOME/.terminfo/tmux-256color.terminfo
fi

tic -o $HOME/.terminfo $HOME/.terminfo/xterm-256color.terminfo

echo ':: veriying italics and standouts work..'
echo `tput sitm`italics`tput ritm` `tput smso`standout`tput rmso`
