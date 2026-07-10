#!/bin/sh
# POSIX sh only — no bashisms; runs on stock macOS before anything is installed.
set -eu

# Human-readable version stamp — bump whenever this script changes so remote
# runs (curl | sh) show which revision they got.
BOOTSTRAP_UPDATED="2026-07-10 09:54 EST"

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
  printf ' updated: %s\n' "$BOOTSTRAP_UPDATED"
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

# nix-homebrew pins Homebrew taps as symlinks into /nix/store. After nix is
# uninstalled (or while it's read-only) those links break `brew update` and
# `brew tap` with 'Permission denied'. Unlink them; brew works API-based
# without any taps and re-clones real ones on demand.
repair_nix_pinned_taps() {
  brew_repo=$(brew --repository 2>/dev/null) || return 0
  [ -n "$brew_repo" ] || return 0
  taps_dir="$brew_repo/Library/Taps"
  for tap_path in "$taps_dir" "$taps_dir"/* "$taps_dir"/*/*; do
    [ -L "$tap_path" ] || continue
    case "$(readlink "$tap_path")" in
    /nix/store/*)
      warn "Removing nix-pinned Homebrew tap link: $tap_path"
      run rm -f "$tap_path"
      ;;
    esac
  done
  [ -d "$taps_dir" ] || run mkdir -p "$taps_dir"
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
  repair_nix_pinned_taps
  info "Refreshing Homebrew formula index (brew update)..."
  if HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 brew update; then
    HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 brew upgrade mise || HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 brew install mise || warn "brew could not upgrade mise."
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

# Unlink a symlink that points into the read-only /nix/store; its parent dir
# is writable even though the target is not.
remove_store_link() {
  [ -L "$1" ] || return 0
  case "$(readlink "$1")" in
  /nix/store/*)
    info "Removing nix-managed symlink: $1"
    run rm -f "$1"
    ;;
  esac
}

# Home Manager leaves symlinks into /nix/store at paths mise manages;
# `mise dotfiles apply --force` tries to rm *through* dir symlinks and dies
# with EACCES in the store. Unlink store symlinks at managed targets (and one
# level inside real dirs, for symlink-each entries) before applying.
clean_nix_managed_targets() {
  [ -d /nix/store ] || return 0
  sed -n '/^\[dotfiles\]/,/^\[/s/^"\(~\/[^"]*\)".*/\1/p' "$DOTFILES_DIR/_mise.toml" |
    while IFS= read -r target; do
      path="$HOME${target#\~}"
      remove_store_link "$path"
      if [ -d "$path" ] && [ ! -L "$path" ]; then
        for entry in "$path"/* "$path"/.[!.]*; do
          remove_store_link "$entry"
        done
      fi
    done
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

# Auto-stash local changes so checkout/pull never abort on a dirty tree.
# Recover later with: git -C ~/.dotfiles stash list / stash pop
stash_dotfiles_changes() {
  [ -n "$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null)" ] || return 0
  warn "$DOTFILES_DIR has local changes; stashing them (recover with 'git stash pop')."
  run git -C "$DOTFILES_DIR" stash push -u -m "bootstrap auto-stash $(date +%Y%m%d-%H%M%S)"
}

pull_dotfiles() {
  stash_dotfiles_changes && ensure_dotfiles_branch && run git -C "$DOTFILES_DIR" pull --ff-only
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
# mise 2026.7.5 launchd apply fails on clean Tahoe VMs with launchctl bootout
# EIO before services converge. Its user step also calls chsh, which prompts
# for a password on macOS. Skip both and handle the login shell below with sudo.
MISE_BOOTSTRAP_FLAGS="--skip launchd --skip user --locked"
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

install_clt_noninteractive() {
  clt_marker="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  run touch "$clt_marker"
  clt_label=$(softwareupdate --list 2>&1 |
    sed -n 's/^[[:space:]]*\* Label: \(Command Line Tools for Xcode.*\)$/\1/p' |
    tail -1)
  if [ -z "$clt_label" ]; then
    run rm -f "$clt_marker"
    die "Could not find Command Line Tools in softwareupdate catalog"
  fi
  info "Installing $clt_label via softwareupdate..."
  if ! run sudo softwareupdate --install "$clt_label" --verbose; then
    run rm -f "$clt_marker"
    die "Command Line Tools install failed"
  fi
  run rm -f "$clt_marker"
  if [ -d /Library/Developer/CommandLineTools ]; then
    run sudo xcode-select --switch /Library/Developer/CommandLineTools
  fi
  xcode-select -p >/dev/null 2>&1 || die "Command Line Tools install did not complete"
}

# CLT first: everything below (brew, git, compilers) depends on it.
if xcode-select -p >/dev/null 2>&1; then
  ok "CLT installed: $(xcode-select -p)"
elif [ "$DRY_RUN" = 1 ]; then
  die "[dry-run] Xcode Command Line Tools required. Run without --dry-run to install via softwareupdate"
else
  info "Command Line Tools not installed; installing now."
  install_clt_noninteractive
  ok "CLT installed: $(xcode-select -p)"
fi

if ! command -v brew >/dev/null 2>&1; then
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would install Homebrew"
  else
    info "Installing Homebrew (needs an administrator password)..."
    id -Gn | grep -qw admin || die "Homebrew install requires an administrator account; $(id -un) is not in the admin group"
    # NONINTERACTIVE installs refuse to prompt for sudo — cache credentials first
    sudo -v || die "sudo authentication failed; Homebrew install needs it"
    NONINTERACTIVE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# heal nix-homebrew leftovers before anything uses brew (cheap, idempotent)
repair_nix_pinned_taps

if ! command -v mise >/dev/null 2>&1; then
  if [ "$DRY_RUN" = 1 ]; then
    die "[dry-run] mise not installed; dry-run needs mise to preview sub-commands"
  fi
  info "Installing mise..."
  HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 brew install mise || install_mise_standalone
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

xcode_license_check=$(xcodebuild -license check 2>&1 || true)
case "$xcode_license_check" in
*"requires Xcode"*"CommandLineTools"*)
  info "Skipping Xcode license check (CLT-only install)."
  ;;
"")
  :
  ;;
*)
  warn "Xcode license not accepted."
  run sudo xcodebuild -license accept
  ok "Xcode license accepted"
  ;;
esac

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
  git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
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

clean_nix_managed_targets

info "Applying dotfiles..."
# shellcheck disable=SC2086 # intentional word-splitting of flag strings
if ! mise dotfiles apply --yes $MISE_DOTFILES_FLAGS; then
  warn "dotfiles apply refused to overwrite existing files."
  say "Re-run with --force to overwrite them, e.g.:"
  # shellcheck disable=SC2016 # literal one-liner for the user to copy
  say '  bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)" -- --force'
  die "dotfiles apply failed"
fi
ok "done applying dotfiles."

MISE_BOOTSTRAP_LOG="${TMPDIR:-/tmp}/bootstrap-mise-$$.log"
MISE_BOOTSTRAP_STATUS="${TMPDIR:-/tmp}/bootstrap-mise-$$.status"

# Run mise bootstrap while capturing output so failures can be inspected.
attempt_mise_bootstrap() {
  # shellcheck disable=SC2086 # intentional word-splitting of flag strings
  # `|| printf` keeps `set -e` from killing the subshell before status is written
  {
    mise bootstrap --yes $MISE_BOOTSTRAP_FLAGS 2>&1 &&
      printf '%s' 0 >"$MISE_BOOTSTRAP_STATUS" ||
      printf '%s' "$?" >"$MISE_BOOTSTRAP_STATUS"
  } | tee "$MISE_BOOTSTRAP_LOG"
  [ "$(cat "$MISE_BOOTSTRAP_STATUS" 2>/dev/null)" = 0 ]
}

# If mise failed renaming an app bundle in /Applications, try moving it aside
# with sudo. This rescues root-owned bundles (previous installer/MDM). It does
# NOT rescue the App Management TCC block — macOS attributes sudo'd commands to
# the spawning terminal, so TCC denies root exactly the same.
sudo_rescue_app_rename() {
  blocked=$(sed -n 's/.*failed rename: \(\/Applications\/[^ ]*\.app\) ->.*/\1/p' "$MISE_BOOTSTRAP_LOG" | head -1)
  [ -n "$blocked" ] || return 1
  [ -e "$blocked" ] || return 1
  warn "mise could not rename $blocked; trying with sudo..."
  if run sudo mv "$blocked" "${blocked%.app}.pre-mise-$(date +%s).app"; then
    ok "Moved aside with sudo (kept as backup); retrying mise bootstrap."
    return 0
  fi
  warn "sudo could not rename it either — that confirms the App Management TCC block (sudo cannot bypass TCC)."
  return 1
}

