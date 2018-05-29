#!/bin/zsh

echo "## FISH..."

mkdir -p $HOME/.config
ln -sfv $HOME/.dotfiles/fish $HOME/.config/fish

echo "Installing fisherman..."
# install fisherman (fish plugin manager)
curl -Lo $HOME/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
