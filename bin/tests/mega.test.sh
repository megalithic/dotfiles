#!/usr/bin/env bash
# mega start/ls/stop against a stub `ultimate`; no real Ultimate runs.
set -euo pipefail
MEGA="$(cd "$(dirname "$0")/.." && pwd)/mega"
tmp="$(realpath "$(mktemp -d)")"
trap 'pkill -f "$tmp/bin/ultimate" 2>/dev/null || true; rm -rf "$tmp"' EXIT
export HOME="$tmp/home" ULTIMATE_USER_HOME="$tmp/home/.ultimate" ULTIMATE_HOME="$tmp/other-instance"
export STUB_LOCKS="$ULTIMATE_USER_HOME/projects"
mkdir -p "$tmp/bin" "$HOME" "$tmp/code/app"
# The stub holds a lock like Ultimate's until SIGTERM, which removes it.
cat >"$tmp/bin/ultimate" <<'EOF'
#!/usr/bin/env bash
# mega clears every ULTIMATE_* variable for it, so the locks' folder comes another way.
[ -z "${ULTIMATE_HOME:-}${ULTIMATE_USER_HOME:-}" ] || exit 3
lock="$STUB_LOCKS/$(basename "$1")/ultimate.lock"
mkdir -p "$(dirname "$lock")"
trap 'rm -f "$lock"; exit 0' TERM
echo "stub serving $1 $2"
printf '{"pid":%d,"port":4799,"project":"%s"}\n' "$$" "$1" >"$lock"
while :; do sleep 0.1; done
EOF
chmod +x "$tmp/bin/ultimate"
export PATH="$tmp/bin:$PATH"
pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

out="$("$MEGA" start "$tmp/code/app")"
[[ "$out" == "app: http://127.0.0.1:4799 (pid "*", log $HOME/Library/Logs/ultimate-app.log)" ]] || fail "start: $out"
grep -q "stub serving $tmp/code/app --no-open" "$HOME/Library/Logs/ultimate-app.log" || fail "log"
ok "start runs ultimate detached with --no-open and logs to ultimate-<basename>.log"

out="$("$MEGA" start "$tmp/code/app")"
[[ "$out" == "app already runs on http://127.0.0.1:4799"* ]] || fail "second start: $out"
ok "start again reports the running instance"

out="$("$MEGA" ls)"
[[ "$out" == "app"$'\t'":4799 $tmp/code/app (pid "*")" ]] || fail "ls: $out"
ok "ls lists name<TAB>:port path (pid)"

out="$("$MEGA" stop app)"
[[ "$out" == "stopped app (pid "*")" ]] || fail "stop: $out"
[[ -z "$("$MEGA" ls)" ]] || fail "still listed after stop"
ok "stop by name sends SIGTERM and waits for it to exit"

if out="$("$MEGA" stop app 2>&1)"; then fail "stopping a stopped instance succeeded"; fi
[[ "$out" == *"no running Ultimate named app"* ]] || fail "stop missing: $out"
ok "stop names what is not running"

# A plain login shell carries no ULTIMATE_* variable, and macOS /bin/bash is 3.2.
out="$(env -i HOME="$HOME" PATH="$PATH" STUB_LOCKS="$STUB_LOCKS" /bin/bash "$MEGA" start "$tmp/code/app" 2>&1)" ||
  fail "start under /bin/bash without ULTIMATE_*: $out"
[[ "$out" == "app: http://127.0.0.1:4799 (pid "*")" ]] || fail "start under /bin/bash: $out"
"$MEGA" stop app >/dev/null
ok "start works under /bin/bash with no ULTIMATE_* variables"

echo "1..$pass"
