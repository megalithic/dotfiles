#!/bin/zsh

echo "### node-specific tasks..."
echo ""

echo ":: installing node packages..."
$DOTS/node/package-installer

if (( $+commands[yarn] )); then
  yarn global add neovim # neovim gets angry when trying to use asdf's shim of neovim-node-host
fi

