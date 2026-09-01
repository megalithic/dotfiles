#!/usr/bin/env bash
# smoke-test-macos.sh — post-switch health check for megabookpro's
# nix+mise hybrid setup. Run anytime; read-only. Exits non-zero on failures.
# Born from the 2026-08 nix→mise migration verification set.
#
# Flags:
#   --fast   skip the mise bootstrap converge check (slowest section)
#   --aqua   relaunch in a fresh Ghostty window via LaunchServices. Use from
#            tmux/agent contexts: tmux panes are sandboxed (defaults domains
#            unreadable, /etc writes denied, partial PATH) and produce false
#            failures. Blocks on a fifo until the window finishes, then prints
#            the log and exits with the real result. No tmux involved.
set -uo pipefail

# Pin canonical PATH (mise shims first, like interactive shells) — Ghostty
# --command runs with no shell init and inherits the launcher's env, so an
# inherited partial PATH would produce false ownership failures.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Host-specific mise config: --aqua runs with no shell init, so MISE_ENV
# (normally exported by rc files) must be pinned here too.
export MISE_ENV="${MISE_ENV:-$(hostname -s)}"

LOG=/tmp/smoke-aqua.log
run_bootstrap=1 aqua=0 aqua_run=0
for arg in "$@"; do
  case "$arg" in
  --fast) run_bootstrap=0 ;;
  --aqua) aqua=1 ;;
  --aqua-run) aqua_run=1 ;;
  *)
    echo "usage: $(basename "$0") [--fast] [--aqua]" >&2
    exit 2
    ;;
  esac
done

FIFO=/tmp/smoke-aqua.fifo
if [[ "$aqua" -eq 1 ]]; then
  self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  args="--aqua-run"
  [[ "$run_bootstrap" -eq 0 ]] && args="$args --fast"
  rm -f "$LOG" "$FIFO"
  mkfifo "$FIFO"
  open -na Ghostty --args --command="$self $args"
  rc="$(cat "$FIFO")" # blocks until the aqua run writes its exit code
  rm -f "$FIFO"
  cat "$LOG"
  exit "${rc:-1}"
fi

[[ "$aqua_run" -eq 1 ]] && exec > >(tee "$LOG") 2>&1

pass=0 fail=0 warn=0
ok() {
  printf '  \033[32m✓\033[0m %s\n' "$1"
  pass=$((pass + 1))
}
bad() {
  printf '  \033[31m✗\033[0m %s\n' "$1"
  fail=$((fail + 1))
}
wrn() {
  printf '  \033[33m!\033[0m %s\n' "$1"
  warn=$((warn + 1))
}
hdr() { printf '\n\033[1m%s\033[0m\n' "$1"; }

hdr "macOS defaults"
[[ "$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null)" == "1" ]] && ok "KeyRepeat = 1" || bad "KeyRepeat != 1"
[[ "$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null)" == "15" ]] && ok "InitialKeyRepeat = 15" || bad "InitialKeyRepeat != 15"
[[ "$(defaults read com.apple.screencapture location 2>/dev/null)" == "$HOME/_screenshots" ]] && ok "screencapture → ~/_screenshots" || bad "screencapture location wrong"

hdr "Shell"
[[ "$(dscl . -read "/Users/$USER" UserShell 2>/dev/null)" == *"/opt/homebrew/bin/fish" ]] && ok "login shell = brew fish" || bad "login shell is not /opt/homebrew/bin/fish"
grep -q '^/opt/homebrew/bin/fish$' /etc/shells && ok "/etc/shells has brew fish" || bad "/etc/shells missing brew fish"
grep -q '/nix/store' /etc/shells && bad "/etc/shells still has nix entries" || ok "/etc/shells has no nix entries"

hdr "sudo_local (Touch ID)"
if [[ -f /etc/pam.d/sudo_local && ! -L /etc/pam.d/sudo_local ]]; then
  ok "sudo_local is a real file (not nix symlink)"
  grep -q '/opt/homebrew/lib/pam/pam_reattach.so' /etc/pam.d/sudo_local && ok "pam_reattach = brew copy" || bad "pam_reattach not brew (nix leftover?)"
  grep -q 'pam_tid.so' /etc/pam.d/sudo_local && ok "pam_tid present" || bad "pam_tid missing"
else
  bad "sudo_local missing or still a symlink"
fi

