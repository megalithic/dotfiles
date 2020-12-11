#!/usr/bin/env zsh

echo ""
echo ":: setting up keyboard related things"
echo ""

# Disable Dock icon for Hammerspoon
defaults write org.hammerspoon.Hammerspoon MJShowDockIconKey -bool FALSE

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
# defaults write NSGlobalDomain KeyRepeat -int 1
# defaults write NSGlobalDomain InitialKeyRepeat -int 10

echo ""
echo ":: done! remember to enable accessibility for hammerspoon."
echo ""
