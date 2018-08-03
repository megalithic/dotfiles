#!/bin/zsh

echo "### node-specific tasks..."
echo ""

echo "Installing node packages..."
$DOTS/node/package-installer

# echo "Setting up `avn` (automatic node version loader)..."
# [[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh" # source avn
# avn setup
