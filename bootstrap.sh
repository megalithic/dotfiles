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

ensure_tty() {
  if ! { : </dev/tty; } 2>/dev/null; then
    die "$1 requires an interactive terminal; pass --host <name> or set HOST=<name>"
  fi
}

ask_tty() {
  ask_prompt="$1"
  ensure_tty "$ask_prompt"
  while :; do
    printf ' [?] %s ' "$ask_prompt" >/dev/tty
    IFS= read -r ask_reply </dev/tty || die "Could not read response from terminal"
    ask_reply=$(printf '%s' "$ask_reply" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$ask_reply" ]; then
      printf '%s\n' "$ask_reply"
      return 0
    fi
    warn "Response required."
  done
}

ask_tty_default() {
  ask_prompt="$1"
  ask_default="$2"
  ensure_tty "$ask_prompt"
  printf ' [?] %s ' "$ask_prompt" >/dev/tty
  IFS= read -r ask_reply </dev/tty || die "Could not read response from terminal"
  ask_reply=$(printf '%s' "$ask_reply" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  printf '%s\n' "${ask_reply:-$ask_default}"
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

# Standalone installer works even when Homebrew is nix-managed (taps pinned
# read-only in /nix/store make `brew update`/`brew upgrade` a no-op there).
install_mise_standalone() {
  info "Installing mise to ~/.local/bin via https://mise.run..."
  MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh -c "$(curl -fsSL https://mise.run)" || {
    warn "Standalone mise install failed."
    return 1
  }
  PATH="$HOME/.local/bin:$PATH"
  export PATH
  hash -r 2>/dev/null || true
}

ensure_mise_version() {
  current_mise_version=$(mise_version)
  [ -n "$current_mise_version" ] || die "Unable to determine mise version"
  version_lt "$current_mise_version" "$MIN_MISE_VERSION" || return 0
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] mise $current_mise_version is older than $MIN_MISE_VERSION; would upgrade mise"
    die "dry-run cannot preview mise bootstrap with old mise; upgrade mise first or run without --dry-run"
  fi
  info "Upgrading mise ($current_mise_version -> >= $MIN_MISE_VERSION)..."
  info "Refreshing Homebrew formula index (brew update)..."
  if brew update; then
    brew upgrade mise || brew install mise || warn "brew could not upgrade mise."
  else
    warn "brew update failed (Homebrew may be nix-managed/read-only); skipping brew upgrade."
  fi
  hash -r 2>/dev/null || true
  current_mise_version=$(mise_version)
  if version_lt "$current_mise_version" "$MIN_MISE_VERSION"; then
    warn "Homebrew could not provide mise >= $MIN_MISE_VERSION; falling back to standalone installer."
    install_mise_standalone
    current_mise_version=$(mise_version)
  fi
  if version_lt "$current_mise_version" "$MIN_MISE_VERSION"; then
    die "mise is still $current_mise_version (< $MIN_MISE_VERSION) at $(command -v mise); remove stale mise binaries from PATH and retry."
  fi
  ok "mise $current_mise_version"
}

# run a mutating command, or print it in dry-run mode
run() {
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would run: $*"
  else
    "$@"
  fi
}

dotfiles_default_branch() {
  default_branch=$(git -C "$DOTFILES_DIR" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  printf '%s' "${default_branch:-main}"
}

# `git pull` refuses to run on a detached HEAD; check out the default branch first.
ensure_dotfiles_branch() {
  if git -C "$DOTFILES_DIR" symbolic-ref -q HEAD >/dev/null 2>&1; then
    return 0
  fi
  checkout_branch=$(dotfiles_default_branch)
  warn "$DOTFILES_DIR is on a detached HEAD; checking out $checkout_branch."
  run git -C "$DOTFILES_DIR" checkout "$checkout_branch"
}

pull_dotfiles() {
  ensure_dotfiles_branch && run git -C "$DOTFILES_DIR" pull --ff-only
}

update_dotfiles_checkout() {
  info "Updating $DOTFILES_DIR..."
  if pull_dotfiles; then
    return 0
  fi

  while :; do
    warn "Could not update $DOTFILES_DIR with its configured remote."
    say "If SSH auth needs attention, unlock/fix it now, then retry."
    say "Options:"
    say "  [r]etry configured remote"
    say "  [h]ttps fallback using $DOTFILES_REPO_URL"
    say "  [s]tash local changes, then use HTTPS fallback"
    say "  [a]bort"
    UPDATE_CHOICE=$(ask_tty "Update action [r/h/s/a]:")
    case "$UPDATE_CHOICE" in
    r | R | retry)
      pull_dotfiles && return 0
      ;;
    h | H | https)
      ensure_dotfiles_branch &&
        GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C "$DOTFILES_DIR" pull --ff-only "$DOTFILES_REPO_URL" HEAD && return 0
      ;;
    s | S | stash)
      git -C "$DOTFILES_DIR" stash push -u -m "bootstrap before update $(date +%Y%m%d-%H%M%S)" || warn "Stash failed."
      ensure_dotfiles_branch &&
        GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C "$DOTFILES_DIR" pull --ff-only "$DOTFILES_REPO_URL" HEAD && return 0
      ;;
    a | A | abort)
      die "Could not update $DOTFILES_DIR; fix git auth/local changes and retry"
      ;;
    *)
      warn "Choose r, h, s, or a."
      ;;
    esac
  done
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
  brew install mise || install_mise_standalone
  command -v mise >/dev/null 2>&1 || die "mise installation failed"
fi
ensure_mise_version

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
    REPLY=$(ask_tty_default "Hostname [$CURRENT_HOST]:" "$CURRENT_HOST")
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
  update_dotfiles_checkout
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
