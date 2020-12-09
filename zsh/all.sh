#!/usr/bin/env zsh

echo ""
echo ":: setting up zsh related things"
echo ""

echo "-> setting zsh dir symlinks"
ln -sfv $DOTS/zsh $HOME/.zsh
ln -sfv $DOTS/zsh $HOME/.config/
