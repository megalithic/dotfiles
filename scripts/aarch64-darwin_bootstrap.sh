#!/usr/bin/env bash

set -Eueo pipefail

DOTFILES_NAME="dotfiles"
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
sudo -u "$SUDO_USER" -v || exit 1

# Keep-alive: update existing `sudo` time stamp until setup has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# Force non-interactive CLT installation via softwareupdate
install_clt() {
  # Create trigger file that makes softwareupdate list CLT
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

  # Find the CLT package label (try newer format first)
  CLT_LABEL=$(softwareupdate -l 2>&1 |
    grep -E '^\s*\* (Label:|Command Line Tools)' |
    grep -i "command line" |
    sed 's/^[^:]*: //' |
    head -1)

  # Fallback: try older format
  if [[ -z $CLT_LABEL ]]; then
    CLT_LABEL=$(softwareupdate -l 2>&1 |
      grep '\* Command Line' |
      sed 's/^.*\* //' |
      head -1)
  fi

  if [[ -n $CLT_LABEL ]]; then
    echo "░ :: -> Installing: $CLT_LABEL"
    softwareupdate -i "$CLT_LABEL" --verbose
  else
    echo "░ [!] -> CLT not found in softwareupdate, falling back to xcode-select"
    xcode-select --install
    # Wait for GUI install to complete
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
  fi

  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
}

echo "░ :: -> Checking for Xcode CommandLineTools.."
if ! xcode-select -p &>/dev/null; then
  echo "░ :: -> Installing Xcode CommandLineTools for $SUDO_USER.."
  install_clt
  echo "░ :: -> Installing Rosetta 2.."
  softwareupdate --install-rosetta --agree-to-license
fi

# Accept Xcode license if not already accepted (required for git, etc.)
if ! xcodebuild -license check &>/dev/null 2>&1; then
  echo "░ :: -> Accepting Xcode license.."
  sudo xcodebuild -license accept
fi

if [ -d "$DOTFILES_DIR" ]; then
  BACKUP_DIR="$DOTFILES_DIR$(date +%s)"
  echo "░ :: -> Backing up existing $DOTFILES_NAME to $BACKUP_DIR.." &&
    mv "$DOTFILES_DIR" "$BACKUP_DIR"
fi

echo "░ :: -> Cloning $DOTFILES_NAME repo to $DOTFILES_DIR.." &&
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git clone "$DOTFILES_REPO" "$DOTFILES_DIR"

echo "░ :: -> Configuring git hooks.." &&
  git -C "$DOTFILES_DIR" config core.hooksPath .githooks

echo "░ :: -> Running nix-darwin for the first time for $FLAKE.." &&
  (sudo nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --option eval-cache false --flake "$DOTFILES_DIR" &&
    echo "░ [✓] -> Completed installation of $DOTFILES_DIR nix-darwin flake..") || echo "░ [x] -> Errored while installing $DOTFILES_DIR nix-darwin flake.."

# Ensure ~/Applications exists with proper ownership/permissions for home-manager
if [[ ! -d "$HOME/Applications" ]]; then
  echo "░ :: -> Creating ~/Applications directory.."
  mkdir -p "$HOME/Applications"
fi
# Fix ownership if root owns it (can happen during bootstrap)
if [[ "$(stat -f '%Su' "$HOME/Applications")" != "$SUDO_USER" ]]; then
  echo "░ :: -> Fixing ~/Applications ownership.."
  sudo chown "$SUDO_USER:staff" "$HOME/Applications"
fi
chmod 755 "$HOME/Applications"

echo "░ :: -> Provisioning opnix token for $FLAKE.."
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
OPNIX_TOKEN="$XDG_CONFIG_HOME/opnix/token"
OPNIX_OP_REF="op://Crypt/opnix/$FLAKE/token"
mkdir -p "$(dirname "$OPNIX_TOKEN")"

if [[ -f $OPNIX_TOKEN ]]; then
  chmod 600 "$OPNIX_TOKEN"
  echo "░ [✓] -> Existing opnix token found"
elif command -v op &>/dev/null; then
  echo "░      Fetching service account token from $OPNIX_OP_REF"
  if op read "$OPNIX_OP_REF" >"$OPNIX_TOKEN" 2>/dev/null; then
    chmod 600 "$OPNIX_TOKEN"
    echo "░ [✓] -> opnix token installed"
  else
    rm -f "$OPNIX_TOKEN"
    echo "░ [!] -> op read failed for $OPNIX_OP_REF"
    echo "░      Create 1Password item first, then run: just opnix-token"
  fi
else
  echo "░ [!] -> 1Password CLI (op) not found"
  echo "░      Run after bootstrap: just opnix-token && just home"
fi

echo "░ :: -> Running home-manager for the first time for $FLAKE.." &&
  (nix run home-manager/master -- switch --flake "$DOTFILES_DIR" &&
    echo "░ [✓] -> Completed installation of $DOTFILES_DIR home-manager flake..") || echo "░ [x] -> Errored while installing $DOTFILES_DIR home-manager flake.."

echo "░ :: -> Running post-install settings.." &&
  (sudo scutil --set HostName "$FLAKE" &&
    sudo scutil --set LocalHostName "$FLAKE" &&
    sudo scutil --set ComputerName "$FLAKE" &&
    sudo defaults write \
      /Library/Preferences/SystemConfiguration/com.apple.smb.server \
      NetBIOSName -string "$FLAKE") &&
  echo "░ [✓] -> Completed post-install settings" ||
  echo "░ [x] -> Errored post-install settings"
