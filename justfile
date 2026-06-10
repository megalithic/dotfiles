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
  nix run home-manager -- switch --flake ".#$(whoami)@$(hostname -s)" -b backup

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

# Update npm package lockfiles and nix hashes (run before `just home`)
# Usage: just update-npm          (all packages)
#        just update-npm pi-diff  (one package)
update-npm *pkg:
  home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh {{pkg}}

# ===========================================================================
# Primary rebuild commands
# ===========================================================================

# Bootstrap: rebuild without requiring `just` in PATH (use when system is broken)
# Usage: nix run nixpkgs#just -- bootstrap
[macos]
bootstrap:
  #!/usr/bin/env bash
  set -euo pipefail
  export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/system/sw/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
  HOST=$(hostname -s)

  # Restore /run/current-system if missing
  if [ ! -e /run/current-system ]; then
    echo ":: Restoring /run/current-system symlink..."
    sudo ln -sfn /nix/var/nix/profiles/system /run/current-system
  fi

  echo ":: Building darwin configuration..."
  sudo darwin-rebuild switch --flake ".#$HOST"

  echo ":: Building home-manager configuration..."
  nix run home-manager -- switch -b backup --flake ".#$(whoami)@$HOST"

  echo ":: Bootstrap complete."

# Validate: build configs without switching (catches errors before they break things)
# Usage: just validate [darwin|home]  — omit argument to build both
[macos]
validate target="":
  #!/usr/bin/env bash
  set -euo pipefail
  HOST=$(hostname -s)
  TARGET="{{ target }}"
  if [[ -z "$TARGET" || "$TARGET" == "darwin" ]]; then
    echo ":: Building darwin configuration (no switch)..."
    darwin-rebuild build --flake ".#$HOST"
    rm -f result
  fi
  if [[ -z "$TARGET" || "$TARGET" == "home" ]]; then
    echo ":: Building home-manager configuration (no switch)..."
    nix run home-manager -- build --flake ".#$(whoami)@$HOST"
    rm -f result
  fi
  if [[ -n "$TARGET" && "$TARGET" != "darwin" && "$TARGET" != "home" ]]; then
    echo "Error: unknown target '$TARGET'. Use 'darwin', 'home', or omit for both." >&2
    exit 1
  fi
  if [[ -z "$TARGET" ]]; then
    echo ":: ✓ Both configurations build successfully."
  else
    echo ":: ✓ $TARGET configuration builds successfully."
  fi

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
    darwin-rebuild build --flake ".#$HOST" --show-trace -L
    echo ":: Dry run complete. No changes applied."
  else
    echo ":: Running darwin-rebuild switch..."
    sudo darwin-rebuild switch --flake ".#$HOST" --show-trace -L
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
    nix run home-manager -- build --flake ".#$(whoami)@$HOST" --show-trace -L
    echo ":: Dry run complete. No changes applied."
  else
    echo ":: Running home-manager switch..."
    nix run home-manager -- switch --flake ".#$(whoami)@$HOST" --show-trace -L
    pi update --extensions
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
    jj bookmark set main -r main@origin --allow-backwards

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
# Settings sync (app preferences between machines)
# ===========================================================================

# Sync app settings - export to or import from sync directory
# Usage: just sync [export|import|status] [app]
# Examples:
#   just sync              # Show status
#   just sync export       # Export all enabled apps
#   just sync import       # Import all from sync dir
#   just sync export brave-nightly
[macos]
sync *args:
  #!/usr/bin/env bash
  set -euo pipefail

  if ! command -v settings-sync &>/dev/null; then
    echo "Error: settings-sync not found. Run 'just home' first to install it."
    exit 1
  fi

  if [[ -z "${1:-}" ]]; then
    settings-sync status
  else
    settings-sync "$@"
  fi


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


# ===========================================================================
# Security scanning
# ===========================================================================

# Scan the repo for compromising info (secrets, keys, tokens) before pushing.
# Add more checks (PII, deps, SAST, etc.) to this recipe over time.
# Usage: just scan
scan:
  #!/usr/bin/env bash
  set -uo pipefail
  rc=0

  echo ":: gitleaks — scanning git history + working tree for secrets..."
  nix run nixpkgs#gitleaks -- detect --source . --redact --verbose || rc=$?

  if [[ $rc -eq 0 ]]; then
    echo ":: ✓ scan complete — no findings."
  else
    echo ":: ✗ scan found issues (exit $rc) — review output above before pushing." >&2
  fi
  exit $rc

# configure opnix service account token (only unmanaged secret, kept out of Nix store)
# fetches per-host token from 1Password at op://Crypt/opnix/<hostname>/token,
# falls back to interactive `opnix token set` if `op` is missing or unauth'd.
opnix-token:
  #!/usr/bin/env bash
  set -euo pipefail
  config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  token_file="$config_home/opnix/token"
  host="$(hostname -s)"
  op_ref="op://Crypt/opnix/${host}/token"
  mkdir -p "$(dirname "$token_file")"
  if command -v op >/dev/null 2>&1; then
    echo ":: Fetching opnix token from $op_ref"
    if op read "$op_ref" > "$token_file"; then
      chmod 600 "$token_file"
      echo ":: ✓ opnix token installed at $token_file"
      exit 0
    fi
    echo ":: ⚠ op read failed, falling back to interactive entry"
    rm -f "$token_file"
  fi
  opnix token -path "$token_file" set
  chmod 600 "$token_file"

# encrypt plaintext -> secrets/archive/<name>.age (ssh key as recipient)
# output-name optional; defaults to basename of input. ".age" auto-added.
# Usage: just age <path-to-plaintext> [output-name]
age file name="":
  #!/usr/bin/env bash
  set -euo pipefail
  in="{{file}}"
  [[ -f "$in" ]] || { echo ":: ✗ input not found: $in" >&2; exit 1; }
  name="{{name}}"
  [[ -z "$name" ]] && name="$(basename "$in")"
  [[ "$name" == *.age ]] || name="${name}.age"
  out="secrets/archive/$name"
  pub="$HOME/.ssh/id_ed25519.pub"
  [[ -f "$pub" ]] || { echo ":: ✗ missing $pub" >&2; exit 1; }
  mkdir -p "$(dirname "$out")"
  echo ":: Encrypting $in -> $out"
  nix run nixpkgs#age -- -R "$pub" -o "$out" "$in"
  echo ":: ✓ wrote $out"

# decrypt secrets/archive/<name>[.age] with ssh key; accepts bare name or full path
# Usage: just deage <name> [out-path]   (no out-path -> stdout)
deage file out="":
  #!/usr/bin/env bash
  set -euo pipefail
  arg="{{file}}"
  if [[ -f "$arg" ]]; then
    in="$arg"
  else
    base="$arg"
    [[ "$base" == *.age ]] || base="${base}.age"
    in="secrets/archive/$base"
  fi
  [[ -f "$in" ]] || { echo ":: ✗ not found: $in" >&2; exit 1; }
  key="$HOME/.ssh/id_ed25519"
  [[ -f "$key" ]] || { echo ":: ✗ missing $key" >&2; exit 1; }
  out="{{out}}"
  if [[ -n "$out" ]]; then
    echo ":: Decrypting $in -> $out" >&2
    nix run nixpkgs#age -- -d -i "$key" -o "$out" "$in"
  else
    nix run nixpkgs#age -- -d -i "$key" "$in"
  fi
