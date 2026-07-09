#!/bin/sh
# POSIX sh only — no bashisms; runs on stock macOS before anything is installed.
set -eu

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/megalithic/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
FORCE_HOST="${HOST:-}" # desired hostname; skip hostname prompt if set
FORCE=0                # --force: pass force flags to all sub-commands
DRY_RUN=0              # --dry-run: pass dry-run flags to all sub-commands; skip other mutations

COLOR_RESET="$(printf '\033[0m')"
COLOR_BLUE="$(printf '\033[34m')"
COLOR_BOLD_RED="$(printf '\033[1;31m')"
COLOR_BOLD_GREEN="$(printf '\033[1;32m')"
COLOR_ITALIC_YELLOW="$(printf '\033[3;33m')"

# -- helpers --
say() { printf ' :: %s\n' "$*"; }
ok() { printf ' %s[✓]%s %s\n' "$COLOR_BOLD_GREEN" "$COLOR_RESET" "$*"; }
warn() { printf ' %s[!]%s %s\n' "$COLOR_ITALIC_YELLOW" "$COLOR_RESET" "$*" >&2; }
info() { printf ' %s[.]%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$1"; }
die() {
  printf ' %s[✗]%s %s\n' "$COLOR_BOLD_RED" "$COLOR_RESET" "$1" >&2
  exit 1
}

header() {
  printf '\n'
  printf '\n'
  printf ' ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐\n'
  printf ' │││├┤ │ ┬├─┤│  │ │ ├─┤││   dotfiles\n'
  printf ' ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘\n'
  printf '\n'
  printf ' bootstrapping...\n'
  printf '\n'
}

ask() {
  ask_prompt="$1"
  ask_default="${2:-}"
  if [ -t 0 ]; then
    printf ' [?] %s ' "$ask_prompt" >&2
    read -r ask_reply
    printf '%s\n' "${ask_reply:-$ask_default}"
  else
    printf '%s\n' "$ask_default"
  fi
}

confirm() {
  confirm_ans=$(ask "$1 [y/N] " "n")
  case "$confirm_ans" in
  y | Y | yes | YES) return 0 ;;
  *) return 1 ;;
  esac
}

normalize_hostname() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-' | sed 's/--*/-/g;s/^-//;s/-$//'
}

# run a mutating command, or print it in dry-run mode
run() {
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would run: $*"
  else
    "$@"
  fi
}

