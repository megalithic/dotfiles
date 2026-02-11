flake := env('FLAKE', justfile_directory())

default:
  @just --list

# update your flake.lock
update-flake:
  #!/usr/bin/env bash
  set -euxo pipefail
  nix flake update
  if git diff --exit-code flake.lock > /dev/null 2>&1; then
    echo "no changes to flake.lock"
  else
    echo "committing flake.lock"
    git add flake.lock
    git commit -m "chore(nix): updates flake.lock"
  fi

# upgrades nix
upgrade-nix:
  sudo --preserve-env=PATH nix run \
     --experimental-features "nix-command flakes" \
     upgrade-nix \

# run nix run home-manager -- switch
hm:
  nix run home-manager -- switch --flake ".#seth@$(hostname -s)" -b backup

news:
  nix run home-manager -- news --flake .


init host=`hostname`:
  #!/usr/bin/env bash
  set -Eueo pipefail

  DOTFILES_DIR="$HOME/.dotfiles"
  SUDO_USER=$(whoami)

  if ! command -v xcode-select >/dev/null; then
    echo ":: Installing xcode.."
    xcode-select --install
    sudo -u "$SUDO_USER" softwareupdate --install-rosetta --agree-to-license
    # sudo -u "$SUDO_USER" xcodebuild -license
  fi

  if [ -z "$DOTFILES_DIR" ]; then
    echo ":: Cloning dotfiles repo to $DOTFILES_DIR.." && \
      git clone https://github.com/megalithic/dotfiles "$DOTFILES_DIR"
  fi

  # if ! command -v brew >/dev/null; then
  #   echo ":: Installing homebrew.." && \
  #     bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # fi

  echo ":: Running nix-darwin for the first time.." && \
    sudo nix --experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-25.11 -- switch --option eval-cache false --flake $DOTFILES_DIR#{{host}} --refresh

  # echo ":: Running home-manager for the first time.." && \
  #   sudo nix --experimental-features 'nix-command flakes' run home-manager/master -- switch --option eval-cache false --flake "$DOTFILES_DIR#$FLAKE" --refresh


# update and upgrade homebrew packages
[macos]
update-brew:
  brew update && brew upgrade

# fix shell files. this happens sometimes with nix-darwin
[macos]
fix-shell-files:
  #!/usr/bin/env bash
  set -euxo pipefail

  sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
  sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
  sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin

# updates brew, flake, and runs home-manager
[macos]
update:
  update-brew update-flake hm

# ===========================================================================
# Primary rebuild commands
# ===========================================================================

# Full rebuild: sync from remote, darwin-rebuild, home-manager switch
# Usage: just rebuild [--dry-run]
[macos]
rebuild dry="":
  #!/usr/bin/env bash
  set -euo pipefail
  echo ":: Syncing from remote..."
  just _sync-main
  just darwin {{dry}} --skip-sync
  just home {{dry}} --skip-sync

# Darwin-only rebuild (system settings, brew, etc.)
# Usage: just darwin [--dry-run] [--skip-sync]
[macos]
darwin *args="":
  #!/usr/bin/env bash
  set -euo pipefail
  
  DRY=""
  SKIP_SYNC=""
  for arg in {{args}}; do
    case "$arg" in
      --dry-run) DRY="--dry-run" ;;
      --skip-sync) SKIP_SYNC="1" ;;
    esac
  done
  
  HOST=$(hostname -s)
  
  if [[ -z "$SKIP_SYNC" ]]; then
    echo ":: Syncing from remote..."
    just _sync-main
  fi
  
  if [[ "$DRY" == "--dry-run" ]]; then
    echo ":: [DRY RUN] Building darwin configuration..."
    darwin-rebuild build --flake ".#$HOST"
    echo ":: Dry run complete. No changes applied."
  else
    echo ":: Running darwin-rebuild switch..."
    sudo darwin-rebuild switch --flake ".#$HOST"
  fi

