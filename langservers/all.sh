#!/bin/zsh

echo "## LANGSERVERS..."

if [ ! -d "$HOME/.config" ]; then
  mkdir -p $HOME/.config
fi

ln -sfv $DOTS/langservers/efm-langserver $HOME/.config
