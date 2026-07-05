#!/bin/sh
# POSIX sh only — no bashisms; runs on stock macOS before anything is installed.
set -eu

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/megalithic/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

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
    printf ' [?] %s ' "$ask_prompt"
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

# -- step 1: header and hostname --
header

# CURRENT_HOST=$(uname -n | cut -d. -f1)

[ "$(uname -s)" = "Darwin" ] || die "macOS only."
[ "$(id -u)" -ne 0 ] || die "Do not run as root."

xcode-select -p >/dev/null 2>&1 ||
  die "Xcode Command Line Tools required. Run: xcode-select --install"

if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v mise >/dev/null 2>&1; then
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

if [ -d "$DOTFILES_DIR/.git" ]; then
  info "Updating $DOTFILES_DIR..."
  git -C "$DOTFILES_DIR" pull --ff-only || info "Skipped pull (local changes or diverged branch)."
else
  info "Cloning into $DOTFILES_DIR..."
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone --recurse-submodules "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
fi

# Pre-apply dotfiles so the global ~/.config/mise/config.toml ([tools]) is in place before
# `mise bootstrap` resolves tools on a first-ever run. Cheap + idempotent — keep it.
cd "$DOTFILES_DIR" || {
  warn "Unable to change to $DOTFILES_DIR"
  exit 1
} && {
  info "Trusting mise config..."
  mise trust

  info "Initializing submodules..."
  git -C "$DOTFILES_DIR" submodule update --init && ok "done initializing submodules."

  info "Applying dotfiles..."
  mise dotfiles apply --yes && ok "done applying dotfiles."

  info "Running mise bootstrap..."
  mise bootstrap --yes && ok "done bootstrapping."

  # --- verify ----------------------------
  info "Running health checks..."

  if mise run doctor; then
    info "Done. Restart your terminal (login shell is now fish)."
  else
    warn "Finished, but some of the health checks failed."
    info " Run 'mise run doctor' to investigate."
  fi
}
