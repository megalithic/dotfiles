#!/usr/bin/env bash
# Offline rwt checks: worktree identity, fresh origin bases and safe shutdown.
# Detached worktrees include Ultimate's lander checkout.
# A stub rex stands in for the Rex server: bash bin/tests/rwt.test.sh
set -euo pipefail
RWT="$(cd "$(dirname "$0")/.." && pwd)/rwt"
tmp="$(mktemp -d)"
child='' other_child=''
trap 'for pid in "$child" "$other_child"; do [ -z "$pid" ] || kill "$pid" 2>/dev/null || true; done; rm -rf "$tmp"' EXIT
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
  "session inspect") [ ! -f "${RWT_TEST_KILLED:-/nonexistent}" ] ;;
  "block ls")
    if [ -n "${RWT_TEST_BLOCKS:-}" ]; then echo "$RWT_TEST_BLOCKS"; else echo '{"blocks":[{"block_id":"block:terminal"}]}'; fi
    ;;
  "block call")
    if [ "$6" = block:host ]; then echo "${RWT_TEST_OTHER_PROCESS:-null}"; else echo "${RWT_TEST_PROCESS:-null}"; fi
    ;;
  kill*) [ -z "${RWT_TEST_KILLED:-}" ] || touch "$RWT_TEST_KILLED" ;;
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

# Origin advances without advancing the local default or remote-tracking ref.
cd "$repo"
git init -q --bare -b main "$tmp/origin.git"
git remote add origin "$tmp/origin.git"
git push -q -u origin main
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git clone -q "$tmp/origin.git" "$tmp/upstream"
git -C "$tmp/upstream" -c user.email=t@t -c user.name=t commit -qm newer --allow-empty
git -C "$tmp/upstream" push -q origin main
newer="$(git -C "$tmp/upstream" rev-parse HEAD)"
[ "$(git rev-parse main)" != "$newer" ] || fail "origin fixture did not advance"
out="$("$RWT" new fresh --json --no-services --no-agent)" || fail "new fresh: $out"
[ "$(git rev-parse fresh)" = "$newer" ] || fail "new did not fetch origin/main"
[ -z "$(git for-each-ref --format='%(upstream)' refs/heads/fresh)" ] || fail "new branch tracks origin/main"
ok "new fetches origin/main and creates a branch without an upstream"

# Give down isolated discovery tools, ahead of system tools in rwt's PATH.
# No real Ultimate API or cwd process inventory is used by these offline tests.
export HOME="$tmp/home"
mkdir -p "$HOME/.dotfiles/bin" "$HOME/.local/bin"
cat >"$HOME/.dotfiles/bin/ultimate-instance" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${RWT_TEST_INSTANCES:-[]}"
EOF
cat >"$HOME/.local/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${RWT_TEST_CONVERSATIONS:-null}"
EOF
cat >"$HOME/.local/bin/lsof" <<'EOF'
#!/usr/bin/env bash
[ -z "${RWT_TEST_LSOF:-}" ] || cat "$RWT_TEST_LSOF"
EOF
chmod +x "$HOME/.dotfiles/bin/ultimate-instance" "$HOME/.local/bin/"{curl,lsof}
export RWT_TEST_KILLED="$tmp/killed"

# Job control puts this real child in its own group, just like a Rex terminal.
set -m
sleep 1000 &
child=$!
set +m
export RWT_TEST_PROCESS
RWT_TEST_PROCESS="$(jq -cn --argjson p "$child" --arg cwd "$repo/.worktrees/fresh" '{child:{pid:$p,cwd:$cwd}}')"
out="$("$RWT" down fresh --json)" || fail "down: $out"
kill -0 "$child" 2>/dev/null && fail "down left the terminal process alive"
wait "$child" 2>/dev/null || true
jq -e --argjson p "$child" '.ok and (.stopped | index($p) != null) and .skipped_sweep == null' <<<"$out" >/dev/null || fail "down: $out"
child=''
[ -d "$repo/.worktrees/fresh" ] || fail "down removed the worktree"
git show-ref --verify --quiet refs/heads/fresh || fail "down removed the branch"
[ -f "$RWT_TEST_KILLED" ] && [ ! -e "$repo/.worktrees/fresh/.local/state/rwt-session" ] || fail "down did not kill session and clear its record"
ok "down TERMs a real terminal process group and keeps the worktree and branch"

rm -f "$RWT_TEST_KILLED"
unset RWT_TEST_PROCESS
mkdir -p "$repo/.local/state"
echo session:stub >"$repo/.local/state/rwt-session"
out="$("$RWT" down "$repo" --json)" || fail "down main: $out"
jq -e '.ok and (.skipped_sweep | test("main checkout")) and .swept == []' <<<"$out" >/dev/null || fail "down main: $out"
[ -f "$RWT_TEST_KILLED" ] && [ -d "$repo" ] || fail "down main did not close Rex and keep checkout"
ok "down skips the main-checkout sweep but closes its Rex session successfully"

