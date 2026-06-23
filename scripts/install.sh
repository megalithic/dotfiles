#!/usr/bin/env bash
# megadotfiles — mise-first bootstrap installer.
# Paste into Terminal.app on a fresh or half-configured Mac:
#   curl -sSfL https://raw.githubusercontent.com/megalithic/dotfiles/main/scripts/install.sh | bash
#
# Options:
#   curl ... | bash -s -- --dir ~/custom/path          # custom clone target
#   curl ... | bash -s -- --clone-mode backup           # backup existing dir
#   curl ... | bash -s -- --clone-mode overwrite        # overwrite existing dir
#   curl ... | bash -s -- --clone-mode skip             # skip clone if exists
#   curl ... | bash -s -- --host megabookpro            # skip hostname prompt
#
# Safe to rerun: detects existing state, reports conflicts, asks before mutation.
set -euo pipefail

DOTFILES_REPO="https://github.com/megalithic/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"
CLONE_MODE="" # backup, overwrite, skip (empty = interactive)
FORCE_HOST="" # skip hostname prompt if set

# -- parse args --
while [ $# -gt 0 ]; do
  case "$1" in
  --dir)
    DOTFILES_DIR="${2:-$HOME/.dotfiles}"
    shift 2
    ;;
  --clone-mode)
    CLONE_MODE="${2:-}"
    shift 2
    ;;
  --host)
    FORCE_HOST="${2:-}"
    shift 2
    ;;
  --help | -h)
    echo "Usage: $0 [--dir <path>] [--clone-mode backup|overwrite|skip] [--host <name>]"
    exit 0
    ;;
  *) shift ;;
  esac
done

# -- helpers --
say() { echo "░ :: $*"; }
ok() { echo "░ [✓] $*"; }
warn() { echo "░ [!] $*" >&2; }
header() {
  echo
  echo "░"
  echo "░  ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐"
  echo "░  │││├┤ │ ┬├─┤│  │ │ ├─┤││   mise bootstrap"
  echo "░  ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘"
  echo "░  @megalithic 🗿"
  echo
}

ask() {
  local prompt="$1" default="${2:-}"
  if [ -t 0 ]; then
    read -r -p "░ ?  $prompt " REPLY
    echo "${REPLY:-$default}"
  else
    echo "$default"
  fi
}

confirm() {
  local ans
  ans=$(ask "$1 [y/N] " "n")
  case "$ans" in
  y | Y | yes | YES) return 0 ;;
  *) return 1 ;;
  esac
}

# -- step 1: header and hostname --
header

CURRENT_HOST=$(hostname -s)

HOST=""
if [ -n "$FORCE_HOST" ]; then
  HOST="$FORCE_HOST"
  ok "Host override: $HOST"
elif [ "$CURRENT_HOST" = "megabookpro" ] || [ "$CURRENT_HOST" = "workbookpro" ]; then
  HOST="$CURRENT_HOST"
  ok "Hostname matches known host: $HOST"
else
  warn "Unknown hostname: $CURRENT_HOST"
  say "Known hosts: megabookpro (personal), workbookpro (work)"
  REPLY=$(ask "Which host is this? [megabookpro/workbookpro] " "")
  case "$REPLY" in
  megabookpro | workbookpro) HOST="$REPLY" ;;
  *)
    say "Aborting. Set hostname first or use --host <name>."
    exit 1
    ;;
  esac
fi

# -- step 2: Command Line Tools --
say "Checking Command Line Tools..."
if xcode-select -p &>/dev/null; then
  ok "CLT installed: $(xcode-select -p)"
else
  warn "Command Line Tools not installed."
  say "Installing CLT (this opens a GUI dialog — follow the prompts)..."
  xcode-select --install
  say "Waiting for CLT installation to complete..."
  until xcode-select -p &>/dev/null; do sleep 5; done
  ok "CLT installed"
fi

if ! xcodebuild -license check &>/dev/null 2>&1; then
  warn "Xcode license not accepted."
  sudo xcodebuild -license accept
  ok "Xcode license accepted"
fi

# Rosetta 2 (Apple Silicon only)
if [ "$(uname -m)" = "arm64" ]; then
  if /usr/bin/pgrep -q oahd 2>/dev/null; then
    ok "Rosetta 2 installed"
  else
    say "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license
  fi
fi

# -- step 3: clone or update dotfiles --
say "Dotfiles target: $DOTFILES_DIR"

clone_repo() {
  say "Cloning $DOTFILES_REPO → $DOTFILES_DIR..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

if [ -d "$DOTFILES_DIR/.git" ]; then
  ok "Dotfiles repo found at $DOTFILES_DIR"
  say "Pulling latest changes..."
  git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not fast-forward; manual resolution may be needed"
elif [ -d "$DOTFILES_DIR" ]; then
  warn "$DOTFILES_DIR exists but is not a git repo."

  resolve_mode() {
    case "$CLONE_MODE" in
    backup)
      BACKUP="$DOTFILES_DIR.bak.$(date +%s)"
      say "Backing up to $BACKUP..."
      mv "$DOTFILES_DIR" "$BACKUP"
      clone_repo
      ;;
    overwrite)
      say "Overwriting $DOTFILES_DIR..."
      rm -rf "$DOTFILES_DIR"
      clone_repo
      ;;
    skip)
      warn "Skipping clone (--clone-mode skip). Using existing directory."
      ;;
    *)
      say "Options:"
      say "  [b]ackup  — move existing to $DOTFILES_DIR.bak.<ts> then clone"
      say "  [o]verwrite — delete existing and clone fresh"
      say "  [s]kip     — use existing directory as-is"
      REPLY=$(ask "Backup, overwrite, or skip? [b/o/s] " "")
      case "$REPLY" in
      b | B | backup)
        CLONE_MODE=backup
        resolve_mode
        ;;
      o | O | overwrite)
        CLONE_MODE=overwrite
        resolve_mode
        ;;
      s | S | skip)
        CLONE_MODE=skip
        resolve_mode
        ;;
      *)
        warn "Invalid choice. Aborting."
        exit 1
        ;;
      esac
      ;;
    esac
  }
  resolve_mode
