#!/usr/bin/env bash
# ultimate-hub-launchd: waits while another live process serves the hub, then
# starts it on its port without a window. mise and ultimate are stubs.
set -euo pipefail

launcher="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)/ultimate-hub-launchd"
dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_root="$(mktemp -d)"
holder=""
cleanup() {
  [ -n "$holder" ] && kill "$holder" 2>/dev/null || true
  if [ -x /usr/bin/trash ]; then
    /usr/bin/trash "$test_root"
  else
    trash "$test_root"
  fi
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  [ -f "$test_root/log" ] && cat "$test_root/log" >&2
  exit 1
}

bin="$test_root/bin"
mkdir -p "$bin" "$test_root/user/projects/hub"
# `mise env -s bash` puts the stubs first; the stub ultimate records its args.
printf '%s\n' '#!/usr/bin/env bash' \
  '[ "$1 $2 $3" = "env -s bash" ] || exit 2' \
  "echo \"export PATH='$bin':\\\"\\\$PATH\\\"\"" >"$bin/mise"
printf '%s\n' '#!/usr/bin/env bash' "echo \"\$*\" >\"$test_root/calls\"" >"$bin/ultimate"
chmod +x "$bin/mise" "$bin/ultimate"
export PATH="$bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export ULTIMATE_USER_HOME="$test_root/user" ULTIMATE_HUB_WAIT=0.2

# A live process owns the hub's lock: the launcher waits instead of exiting.
sleep 30 &
holder=$!
printf '{"pid":%d,"port":4749,"project":"%s"}\n' "$holder" "$dotfiles" >"$test_root/user/projects/hub/ultimate.lock"
"$launcher" 2>"$test_root/log" &
launcher_pid=$!
sleep 1
kill -0 "$launcher_pid" 2>/dev/null || fail "exited while the hub ran"
[ ! -f "$test_root/calls" ] || fail "started a second hub"
[ "$(grep -c 'already runs' "$test_root/log")" = 1 ] || fail "should announce the wait once"

# Once it stops, the launcher starts the hub itself.
kill "$holder"
wait "$holder" 2>/dev/null || true
holder=""
wait "$launcher_pid" || fail "launcher exit status"
[ "$(cat "$test_root/calls")" = "$dotfiles --no-open --port 4749" ] || fail "ultimate args: $(cat "$test_root/calls")"

echo "ultimate-hub-launchd: ok"
