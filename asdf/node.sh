#!/usr/bin/env zsh

echo "### node-specific tasks..."
echo ""

#echo ":: installing node packages..."
#$DOTS/node/package-installer

if (( which yarn &> /dev/null )); then
  echo ""
  echo ":: attempting to forcefully install neovim-node-host"
  yarn global add neovim # neovim gets angry when trying to use asdf's shim of neovim-node-host
else
  echo ":: ERROR: wasn't able to run yarn command from ln 12"
fi