else
  clone_repo
fi
cd "$DOTFILES_DIR" || {
  warn "Could not cd to $DOTFILES_DIR"
  exit 1
}

# -- step 4: preflight --
say "Running preflight checks..."

DOTFILES_PREFLIGHT="$DOTFILES_DIR/scripts/mise/dotfile-preflight"
DOCTOR="$DOTFILES_DIR/scripts/mise/doctor"

if [ -x "$DOTFILES_PREFLIGHT" ]; then
  say "Dotfile classifier (read-only):"
  "$DOTFILES_PREFLIGHT" || warn "Some dotfile targets need attention (see above)"
else
  warn "dotfile-preflight not found — skipping"
fi

if [ -x "$DOCTOR" ]; then
  say "Doctor check:"
  "$DOCTOR" || warn "Doctor found issues (see above)"
fi

# -- step 5: review and confirm --
echo
say "Bootstrap plan for $HOST:"
say "  1. Install Homebrew (if missing)"
say "  2. Install Nix via official nix-installer (if missing)"
say "  3. mise bootstrap — Brew packages, dotfiles, macOS defaults, launchd agents"
say "  4. Post-bootstrap tasks — apps, pi tools, secrets, helium, complex defaults"
say "  5. Set ComputerName/HostName/LocalHostName"

if ! confirm "Proceed with bootstrap?"; then
  say "Aborted. Run again when ready."
  exit 0
fi

# -- step 6: Homebrew + mise --
say "Ensuring Homebrew..."
if [ -x "$DOTFILES_DIR/scripts/mise/ensure-homebrew" ]; then
  "$DOTFILES_DIR/scripts/mise/ensure-homebrew"
else
  warn "ensure-homebrew not found — install manually"
fi

say "Installing mise via Homebrew..."
if command -v mise >/dev/null 2>&1; then
  ok "mise already installed: $(mise --version 2>/dev/null | head -1)"
elif command -v brew >/dev/null 2>&1; then
  brew install mise || warn "brew install mise failed"
else
  warn "Homebrew not available — install mise manually: https://mise.jdx.dev/getting-started.html"
  exit 1
fi

# -- step 7: Nix --
say "Ensuring Nix (official nix-installer)..."
if [ -x "$DOTFILES_DIR/scripts/mise/ensure-determinate-nix" ]; then
  "$DOTFILES_DIR/scripts/mise/ensure-determinate-nix" || warn "Nix install/repair failed; continuing"
fi

# -- step 8: mise bootstrap --
say "Running mise bootstrap..."

MISE_VER=$(mise --version 2>/dev/null | head -1 | awk '{print $2}' || echo "0")
MISE_MIN="2026.6.6"
if [ "$(printf '%s\n' "$MISE_MIN" "$MISE_VER" | sort -V | head -1)" != "$MISE_MIN" ]; then
  warn "mise $MISE_VER is too old (need >= $MISE_MIN). Upgrade: brew upgrade mise"
  exit 1
fi
ok "mise $MISE_VER"

say "mise bootstrap (this may take a while)..."
# Dry-run first to catch obvious issues
if mise bootstrap --dry-run 2>&1 | tail -5; then
  ok "Dry-run looks clean"
else
  warn "Dry-run had issues (see above). Continuing anyway..."
fi

# Real bootstrap — dotfiles will refuse to overwrite fish without --force-dotfiles
# User should have been warned by doctor/dotfile-preflight above.
if confirm "Apply mise bootstrap? This will install packages and link dotfiles."; then
  mise bootstrap --force-dotfiles || warn "mise bootstrap had errors (check output)"
else
  say "Skipping mise bootstrap. Run later: mise bootstrap --force-dotfiles"
fi

# -- step 9: post-bootstrap tasks --
if confirm "Run post-bootstrap tasks (apps, pi tools, secrets, helium)?"; then
  say "Installing apps (brew bundle)..."
  mise run apps:install || warn "apps:install had errors"

  say "Setting up Pi tools..."
  mise run pi:setup || warn "pi:setup had errors"

  say "Rendering fnox secrets (skips if token missing)..."
  mise run fnox:render || warn "fnox:render had errors"

  say "Installing Helium..."
  mise run helium:install || warn "helium:install had errors"

  say "Applying complex macOS defaults..."
  mise run macos:complex-defaults || warn "macos:complex-defaults had errors"
else
  say "Skipping post-bootstrap tasks. Run individually via mise run <task>."
fi

# -- step 10: hostname --
say "Setting macOS hostname to $HOST..."
sudo scutil --set HostName "$HOST" || true
sudo scutil --set LocalHostName "$HOST" || true
sudo scutil --set ComputerName "$HOST" || true
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST" 2>/dev/null || true
ok "Hostname set to $HOST"

# -- step 11: next steps --
echo
ok "Bootstrap complete!"
say "Next steps:"
say "  • Restart your shell: exec fish -l"
say "  • Verify: mise run doctor"
say "  • Set up 1Password service account token: fnox set OP_SERVICE_ACCOUNT_TOKEN --provider age"
say "  • Okta Verify: brew install --cask okta-verify (or: mise run okta:check)"
say "  • Kanata: still Nix-managed — run: just darwin"
say "  • README: $DOTFILES_DIR/README.md"
