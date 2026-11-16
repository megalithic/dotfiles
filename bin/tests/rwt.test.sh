#!/usr/bin/env bash
# Offline rwt checks: worktree ids, and detached worktrees (such as Ultimate's
# lander checkout, which made the old `wt list` fail with backend_parse_failed).
# A stub rex stands in for the Rex server: bash bin/tests/rwt.test.sh
set -euo pipefail
RWT="$(cd "$(dirname "$0")/.." && pwd)/rwt"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tmp="$(cd "$tmp" && pwd -P)"
pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}
unset GIT_WORKTREE REX_SESSION REX_BLOCK

# Just enough of the rex CLI for rwt new: a session whose setup succeeds.
mkdir -p "$tmp/rexbin"
cat >"$tmp/rexbin/rex" <<'EOF'
#!/usr/bin/env bash
case "$1 ${2:-}" in
  "ls --json") echo '{"sessions":[]}' ;;
  "window ls") echo '{"windows":[]}' ;;
  new*) echo '{"session_id":"session:stub","initial_windows":[{"window_id":"window:setup","block_ids":["block:setup"]}]}' ;;
  wait* | "window close") ;;
  do*) echo '{"code":"block:code"}' ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$tmp/rexbin/rex"
export REX_BIN_DIR="$tmp/rexbin"
export RWT_STRIVE_ROOT="$tmp/strive"

repo="$tmp/repo"
mkdir -p "$repo"
cd "$repo"
git init -q -b main
printf '.worktrees/\n.local/\n' >.gitignore
git add . && git -c user.email=t@t -c user.name=t commit -qm init
git worktree add -q --detach "$tmp/lander" HEAD
git worktree add -q --detach .worktrees/loose HEAD

ls="$("$RWT" ls)" || fail "ls: $ls"
jq -e --arg l "$tmp/lander" '.ok and (.worktrees | length == 3) and
  (.worktrees[] | select(.path == $l) | .branch == null)' <<<"$ls" >/dev/null || fail "ls: $ls"
jq -e '.worktrees[0].branch == "main"' <<<"$ls" >/dev/null || fail "main branch: $ls"
ok "ls lists detached worktrees with branch null"

st="$("$RWT" status "$tmp/lander")" || fail "status: $st"
jq -e '.ok and .worktree.branch == null and .session == null' <<<"$st" >/dev/null || fail "status: $st"
ok "status reports a detached worktree's branch as null"

out="$("$RWT" new feat/y --json --no-services --no-agent 2>/dev/null)" || fail "new: $out"
jq -e --arg p "$repo/.worktrees/feat-y" '.ok and .worktree.path == $p and .worktree.branch == "feat/y" and
  .worktree.created and .session.id == "session:stub"' <<<"$out" >/dev/null || fail "new: $out"
[ "$(git -C .worktrees/feat-y branch --show-current)" = feat/y ] || fail "new checked out the wrong branch"
"$RWT" ls | jq -e '[.worktrees[].branch] | sort == [null, null, "feat/y", "main"]' >/dev/null || fail "ls after new: $("$RWT" ls)"
ok "new creates a branch worktree beside detached ones"

set +e
p="$("$RWT" prune loose --json 2>/dev/null)"
rc=$?
set -e
[ "$rc" -eq 6 ] && jq -e '.error | test("detached")' <<<"$p" >/dev/null || fail "prune detached: rc=$rc $p"
[ -d .worktrees/loose ] || fail "prune removed the detached worktree"
ok "prune refuses a detached worktree"

# Project configs derive each worktree's database and port from this id.
[ "$("$RWT" id "$repo")" = "" ] && [ "$("$RWT" id .worktrees/feat-y)" = repo-feat-y ] &&
  [ "$("$RWT" id "$tmp/lander")" = repo-lander ] && [ "$("$RWT" id feat/y)" = repo-feat-y ] ||
  fail "id: main=$("$RWT" id "$repo") feat=$("$RWT" id .worktrees/feat-y) lander=$("$RWT" id "$tmp/lander")"
ok "id: empty in main, {repo}-{branch slug}, directory name when detached"
# mise asks with `id .` from wherever the shell is; the old wt named every
# detached checkout "{repo}-" that way, so they shared one database and port.
mkdir -p "$tmp/lander/sub"
[ "$(cd "$tmp/lander/sub" && "$RWT" id .)" = repo-lander ] && [ "$(cd .worktrees/feat-y && "$RWT" id .)" = repo-feat-y ] ||
  fail "id . from a subdirectory: $(cd "$tmp/lander/sub" && "$RWT" id .)"
ok "id . names the checkout, not the current directory"

# Strive repos name worktrees sm-<short-kebab-name>; feat/y above kept its name.
strive="$tmp/strive/acme"
mkdir -p "$strive"
git -C "$strive" init -q -b main
cp .gitignore "$strive/"
git -C "$strive" add . && git -C "$strive" -c user.email=t@t -c user.name=t commit -qm init
cd "$strive"
out="$("$RWT" new expand-reporting --json --no-services --no-agent 2>"$tmp/err")" || fail "strive new: $out"
jq -e --arg p "$strive/.worktrees/sm-expand-reporting" '.worktree.path == $p and .worktree.branch == "sm-expand-reporting" and
  .worktree.id == "acme-sm-expand-reporting"' <<<"$out" >/dev/null || fail "strive new: $out"
grep -q 'expand-reporting -> sm-expand-reporting' "$tmp/err" || fail "strive new did not print the final name: $(cat "$tmp/err")"
"$RWT" new sm-expand-reporting --json --no-services --no-agent 2>/dev/null | jq -e '.worktree.created == false' >/dev/null ||
  fail "strive new sm- name did not reuse the worktree"
ok "strive: new prefixes sm- and the id derives from the final name"

for bad in Fix_Thing feat/y one-two-three-four-five-six sm-; do
  set +e
  e="$("$RWT" new "$bad" --json --no-services --no-agent 2>/dev/null)"
  rc=$?
  set -e
  [ "$rc" -eq 2 ] && jq -e '.error | test("sm-<short-kebab-name>")' <<<"$e" >/dev/null || fail "strive bad name $bad: rc=$rc $e"
done
[ "$(git -C "$strive" worktree list | wc -l)" -eq 2 ] || fail "a rejected name created a worktree"
ok "strive: new rejects names that aren't short lowercase kebab-case"

echo "all $pass checks passed"