rm -f "$RWT_TEST_KILLED"
echo session:stub >"$repo/.worktrees/fresh/.local/state/rwt-session"
export RWT_TEST_INSTANCES='[{"pid":99999999,"url":"http://ultimate.test","port":1,"project":"unused"}]'
export RWT_TEST_CONVERSATIONS
RWT_TEST_CONVERSATIONS="$(jq -cn --arg cwd "$repo/.worktrees/fresh" '{result:[{id:42,cwd:$cwd,busy:false,concluded:false}]}')"
export RWT_TEST_PROCESS
set -m
sleep 1000 &
child=$!
set +m
RWT_TEST_PROCESS="$(jq -cn --argjson p "$child" '{child:{pid:$p}}')"
out="$("$RWT" down fresh --json)" || fail "down Ultimate: $out"
kill -0 "$child" 2>/dev/null && fail "Ultimate sweep guard left the session process alive"
wait "$child" 2>/dev/null || true
child=''
jq -e '.ok and (.skipped_sweep | test("http://ultimate.test conversation #42")) and .swept == []' <<<"$out" >/dev/null || fail "down Ultimate: $out"
[ -f "$RWT_TEST_KILLED" ] || fail "Ultimate guard prevented session shutdown"
ok "down stops session processes but skips a sweep owned by an unconcluded Ultimate conversation"

# Session A has a pane cd'd into B's worktree; B's orphan is not A's to sweep.
rm -f "$RWT_TEST_KILLED"
export RWT_TEST_INSTANCES='[]' RWT_TEST_LSOF="$tmp/cwds"
echo session:other >"$repo/.worktrees/fresh/.local/state/rwt-session"
set -m
sleep 1000 &
child=$!
(cd "$repo/.worktrees/fresh" && exec sleep 1000) &
other_child=$!
set +m
RWT_TEST_PROCESS="$(jq -cn --argjson p "$child" --arg cwd "$repo/.worktrees/fresh" '{child:{pid:$p,cwd:$cwd}}')"
printf 'p%s\nn%s\n' "$other_child" "$repo/.worktrees/fresh" >"$RWT_TEST_LSOF"
out="$(cd "$tmp" && "$RWT" down --session session:stub --json)" || fail "down cross-session: $out"
kill -0 "$child" 2>/dev/null && fail "down did not stop session A's process group"
wait "$child" 2>/dev/null || true
child=''
kill -0 "$other_child" 2>/dev/null || fail "down swept session B's process"
jq -e --arg reason "worktree $repo/.worktrees/fresh belongs to another session" \
  '.ok and .skipped_sweep == $reason and .swept == []' <<<"$out" >/dev/null || fail "down cross-session: $out"
[ -f "$RWT_TEST_KILLED" ] || fail "down did not kill session A"
[ "$(cat "$repo/.worktrees/fresh/.local/state/rwt-session")" = session:other ] || fail "down removed session B's record"
kill "$other_child"
wait "$other_child" 2>/dev/null || true
other_child=''
ok "session-only down closes A without sweeping or changing B's worktree session"

# Even another, ordinary block must survive when any group hosts Ultimate.
rm -f "$RWT_TEST_KILLED"
unset RWT_TEST_LSOF
echo session:stub >"$repo/.worktrees/fresh/.local/state/rwt-session"
set -m
sleep 1000 &
child=$!
sleep 1000 &
other_child=$!
set +m
export RWT_TEST_BLOCKS='{"blocks":[{"block_id":"block:terminal"},{"block_id":"block:host"}]}'
export RWT_TEST_OTHER_PROCESS
RWT_TEST_PROCESS="$(jq -cn --argjson p "$child" '{child:{pid:$p}}')"
RWT_TEST_OTHER_PROCESS="$(jq -cn --argjson p "$other_child" '{child:{pid:$p}}')"
RWT_TEST_INSTANCES="$(jq -cn --argjson p "$other_child" '[{pid:$p,url:"http://ultimate.test",port:1,project:"test-project"}]')"
set +e
out="$("$RWT" down fresh --json)"
rc=$?
set -e
[ "$rc" -eq 6 ] || fail "down host session: rc=$rc $out"
jq -e --arg error "session runs the Ultimate host for test-project (pid $other_child); stop it there" \
  '.ok == false and .code == 6 and .error == $error' <<<"$out" >/dev/null || fail "down host session: $out"
kill -0 "$child" 2>/dev/null || fail "down signalled an ordinary block before refusing the host"
kill -0 "$other_child" 2>/dev/null || fail "down signalled the Ultimate host"
[ ! -e "$RWT_TEST_KILLED" ] || fail "down killed the host's Rex session"
[ "$(cat "$repo/.worktrees/fresh/.local/state/rwt-session")" = session:stub ] || fail "down removed the host's session record"
kill "$child" "$other_child"
wait "$child" 2>/dev/null || true
wait "$other_child" 2>/dev/null || true
child='' other_child=''
ok "down refuses an Ultimate host session before signalling any group or killing Rex"

echo "all $pass checks passed"