# mise launchd registration can trip over stale or half-written plists on first
# bootstrap. When bootout fails, remove the stale registration target and retry.
rescue_stuck_launchd_agent() {
  plist=$(sed -n 's/.*launchctl bootout gui\/[0-9][0-9]* \([^`]*\.plist\).*/\1/p' "$MISE_BOOTSTRAP_LOG" | head -1)
  [ -n "$plist" ] || return 1
  label=$(basename "$plist" .plist)
  warn "mise could not bootout stale launchd agent $label; removing stale registration target..."
  run launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  [ ! -e "$plist" ] || run rm -f "$plist"
  ok "Cleared stale launchd agent $label; retrying mise bootstrap."
  return 0
}

# Print failure guidance that matches what actually went wrong, based on the
# captured mise output — only the /Applications permission case is TCC.
explain_mise_bootstrap_failure() {
  if grep -q 'failed rename: /Applications/.*Permission denied\|failed rename: /Applications/' "$MISE_BOOTSTRAP_LOG" 2>/dev/null &&
    grep -q 'Permission denied' "$MISE_BOOTSTRAP_LOG" 2>/dev/null; then
    say "'Permission denied' under /Applications usually means this terminal lacks"
    say "the App Management permission. Opening System Settings at that pane..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles" 2>/dev/null ||
      say "(open System Settings -> Privacy & Security -> App Management manually)"
    say "Enable it for this terminal. IMPORTANT: the grant only applies to a fresh"
    say "terminal process — after toggling, fully quit this terminal app (Cmd+Q),"
    say "reopen it, and re-run this bootstrap; retrying here will fail again."
    say "If no toggle appears (MDM-managed work machine), delete the affected app"
    say "via Finder (drag to Trash), then retry here."
    return 0
  fi
  say "Errors from mise:"
  grep 'ERROR' "$MISE_BOOTSTRAP_LOG" 2>/dev/null | tail -5 | while IFS= read -r line; do
    say "  $line"
  done
  say "Full log: $MISE_BOOTSTRAP_LOG (re-run with MISE_VERBOSE=1 for more)."
  say "Fix the underlying issue, then retry."
}

