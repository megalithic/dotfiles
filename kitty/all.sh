#!/usr/bin/env zsh

echo ""
echo ":: setting up kitty related things"
echo ""

rm -rf "$HOME/.config/kitty"
mkdir -p "$HOME/.config/kitty"

ln -sfv $DOTS/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
