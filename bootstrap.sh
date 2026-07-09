#!/bin/sh
# POSIX sh only — no bashisms; runs on stock macOS before anything is installed.
set -eu

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/megalithic/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
FORCE_HOST="${HOST:-}" # desired hostname; skip hostname prompt if set
FORCE=0                # --force: pass force flags to all sub-commands
DRY_RUN=0              # --dry-run: pass dry-run flags to all sub-commands; skip other mutations
MIN_MISE_VERSION="2026.6.10"

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

ask_tty() {
  ask_prompt="$1"
  if ! { : </dev/tty; } 2>/dev/null; then
    die "$ask_prompt requires an interactive terminal; pass --host <name> or set HOST=<name>"
  fi
  while :; do
    printf ' [?] %s ' "$ask_prompt" >/dev/tty
    IFS= read -r ask_reply </dev/tty || die "Could not read response from terminal"
    ask_reply=$(printf '%s' "$ask_reply" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$ask_reply" ]; then
      printf '%s\n' "$ask_reply"
      return 0
    fi
    warn "Response required. Type a hostname, e.g. workbookpro."
  done
}

normalize_hostname() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-' | sed 's/--*/-/g;s/^-//;s/-$//'
}

mise_version() {
  mise --version | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+[.][0-9]+[.][0-9]+$/) { print $i; exit } }'
}

version_lt() {
  version_a=$1
  version_b=$2
  IFS=. read -r a_major a_minor a_patch <<EOF
$version_a
EOF
  IFS=. read -r b_major b_minor b_patch <<EOF
$version_b
EOF
  [ "${a_major:-0}" -lt "${b_major:-0}" ] && return 0
  [ "${a_major:-0}" -gt "${b_major:-0}" ] && return 1
  [ "${a_minor:-0}" -lt "${b_minor:-0}" ] && return 0
  [ "${a_minor:-0}" -gt "${b_minor:-0}" ] && return 1
  [ "${a_patch:-0}" -lt "${b_patch:-0}" ]
}

ensure_mise_version() {
  current_mise_version=$(mise_version)
  [ -n "$current_mise_version" ] || die "Unable to determine mise version"
  if version_lt "$current_mise_version" "$MIN_MISE_VERSION"; then
    if [ "$DRY_RUN" = 1 ]; then
      info "[dry-run] mise $current_mise_version is older than $MIN_MISE_VERSION; would upgrade mise"
      die "dry-run cannot preview mise bootstrap with old mise; upgrade mise first or run without --dry-run"
    fi
    info "Upgrading mise ($current_mise_version -> >= $MIN_MISE_VERSION)..."
    brew upgrade mise || brew install mise
  fi
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
ensure_mise_version

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

HOST=""
if [ "$DRY_RUN" = 1 ]; then
  if [ -n "$FORCE_HOST" ]; then
    HOST=$(normalize_hostname "$FORCE_HOST")
    [ -n "$HOST" ] || die "--host cannot be empty after normalization"
    info "[dry-run] would set hostname to $HOST"
    run sudo scutil --set ComputerName "$HOST"
    run sudo scutil --set LocalHostName "$HOST"
    run sudo scutil --set HostName "$HOST"
    run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST"
  else
    info "[dry-run] skipping hostname prompt/change; pass --host <name> to preview hostname change"
  fi
else
  CURRENT_HOST=$(normalize_hostname "$(uname -n | cut -d. -f1)")
  if [ -n "$FORCE_HOST" ]; then
    HOST=$(normalize_hostname "$FORCE_HOST")
    [ -n "$HOST" ] || die "--host cannot be empty after normalization"
    ok "Host override: $HOST"
  else
    REPLY=$(ask_tty "Hostname (current: $CURRENT_HOST; type desired hostname):")
    HOST=$(normalize_hostname "$REPLY")
    [ -n "$HOST" ] || die "Hostname cannot be empty after normalization"
  fi

  if [ "$HOST" != "$CURRENT_HOST" ]; then
    say "Switching macOS hostname: $CURRENT_HOST -> $HOST"
    run sudo scutil --set ComputerName "$HOST"
    run sudo scutil --set LocalHostName "$HOST"
    run sudo scutil --set HostName "$HOST"
    run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST"
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
  if ! run git -C "$DOTFILES_DIR" pull --ff-only; then
    info "Default remote pull failed; retrying via $DOTFILES_REPO_URL without global git config..."
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C "$DOTFILES_DIR" pull --ff-only "$DOTFILES_REPO_URL" HEAD || die "Could not update $DOTFILES_DIR; fix git auth/local changes and retry"
  fi
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
[ -f _mise.toml ] || die "Missing $DOTFILES_DIR/_mise.toml; checkout is stale or incomplete"

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
