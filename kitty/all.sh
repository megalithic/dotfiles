#!/bin/zsh

mkdir -p $HOMEDIR/.config/kitty
rm -rf $HOMEDIR/.config/kitty

ln -sfv $DOTS/kitty/kitty.conf $HOMEDIR/.config/kitty/kitty.conf
