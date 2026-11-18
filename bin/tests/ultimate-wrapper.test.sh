#!/usr/bin/env bash
# home/.local/bin/ultimate runs the aube-linked Ultimate with mise's shims last on
# PATH, so its agents' shells find gh even when the caller's PATH lacks it, and
# without the Anthropic auth/backend overrides that block Claude Code subscription.
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

conflicts=(ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_FOUNDRY_API_KEY
  CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY)
printf '%s\n' '#!/bin/sh' 'env | cut -d= -f1' >"$HOME/.local/share/aube/bin/ultimate"
out="$(env "${conflicts[@]/%/=1}" KEEP_ME=1 PATH=/usr/bin:/bin "$WRAPPER")"
for name in "${conflicts[@]}"; do
  ! grep -qx "$name" <<<"$out" || fail "$name reached the child"
done
grep -qx KEEP_ME <<<"$out" || fail "other variables dropped"

echo "ultimate-wrapper: ok"
