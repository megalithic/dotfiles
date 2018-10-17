#!/usr/bin/env zsh

rm -rf "$HOME/.config/kitty"
mkdir -p "$HOME/.config/kitty"

ln -sfv $DOTS/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