hdr "CLI ownership (mise/brew wins PATH, no nix-profile dupes)"
for tool in gh jq just node direnv; do
  p="$(command -v "$tool" 2>/dev/null || true)"
  case "$p" in
  *mise* | /opt/homebrew/*) ok "$tool → $p" ;;
  *.nix-profile*) bad "$tool still resolves to nix profile: $p" ;;
  "") bad "$tool not found" ;;
  *) wrn "$tool → $p (unexpected owner)" ;;
  esac
done
p="$(command -v op 2>/dev/null || true)"
[[ "$p" == /opt/homebrew/* ]] && ok "op → $p" || bad "op not brew-owned: ${p:-missing}"
[[ -e /usr/local/bin/op ]] && bad "/usr/local/bin/op (nix copy) still exists" || ok "no nix op at /usr/local/bin"

hdr "1Password"
if [[ -d /Applications/1Password.app ]]; then
  owner="$(/usr/bin/stat -f '%Su' /Applications/1Password.app)"
  [[ "$owner" == "$USER" ]] && ok "1Password.app cask-owned (owner $owner)" || bad "1Password.app owner is $owner (nix copy?)"
else
  bad "/Applications/1Password.app missing"
fi
if op whoami >/dev/null 2>&1; then ok "op whoami (signed in)"; else wrn "op whoami failed (app locked or CLI integration off)"; fi
fnox get APPLE_TEAM_ID >/dev/null 2>&1 && ok "fnox secret resolution" || bad "fnox get APPLE_TEAM_ID failed"
sp="$(git config --get gpg.ssh.program 2>/dev/null)"
[[ -x "$sp" ]] && ok "git signer exists: $sp" || bad "git gpg.ssh.program missing/not executable"

hdr "GUI apps (cask owns, HM Apps empty)"
for app in "Brave Browser Nightly" Ghostty Contexts Discord MeetingBar Obsidian "Proton Drive" ProtonVPN ColorSnapper2 "Yubico Authenticator" IINA Inkscape OBS Slack "Tidewave IDE" zoom.us "Okta Verify"; do
  [[ -d "/Applications/$app.app" ]] && ok "/Applications/$app.app" || bad "/Applications/$app.app missing"
done
hm_apps="$(ls "$HOME/Applications/Home Manager Apps/" 2>/dev/null | sort | tr '\n' ' ')"
[[ -z "$hm_apps" ]] && ok "HM Apps empty (all GUI apps cask-owned)" || wrn "HM Apps drifted: $hm_apps"

hdr "Key config symlinks (mise [dotfiles])"
for link in ghostty fish tmux; do
  target="$(readlink "$HOME/.config/$link" 2>/dev/null || true)"
  [[ "$target" == *"/.dotfiles/mise/config/$link" ]] && ok "~/.config/$link → mise" || bad "~/.config/$link not mise-linked (→ ${target:-missing})"
done

hdr "Fonts"
ls "$HOME/Library/Fonts/" 2>/dev/null | grep -q 'FiraCodeNerdFont' && ok "nerd fonts in ~/Library/Fonts (mise)" || bad "mise nerd fonts missing"
ls "/Library/Fonts/Nix Fonts/" 2>/dev/null | grep -qi 'nerd-fonts' && bad "Nix Fonts still ships nerd-fonts" || ok "Nix Fonts free of nerd-fonts"

hdr "launchd (mise agents up, no strays)"
for agent in dev.mise.com.megadots.llama-cpp dev.mise.com.megadots.avwatchd dev.mise.com.megadots.miccheck; do
  if launchctl list "$agent" >/dev/null 2>&1; then ok "$agent loaded"; else bad "$agent not loaded"; fi
done
old_media_label=dev.mise.com.megadots.media-presenced
old_media_plist="$HOME/Library/LaunchAgents/$old_media_label.plist"
old_media_socket="$HOME/.local/state/media-presence/sock"
if launchctl list "$old_media_label" >/dev/null 2>&1 ||
  [[ -e "$old_media_plist" || -S "$old_media_socket" ]] ||
  pgrep -f "$HOME/.dotfiles/bin/media-presenced" >/dev/null 2>&1; then
  bad "stale media-presenced agent/process/socket"
else
  ok "no stale media-presenced agent/process/socket"
fi
avwatch_host="$HOME/Library/Application Support/net.imput.helium/NativeMessagingHosts/com.megadots.avwatchd.json"
if [[ -f "$avwatch_host" ]]; then
  ok "avwatchweb native host installed"
else
  bad "avwatchweb native host missing"
fi
pgrep -q kanata && ok "kanata running" || bad "kanata not running"
pgrep -fq 'Espanso.app.*worker' && ok "espanso worker running" || bad "espanso worker not running"
launchctl list 2>/dev/null | grep -q 'org.nixos.raycast\|com.raycast' && bad "raycast launchd leftovers" || ok "no raycast agents"

hdr "touchid-sudo task idempotency"
out="$(bash "$HOME/.dotfiles/mise/tasks/setup-touchid-sudo" 2>&1)"
[[ "$out" == *"already current"* ]] && ok "setup-touchid-sudo: already current" || wrn "setup-touchid-sudo wants changes: $out"

if [[ "$run_bootstrap" -eq 1 ]]; then
  hdr "mise bootstrap (idempotent converge; --fast skips)"
  blog="$(mktemp)"
  if mise bootstrap >"$blog" 2>&1; then
    ok "mise bootstrap exit 0"
  else
    bad "mise bootstrap failed (log: $blog)"
  fi
  if grep -q 'mise ERROR' "$blog"; then
    bad "mise ERROR lines in bootstrap output (log: $blog)"
  else
    ok "no mise ERROR in bootstrap output"
    rm -f "$blog"
  fi
fi

printf '\n\033[1mResult:\033[0m %d passed, %d failed, %d warnings\n' "$pass" "$fail" "$warn"
rc=$([[ "$fail" -eq 0 ]] && echo 0 || echo 1)

if [[ "$aqua_run" -eq 1 ]]; then
  [[ -p "$FIFO" ]] && echo "$rc" >"$FIFO"
  if [[ "$rc" -ne 0 ]]; then
    echo "failures above — press enter to close"
    read -r
  fi
fi
exit "$rc"
