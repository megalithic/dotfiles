#!/bin/sh

echo "does keyboard things"

set -e

# Prepare custom settings for Karabiner-Elements
# https://github.com/tekezo/Karabiner-Elements/issues/597#issuecomment-282760186
ln -sfvn ~/.dotfiles/keyboard/karabiner ~/.config

# Disable Dock icon for Hammerspoon
defaults write org.hammerspoon.Hammerspoon MJShowDockIconKey -bool FALSE

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
# defaults write NSGlobalDomain KeyRepeat -int 1
# defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Open Apps
open /Applications/Hammerspoon.app
open /Applications/Karabiner-Elements.app

# Enable apps at startup
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Hammerspoon.app", hidden:true}' > /dev/null
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Karabiner-Elements.app", hidden:true}' > /dev/null

echo "Done! Remember to enable Accessibility for Hammerspoon."
