#!/usr/bin/env bash
# bin/notify against stub notiwatchd and ntfy: arguments pass through as
# values, and ntfy runs only when notiwatchd showed nothing (exit 1).
set -euo pipefail
NOTIFY="$(cd "$(dirname "$0")/.." && pwd)/notify"
tmp="$(realpath "$(mktemp -d)")"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" CALLS="$tmp/calls"
mkdir -p "$HOME/.local/bin" "$HOME/bin"
for stub in .local/bin/notiwatchd bin/ntfy; do
  cat >"$HOME/$stub" <<'EOF'
#!/usr/bin/env bash
printf '%s' "$(basename "$0")" >>"$CALLS"; printf ' <%s>' "$@" >>"$CALLS"; echo >>"$CALLS"
[[ "$(basename "$0")" == notiwatchd ]] && exit "${POST_EXIT:-0}"
exit 0
EOF
  chmod +x "$HOME/$stub"
done

pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  cat "$CALLS" >&2 2>/dev/null || true
  exit 1
}

body='lunch? $(touch pwned) ]] "q"'
"$NOTIFY" -s pi -t '[dots pi] Input needed' -m "$body" -u critical -g pi:dots:1:0 -c tmux:dots:1:0 -a com.example
[[ "$(cat "$CALLS")" == "notiwatchd <post> <--title> <[dots pi] Input needed> <--body> <$body> <--urgency> <critical> <--source> <pi> <--group> <pi:dots:1:0> <--context> <tmux:dots:1:0> <--app> <com.example>" ]] ||
  fail "post arguments"
[[ ! -e pwned && ! -e "$tmp/pwned" ]] || fail "body ran as shell"
ok "every flag reaches notiwatchd post as one argument; shown means no ntfy"

rm -f "$CALLS"
POST_EXIT=1 "$NOTIFY" -s vpn -t T -m B -u high
[[ "$(sed -n 2p "$CALLS")" == "ntfy <send> <-t> <T> <-m> <B> <-u> <high> <-s> <vpn>" ]] || fail "fallback"
rm -f "$CALLS"
POST_EXIT=1 "$NOTIFY" -t T -m B
[[ "$(sed -n 2p "$CALLS")" == "ntfy <send> <-t> <T> <-m> <B> <-u> <normal> <-S>" ]] || fail "fallback without source"
ok "nothing shown (exit 1) falls back to ntfy"

rm -f "$CALLS"
if POST_EXIT=2 "$NOTIFY" -t T -m B 2>/dev/null; then fail "usage error passed"; fi
[[ "$(wc -l <"$CALLS")" -eq 1 ]] || fail "usage error reached ntfy"
if "$NOTIFY" -t T -x y 2>/dev/null; then fail "unknown flag passed"; fi
ok "a usage error exits 2 and never reaches ntfy"

# The real ntfy against a stub hs that records its code and arguments apart.
mkdir -p "$tmp/stubs"
cat >"$tmp/stubs/hs" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == -c && "$3" == -- ]] || exit 9
printf '%s\n' "$2" >>"$CALLS.code"; shift 3; printf ' <%s>' "$@" >>"$CALLS.args"
echo "sent not_paying_attention hud "
EOF
chmod +x "$tmp/stubs/hs"
NTFY="$(dirname "$NOTIFY")/ntfy"
PATH="$tmp/stubs:$PATH" "$NTFY" send -t "$body" -m "$body" -u high -S >/dev/null
PATH="$tmp/stubs:$PATH" "$NTFY" answer -t "$body" -m x >/dev/null
grep -qF "<$body> <$body> <high>" "$CALLS.args" || fail "ntfy args"
! grep -qF 'lunch' "$CALLS.code" || fail "ntfy put a value into Lua"
! grep -q 'notify' "$CALLS.code" || fail "ntfy's Lua posts to Notification Center"
ok "ntfy passes values to hs as arguments, never into Lua or Notification Center"
