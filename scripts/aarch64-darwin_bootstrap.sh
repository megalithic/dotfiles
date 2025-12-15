#!/usr/bin/env bash

set -Eueo pipefail

DOTFILES_NAME="dotfiles-nix"
DOTFILES_REPO="https://github.com/megalithic/$DOTFILES_NAME"
DOTFILES_DIR="$HOME/.$DOTFILES_NAME"
SUDO_USER=$(whoami)
FLAKE=$(hostname -s)

command cat <<EOF

░
░  ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
░  │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: bits & bobs, dots & things.
░  ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
░  @megalithic 🗿
░
EOF

# gather sudo privileges:
echo "░ :: -> sudo required:"
sudo -u $SUDO_USER -v || exit 1

# Keep-alive: update existing `sudo` time stamp until setup has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

if ! command -v xcode-select >/dev/null 2>&1; then
  echo "░ :: -> Installing Xcode for $SUDO_USER.." &&
    xcode-select --install &&
    sudo softwareupdate --install-rosetta --agree-to-license
fi

if [ -d "$DOTFILES_DIR" ]; then
  BACKUP_DIR="$DOTFILES_DIR$(date +%s)"
  echo "░ :: -> Backing up existing $DOTFILES_NAME to $BACKUP_DIR.." &&
    mv "$DOTFILES_DIR" "$BACKUP_DIR"
fi

echo "░ :: -> Cloning $DOTFILES_NAME repo to $DOTFILES_DIR.." &&
  git clone $DOTFILES_REPO "$DOTFILES_DIR"

echo "░ :: -> Configuring git hooks.." &&
  git -C "$DOTFILES_DIR" config core.hooksPath .githooks

echo "░ :: -> Running nix-darwin for the first time for $FLAKE.." &&
  (sudo nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --option eval-cache false --flake "$DOTFILES_DIR#$FLAKE" &&
    echo "░ [✓] -> Completed installation of $DOTFILES_DIR flake..") || echo "░ [x] -> Errored while installing $DOTFILES_DIR flake.."

echo "░ :: -> Running post-install settings.." &&
  (sudo scutil --set HostName "$FLAKE" &&
    sudo scutil --set LocalHostName "$FLAKE" &&
    sudo scutil --set ComputerName "$FLAKE" &&
    sudo defaults write \
      /Library/Preferences/SystemConfiguration/com.apple.smb.server \
      NetBIOSName -string "$FLAKE") &&
  echo "░ [✓] -> Completed post-install settings" ||
  echo "░ [x] -> Errored post-install settings"