usage() {
  printf 'usage: bootstrap.sh [--force] [--dry-run] [--host <name>]\n'
  printf '  --force        overwrite conflicting dotfile targets (mise dotfiles apply --force,\n'
  printf '                 mise bootstrap --force-dotfiles)\n'
  printf '  --dry-run, -n  print what would happen; mise sub-commands run in their dry-run modes\n'
  printf '  --host <name>  set macOS hostname and skip prompt\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
  --force) FORCE=1 ;;
  --dry-run | -n) DRY_RUN=1 ;;
  --host)
    shift
    [ $# -gt 0 ] || die "--host requires a value"
    FORCE_HOST="$1"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    die "Unknown argument: $1"
    ;;
  esac
  shift
done

# flags forwarded to mise sub-commands (word-split on purpose; flags contain no spaces)
MISE_DOTFILES_FLAGS=""
MISE_BOOTSTRAP_FLAGS=""
if [ "$FORCE" = 1 ]; then
  MISE_DOTFILES_FLAGS="$MISE_DOTFILES_FLAGS --force"
  MISE_BOOTSTRAP_FLAGS="$MISE_BOOTSTRAP_FLAGS --force-dotfiles"
fi
if [ "$DRY_RUN" = 1 ]; then
  MISE_DOTFILES_FLAGS="$MISE_DOTFILES_FLAGS --dry-run"
  MISE_BOOTSTRAP_FLAGS="$MISE_BOOTSTRAP_FLAGS --dry-run"
fi

header

[ "$(uname -s)" = "Darwin" ] || die "macOS only."
[ "$(id -u)" -ne 0 ] || die "Do not run as root."

xcode-select -p >/dev/null 2>&1 ||
  die "Xcode Command Line Tools required. Run: xcode-select --install"

if ! command -v brew >/dev/null 2>&1; then
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would install Homebrew"
  else
    info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v mise >/dev/null 2>&1; then
  if [ "$DRY_RUN" = 1 ]; then
    die "[dry-run] mise not installed; dry-run needs mise to preview sub-commands"
  fi
  info "Installing mise..."
  brew install mise
fi

# clone_repo() {
#   info "Cloning $DOTFILES_REPO into $DOTFILES_DIR..."
#   mkdir -p "$(dirname "$DOTFILES_DIR")"
#   git clone --recurse-submodules "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
# }
#
# if [ -d "$DOTFILES_DIR/.git" ]; then
#   ok "Dotfiles repo found at $DOTFILES_DIR"
#   say "Pulling latest changes..."
#   git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not fast-forward; manual resolution may be needed"
# elif [ -d "$DOTFILES_DIR" ]; then
#   warn "$DOTFILES_DIR exists but is not a git repo."
#
#   resolve_mode() {
#     case "$CLONE_MODE" in
#     backup)
#       BACKUP="$DOTFILES_DIR.bak.$(date +%s)"
#       say "Backing up to $BACKUP..."
#       mv "$DOTFILES_DIR" "$BACKUP"
#       clone_repo
#       ;;
#     overwrite)
#       say "Overwriting $DOTFILES_DIR..."
#       rm -rf "$DOTFILES_DIR"
#       clone_repo
#       ;;
#     skip)
#       warn "Skipping clone (--clone-mode skip). Using existing directory."
#       ;;
#     *)
#       say "Options:"
#       say "  [b]ackup  — move existing to $DOTFILES_DIR.bak.<ts> then clone"
#       say "  [o]verwrite — delete existing and clone fresh"
#       say "  [s]kip     — use existing directory as-is"
#       REPLY=$(ask "Backup, overwrite, or skip? [b/o/s] " "")
#       case "$REPLY" in
#       b | B | backup)
#         CLONE_MODE=backup
#         resolve_mode
#         ;;
#       o | O | overwrite)
#         CLONE_MODE=overwrite
#         resolve_mode
#         ;;
#       s | S | skip)
#         CLONE_MODE=skip
#         resolve_mode
#         ;;
#       *)
#         warn "Invalid choice. Aborting."
#         exit 1
#         ;;
#       esac
#       ;;
#     esac
#   }
#   resolve_mode
# else
#   clone_repo
# fi
#
# cd "$DOTFILES_DIR" || {
#   warn "Could not cd to $DOTFILES_DIR"
#   exit 1
# }

CURRENT_HOST=$(normalize_hostname "$(uname -n | cut -d. -f1)")
HOST=""
if [ -n "$FORCE_HOST" ]; then
  HOST=$(normalize_hostname "$FORCE_HOST")
  [ -n "$HOST" ] || die "--host cannot be empty after normalization"
  ok "Host override: $HOST"
else
  REPLY=$(ask "Hostname [$CURRENT_HOST]:" "$CURRENT_HOST")
  HOST=$(normalize_hostname "$REPLY")
  [ -n "$HOST" ] || die "Hostname cannot be empty after normalization"
fi

if [ "$HOST" != "$CURRENT_HOST" ]; then
  say "Switching macOS hostname: $CURRENT_HOST -> $HOST"
  run sudo scutil --set ComputerName "$HOST"
  run sudo scutil --set LocalHostName "$HOST"
  run sudo scutil --set HostName "$HOST"
  run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST"
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would set hostname to $HOST"
  else
    ok "Hostname set to $HOST"
  fi
fi

# -- step 2: Command Line Tools --
say "Checking Command Line Tools..."
if xcode-select -p >/dev/null 2>&1; then
  ok "CLT installed: $(xcode-select -p)"
else
  warn "Command Line Tools not installed."
  say "Installing CLT (this opens a GUI dialog — follow the prompts)..."
  xcode-select --install
  say "Waiting for CLT installation to complete..."
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "CLT installed"
fi

if ! xcodebuild -license check >/dev/null 2>&1; then
  warn "Xcode license not accepted."
  run sudo xcodebuild -license accept
  ok "Xcode license accepted"
fi

# Rosetta 2 (Apple Silicon only)
if [ "$(uname -m)" = "arm64" ]; then
  if /usr/bin/pgrep -q oahd 2>/dev/null; then
    ok "Rosetta 2 installed"
  else
    say "Installing Rosetta 2..."
    run softwareupdate --install-rosetta --agree-to-license
  fi
fi

if [ -d "$DOTFILES_DIR/.git" ]; then
  info "Updating $DOTFILES_DIR..."
  run git -C "$DOTFILES_DIR" pull --ff-only || info "Skipped pull (local changes or diverged branch)."
else
  [ "$DRY_RUN" = 1 ] && die "[dry-run] $DOTFILES_DIR is not a clone; dry-run needs an existing checkout"
  info "Cloning into $DOTFILES_DIR..."
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone --recurse-submodules "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
fi

# Pre-apply dotfiles so the global ~/.config/mise/config.toml ([tools]) is in place before
# `mise bootstrap` resolves tools on a first-ever run. Cheap + idempotent — keep it.
# NOTE: plain sequential statements — wrapping these in `cd || { } && { }`
# suppresses `set -e` inside the block, letting mise failures slip through.
cd "$DOTFILES_DIR" || die "Unable to change to $DOTFILES_DIR"

# The staged mise config is named _mise.toml so it stays inactive on
# nix-managed machines; point mise at it explicitly for the bootstrap run.
MISE_OVERRIDE_CONFIG_FILENAMES="_mise.toml"
export MISE_OVERRIDE_CONFIG_FILENAMES

info "Trusting mise config..."
mise trust # needed even in dry-run so mise can read the config

info "Initializing submodules..."
run git -C "$DOTFILES_DIR" submodule update --init
ok "done initializing submodules."

info "Applying dotfiles..."
# shellcheck disable=SC2086 # intentional word-splitting of flag strings
mise dotfiles apply --yes $MISE_DOTFILES_FLAGS
ok "done applying dotfiles."

info "Running mise bootstrap..."
# shellcheck disable=SC2086 # intentional word-splitting of flag strings
mise bootstrap --yes $MISE_BOOTSTRAP_FLAGS
ok "done bootstrapping."

if [ "$DRY_RUN" = 1 ]; then
  info "[dry-run] would run: mise run doctor"
  info "[dry-run] done."
elif mise run doctor; then
  info "Done. Restart your terminal (login shell is now fish)."
else
  warn "Finished, but some of the health checks failed."
  info " Run 'mise run doctor' to investigate."
fi