run_mise_bootstrap() {
  attempt_mise_bootstrap && return 0
  if sudo_rescue_app_rename || rescue_stuck_launchd_agent; then
    attempt_mise_bootstrap && return 0
  fi
  if ! { : </dev/tty; } 2>/dev/null; then
    explain_mise_bootstrap_failure
    die "mise bootstrap failed in non-interactive mode"
  fi
  while :; do
    warn "mise bootstrap failed."
    explain_mise_bootstrap_failure
    say "Options:"
    say "  [r]etry mise bootstrap"
    say "  [c]ontinue without finishing mise bootstrap"
    say "  [a]bort"
    BOOTSTRAP_CHOICE=$(ask_tty "Bootstrap action [r/c/a]:")
    case "$BOOTSTRAP_CHOICE" in
    r | R | retry)
      attempt_mise_bootstrap && return 0
      if sudo_rescue_app_rename || rescue_stuck_launchd_agent; then
        attempt_mise_bootstrap && return 0
      fi
      ;;
    c | C | continue)
      warn "Continuing with mise bootstrap unfinished; re-run bootstrap.sh (or 'mise bootstrap') after fixing permissions."
      return 0
      ;;
    a | A | abort)
      die "mise bootstrap failed"
      ;;
    *)
      warn "Choose r, c, or a."
      ;;
    esac
  done
}

set_login_shell() {
  fish_path="/opt/homebrew/bin/fish"
  [ -x "$fish_path" ] || fish_path="$(command -v fish 2>/dev/null || true)"
  [ -n "$fish_path" ] || die "fish is not installed; cannot set login shell"
  if ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
    info "Adding $fish_path to /etc/shells..."
    printf '%s\n' "$fish_path" | run sudo tee -a /etc/shells >/dev/null
  fi
  current_shell=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')
  if [ "$current_shell" != "$fish_path" ]; then
    info "Setting login shell to $fish_path..."
    run sudo dscl . -change "/Users/$(id -un)" UserShell "$current_shell" "$fish_path"
  fi
  ok "login shell: $fish_path"
}

info "Running mise bootstrap..."
run_mise_bootstrap
ok "done bootstrapping."
set_login_shell

if [ "$DRY_RUN" = 1 ]; then
  info "[dry-run] would run: mise run doctor"
  info "[dry-run] done."
elif mise run doctor; then
  info "Done. Restart your terminal (login shell is now fish)."
else
  warn "Finished, but some of the health checks failed."
  info " Run 'mise run doctor' to investigate."
fi
