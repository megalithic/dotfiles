#!/bin/zsh

mkdir -p $HOME/.config/kitty
rm -rf $HOME/.config/kitty

ln -sfv $DOTS/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