# Home-manager only rebuild (user packages, dotfiles, no sudo needed)
# Usage: just home [--dry-run] [--skip-sync]
[macos]
home *args="":
  #!/usr/bin/env bash
  set -euo pipefail
  
  DRY=""
  SKIP_SYNC=""
  for arg in {{args}}; do
    case "$arg" in
      --dry-run) DRY="--dry-run" ;;
      --skip-sync) SKIP_SYNC="1" ;;
    esac
  done
  
  HOST=$(hostname -s)
  
  if [[ -z "$SKIP_SYNC" ]]; then
    echo ":: Syncing from remote..."
    just _sync-main
  fi
  
  if [[ "$DRY" == "--dry-run" ]]; then
    echo ":: [DRY RUN] Building home-manager configuration..."
    nix run home-manager -- build --flake ".#seth@$HOST"
    echo ":: Dry run complete. No changes applied."
  else
    echo ":: Running home-manager switch..."
    nix run home-manager -- switch --flake ".#seth@$HOST"
  fi

# ===========================================================================
# Helper recipes (private)
# ===========================================================================

# Sync main bookmark with remote (fetches latest flake.lock from Sunday automation)
[private]
_sync-main:
  #!/usr/bin/env bash
  set -euo pipefail
  
  # Fetch remote updates
  jj git fetch 2>/dev/null || true
  
  # Check if remote main is ahead
  LOCAL_MAIN=$(jj log -r main -T change_id --no-graph 2>/dev/null || echo "")
  REMOTE_MAIN=$(jj log -r 'main@origin' -T change_id --no-graph 2>/dev/null || echo "")
  
  if [[ -n "$REMOTE_MAIN" && "$LOCAL_MAIN" != "$REMOTE_MAIN" ]]; then
    echo ":: Remote main has updates (likely flake.lock from Sunday automation)"
    jj bookmark set main -r main@origin
    
    # Rebase current work onto updated main if we're not on main
    CURRENT=$(jj log -r @ -T 'if(bookmarks, bookmarks, change_id)' --no-graph)
    if [[ "$CURRENT" != "main" ]]; then
      echo ":: Rebasing current work onto updated main..."
      jj rebase -d main 2>/dev/null || echo ":: (already up to date or rebase not needed)"
    fi
    
    ntfy send -t "Nix" -m "Synced flake.lock from remote" 2>/dev/null || true
  else
    echo ":: Already up to date with remote"
  fi

# ===========================================================================
# Legacy recipes (kept for compatibility, use above instead)
# ===========================================================================

[macos]
rebuild-user host=`hostname`:
  just home

[macos]
rebuild-home host=`hostname`:
  just home

[macos]
rebuild-system host=`hostname`:
  just darwin

[macos]
rebuild-fast host=`hostname`:
  just home

[macos]
rebuild-old:
  @echo "WARNING: This may hang on setupLaunchAgents. Use 'just rebuild' instead."
  sudo darwin-rebuild switch --flake ./

[macos]
mac:
  @echo "Deprecated: use 'just darwin' instead"
  just darwin

# initial nix-darwin build
[macos]
build host=`hostname`:
  sudo nix --experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-25.05 -- switch --option eval-cache false --flake {{flake}}#{{host}} --refresh
  # eventually: nh darwin switch ./

# REF: https://docs.determinate.systems/troubleshooting/installation-failed-macos#run-the-uninstaller
[macos]
uninstall:
  sudo /nix/nix-installer uninstall

[macos]
macbuild:
  sudo darwin-rebuild build --flake ./

[macos]
check:
  sudo darwin-rebuild check --flake ./
  # nix flake check --no-allow-import-from-derivation

# apply custom nix config for Determinate Nix (trusted-users, cachix caches, etc.)
[macos]
apply-nix-config:
  #!/usr/bin/env bash
  set -euo pipefail

  SOURCE="{{justfile_directory()}}/nix.custom.conf"
  TARGET="/etc/nix/nix.custom.conf"

  if [[ ! -f "$SOURCE" ]]; then
    echo "Error: $SOURCE not found"
    exit 1
  fi

  echo ":: Copying nix.custom.conf to $TARGET..."
  sudo cp "$SOURCE" "$TARGET"

  echo ":: Restarting nix-daemon..."
  sudo launchctl kickstart -k system/org.nixos.nix-daemon

  echo ":: Verifying trusted-users..."
  if nix show-config | grep -q "trusted-users.*seth"; then
    echo "✓ You are now a trusted user"
  else
    echo "⚠ Warning: trusted-users may not have applied. Check 'nix show-config | grep trusted'"
  fi

# edit an agenix secret file (e.g., just age env-vars.age)
age file:
  #!/usr/bin/env bash
  pushd {{justfile_directory()}}/secrets > /dev/null
  agenix -e {{file}}
  popd > /dev/null
