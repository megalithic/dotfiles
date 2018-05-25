#!/usr/bin/env bash

# ------------------
# great reference:
# https://github.com/herrbischoff/awesome-osx-command-line
# https://mths.be/macos
# ------------------

# COMPUTER_NAME := 'replibook'
COMPUTER_NAME="replibook"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# get password up front
sudo -v

if [ ! -d "$HOME/code" ]; then
  mkdir -p $HOME/code
fi

if [ ! -d "$HOME/tmp" ]; then
  mkdir -p $HOME/tmp
fi

# Keep-alive: update existing `sudo` time stamp until `osx/osx.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Set standby delay to 24 hours (default is 1 hour)
# sudo pmset -a standbydelay 86400

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Allow apps downloaded from "Anywhere"
sudo spctl --master-disable

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# See secrets.blacktree.com
chsh -s /usr/local/bin/zsh $USER

sudo scutil --set ComputerName $COMPUTER_NAME
sudo scutil --set HostName $COMPUTER_NAME
sudo scutil --set LocalHostName $COMPUTER_NAME
sudo defaults write \
  /Library/Preferences/SystemConfiguration/com.apple.smb.server \
  NetBIOSName -string $COMPUTER_NAME

# Save screenshots to the desktop
if [ ! -d "$HOME/Desktop/screenshots" ]; then
  mkdir ~/Desktop/screenshots
fi

defaults write com.apple.screencapture location -string "${HOME}/Desktop/screenshots"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)"
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# no .DS_Store on network
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Finder
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Downloads/"

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Trackpad: enable tap to click for this user and for the login screen (1 enabled, 0 disabled)
# defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0

defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# PRE-SIERRA:
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable "Natural" scroll
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
# Enable move with 3 fingers
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# dock size & autohidden dock
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock autohide -bool true

# 14 days on ical
defaults write com.apple.iCal n\ days\ of\ week 14

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a blazingly fast keyboard repeat rate
# ref: https://ksearch.wordpress.com/2017/06/20/increase-the-key-repeat-rate-in-os-x-sierra/
# --
# Reset to defaults (https://coderwall.com/p/jzuuzg/osx-set-fast-keyboard-repeat-rate):
# defaults delete NSGlobalDomain KeyRepeat
# defaults delete NSGlobalDomain InitialKeyRepeat
# --
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false

# scrollbars on always!
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# expand save/print dialogs by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# remove all default icons on the dock (for when first setting up)
defaults delete com.apple.dock persistent-apps
defaults delete com.apple.dock persistent-others
killall Dock

# unhide Library folder!
chflags nohidden ~/Library/
