#!/usr/bin/env bash
# home/.local/bin/ultimate runs the aube-linked Ultimate with mise's shims last on
# PATH, so its agents' shells find gh even when the caller's PATH lacks it.
set -euo pipefail
WRAPPER="$(cd "$(dirname "$0")/../.." && pwd)/home/.local/bin/ultimate"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp"
shims="$HOME/.local/share/mise/shims"
mkdir -p "$HOME/.local/share/aube/bin" "$shims"
printf '%s\n' '#!/bin/sh' 'echo "$PATH"' 'echo "$*"' >"$HOME/.local/share/aube/bin/ultimate"
chmod +x "$HOME/.local/share/aube/bin/ultimate"
fail() {
  echo "not ok - $1" >&2
  exit 1
}

out="$(PATH=/usr/bin:/bin "$WRAPPER" ~/code/app --no-open)"
[[ "$(sed -n 1p <<<"$out")" == "/usr/bin:/bin:$shims" ]] || fail "shims not appended: $out"
[[ "$(sed -n 2p <<<"$out")" == "$HOME/code/app --no-open" ]] || fail "args: $out"

out="$(PATH="$shims:/usr/bin:/bin" "$WRAPPER")"
[[ "$(sed -n 1p <<<"$out")" == "$shims:/usr/bin:/bin" ]] || fail "shims added twice: $out"

echo "ultimate-wrapper: ok"
