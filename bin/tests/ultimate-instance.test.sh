#!/usr/bin/env bash
# Core lookup checks; no running Ultimate or Rex required.
set -euo pipefail
INSTANCE="$(cd "$(dirname "$0")/.." && pwd)/ultimate-instance"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tmp="$(realpath "$tmp")"
export ULTIMATE_USER_HOME="$tmp/ultimate"
mkdir -p "$ULTIMATE_USER_HOME/projects/"{.project,nested,dead} "$tmp/proj/sub/dead" "$tmp/unrelated"
pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

jq -cn --argjson pid "$$" --arg project "$tmp/proj" \
  '{pid:$pid, port:4701, project:$project}' >"$ULTIMATE_USER_HOME/projects/.project/ultimate.lock"
jq -cn --argjson pid "$$" --arg project "$tmp/proj/sub" \
  '{pid:$pid, port:4702, project:$project}' >"$ULTIMATE_USER_HOME/projects/nested/ultimate.lock"
dead=2147483647
if kill -0 "$dead" 2>/dev/null; then fail "fixture dead pid is alive"; fi
jq -cn --argjson pid "$dead" --arg project "$tmp/proj/sub/dead" \
  '{pid:$pid, port:4703, project:$project}' >"$ULTIMATE_USER_HOME/projects/dead/ultimate.lock"

out="$("$INSTANCE" "$tmp/proj/sub")"
jq -e --arg project "$tmp/proj/sub" --arg home "$ULTIMATE_USER_HOME/projects/nested" --argjson pid "$$" \
  '. == {pid:$pid, port:4702, url:"http://127.0.0.1:4702", project:$project, home:$home}' <<<"$out" >/dev/null || fail "deepest root: $out"
ok "nested directory picks the deepest live root"

# An instance's own conversation worktrees live under its home, outside its project.
mkdir -p "$ULTIMATE_USER_HOME/projects/.project/worktrees/42/src"
out="$("$INSTANCE" "$ULTIMATE_USER_HOME/projects/.project/worktrees/42/src")"
jq -e '.port == 4701' <<<"$out" >/dev/null || fail "own worktree: $out"
ok "a conversation worktree under an instance's home picks that instance"

if out="$("$INSTANCE" "$tmp/unrelated")"; then
  fail "unrelated directory matched: $out"
else
  rc=$?
fi
[ "$rc" -eq 1 ] && [ -z "$out" ] || fail "unrelated directory: rc=$rc output=$out"
ok "unrelated directory exits 1 with no output"

out="$("$INSTANCE" "$tmp/proj/sub/dead")"
jq -e '.port == 4702' <<<"$out" >/dev/null || fail "dead pid selected: $out"
ok "dead pid is ignored"

out="$("$INSTANCE" --all)"
jq -e --argjson pid "$$" \
  'length == 2 and all(.[]; .pid == $pid) and (map(.port) | sort == [4701,4702])' <<<"$out" >/dev/null || fail "live instances: $out"
ok "--all lists only live instances, including hidden project folders"
printf 'all %d checks passed\n' "$pass"
