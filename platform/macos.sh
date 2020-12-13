#!/usr/bin/env zsh


# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

BACKUP_FILE="${HOME}/Desktop/defaults-backup.$(date '+%Y%m%d_%H%M%S').plist"
echo "Backing up current macOS X defaults to: ${BACKUP_FILE}"
defaults read > "$BACKUP_FILE"

echo
set -x


echo ""
echo ":: setting up macOS system related things"
echo ""

# ------------------
# great references:
# ------------------
# https://github.com/herrbischoff/awesome-osx-command-line
# https://mths.be/macos
# https://juanitofatas.com/mac (catalina specific things)
# https://github.com/blackrobot/dotfiles/blob/master/setup/setup-macos.sh
# https://www.cultofmac.com/646404/secret-mac-settings/
# ------------------

# COMPUTER_NAME := 'replibook'
# COMPUTER_NAME="replibook"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# handy folders we always use/seem to need
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

# Resolves issue of sleeping draining battery
# REF: https://discussions.apple.com/thread/8368663?answerId=33336883022#33336883022
sudo pmset -b tcpkeepalive 0

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

defaults write NSGlobalDomain com.apple.sound.beep.flash -int 0
defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0

# Allow apps downloaded from "Anywhere"
sudo spctl --master-disable

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# sudo scutil --set ComputerName $COMPUTER_NAME
# sudo scutil --set HostName $COMPUTER_NAME
# sudo scutil --set LocalHostName $COMPUTER_NAME
# sudo defaults write \
#   /Library/Preferences/SystemConfiguration/com.apple.smb.server \
#   NetBIOSName -string $COMPUTER_NAME

# Create symlink for iCloud Drive to ~
ln -sfv ~/Library/Mobile\ Documents/com\~apple\~CloudDocs/ ~/iCloud

# # Save screenshots to the desktop
# if [ ! -d "$HOME/Desktop/screenshots" ]; then
#   mkdir ~/Desktop/screenshots
# fi

# defaults write com.apple.screencapture location -string "${HOME}/Desktop/screenshots"

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
# defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
sudo defaults write bluetoothaudiod "Enable AptX codec" -bool true
sudo defaults write bluetoothaudiod "Enable AAC codec" -bool true

# Trackpad: enable tap to click for this user and for the login screen (1 enabled, 0 disabled)
# defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0

# Enable tap to click
# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.trackpad.forceClick -int 1
defaults write NSGlobalDomain com.apple.trackpad.scaling -int 3

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -int 1

# Disable "Natural" scroll
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Enable 3-finger drag. (Moving with 3 fingers in any window "chrome" moves the window.)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -int 1

# Trackpad: use three finger tap to Look up & data detectors
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2


# Open App from 3rd-party developer
defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool NO

# dock size & autohidden dock
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock autohide -bool true

# autohide menubar (true autohide, false -- don't autohide)
defaults write NSGlobalDomain _HIHideMenuBar -bool false

# mojave sub-pixel font smoothing
# ref: https://www.reddit.com/r/MacOS/comments/9ijy88/font_antialiasing_on_mojave/e6mbs49/
# ref: https://forums.macrumors.com/threads/the-subpixel-aa-debacle-and-font-rendering.2184484/
defaults -currentHost write -globalDomain AppleFontSmoothing -int 2
defaults write -g CGFontRenderingFontSmoothingDisabled -bool false
# ^-- or, `NO`, instead of `false`

# 14 days on ical
defaults write com.apple.iCal n\ days\ of\ week 14

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# "Set a blazingly fast keyboard repeat rate"
defaults write NSGlobalDomain KeyRepeat -float 1.0

# "Set a shorter Delay until key repeat"
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
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -int 0

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# show all hidden files and folders (or is it `true`?)
defaults write com.apple.Finder AppleShowAllFiles YES

# remove all default icons on the dock (for when first setting up)
defaults delete com.apple.dock persistent-apps
defaults delete com.apple.dock persistent-others


##
# Finder
##

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Enable AirDrop over Ethernet and on unsupported Macs running Lion
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes


##
# Safari
##

# Privacy: don’t send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Press Tab to highlight each item on a web page
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Show the full URL in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari’s home page to `about:blank` for faster loading
# defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Hide Safari’s bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Hide Safari’s sidebar in Top Sites
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Enable continuous spellchecking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Disable Java
defaults write com.apple.Safari WebKitJavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false

# Block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false

# Update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true


##
# Terminal & iTerm
##

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
# See: https://security.stackexchange.com/a/47786/8918
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# Disable the annoying line marks
defaults write com.apple.Terminal ShowLineMarks -int 0

# Don’t display the annoying prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false


##
# Time Machine
##

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable local Time Machine backups
# NOTE: Apple removed the ability to set `disablelocal`. Thanks Apple.
# hash tmutil &> /dev/null && sudo tmutil disablelocal


##
# Activity Monitor
##

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0


##
# Text Edit
##

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0
# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4


##
# Disk Utility
##

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true


##
# App Store
##

# Enable the WebKit Developer Tools in the Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Enable Debug Menu in the Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Automatically download apps purchased on other Macs
# defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Allow the App Store to reboot machine on macOS updates
defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

##
# Photos
##

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true


##
# Google Chrome
##

# Disable the all too sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the all too sensitive backswipe on Magic Mouse
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true


set +x
echo

##
# Kill affected applications
##

function app_is_running {
  osascript -so -e "application \"$1\" is running"
}

# function ask {
#   local app compcontext question reply

#   app="$1"
#   compcontext='yn:yes or no:(y n)'
#   question="%BShould ${app} be quit right now?%b"

#   while true ; do
#     vared -e -p "${question} (y/n or <ctrl-c>) " reply
#     case "$reply" in
#       (Y* | y*) return 0 ;;
#       (N* | n*) return 1 ;;
#     esac
#   done
# }

apps_to_restart=(
  "Activity Monitor"
  "Address Book"
  "Calendar"
  "cfprefsd"
  "Contacts"
  "Dock"
  "Finder"
  "Google Chrome"
  "Photos"
  "Safari"
  "SystemUIServer"
)

for app in "${apps_to_restart[@]}"; do
  if [[ "$(app_is_running "${app}")" == "true" ]]; then
    echo "\"${app}\" needs to be restarted."

    # if ( ask "${app}" ); then
      echo "Quitting ${app}"
      killall "${app}" &> /dev/null
    # else
    #   log "Leaving ${app} open"
    # fi

    echo
  fi
done

apps_to_launch=(
"1Password 7"
"Alfred 4"
"Bartender 3"
"BetterTouchTool"
"Brave Browser"
# "Contexts"
"Docker"
# "Dropbox"
"ExpressVPN"
"Fantastical"
"Hammerspoon"
"iStat Menus"
"Karabiner-Elements"
"kitty"
"Witch"
)
for app in "${apps_to_launch[@]}"; do
  if [[ ! "$(app_is_running "${app}")" == "true" ]]; then
    echo "Launching \"${app}\"."

    open /Applications/${app}.app

    # Enable apps at startup
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Hammerspoon.app", hidden:true}' > /dev/null

    echo
  fi
done

apps_to_startup=(
"1Password 7"
"Alfred 4"
"Bartender 3"
"BetterTouchTool"
# "Contexts"
"Docker"
# "Dropbox"
"Fantastical"
"Hammerspoon"
"Hazel"
"iStat Menus"
"Karabiner-Elements"
"Witch"
)
for app in "${apps_to_startup[@]}"; do
    echo "Setting to \"${app}\" to launch at startup."

    # Enable apps at startup
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/${app}.app", hidden:true}' > /dev/null

    echo
done

# Set brave as default browser!
defaults write "com.brave.Browser" ExternalProtocolDialogShowAlwaysOpenCheckbox -bool true


echo "Done. Note that some of these changes require a full logout/restart to take effect."

# TODO:
# - programmatically set keyboard shortcuts for apps: https://github.com/kassio/dotfiles/blob/master/lib/macos/shortcuts
