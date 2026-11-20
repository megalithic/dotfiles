#!/usr/bin/env bash
# Offline rwt checks: worktree identity, fresh origin bases and safe shutdown.
# Detached worktrees include Ultimate's lander checkout.
# A stub rex stands in for the Rex server: bash bin/tests/rwt.test.sh
set -euo pipefail
RWT="$(cd "$(dirname "$0")/.." && pwd)/rwt"
tmp="$(mktemp -d)"
child='' other_child='' job=''
trap 'for pid in "$child" "$other_child" "$job"; do [ -z "$pid" ] || kill "$pid" 2>/dev/null || true; done; rm -rf "$tmp"' EXIT
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

# A shell's job is a descendant, but leads a different process group. Omit
# foreground from this first response so only the descendant walk can find it.
cat >"$tmp/job-shell" <<'EOF'
#!/usr/bin/env bash
set -m
sleep 1000 &
printf '%s\n' "$!" >"$1"
wait
EOF
start_job_shell() {
  rm -f "$tmp/job.pid"
  bash "$tmp/job-shell" "$tmp/job.pid" &
  other_child=$!
  for _ in $(seq 1 100); do
    [ -s "$tmp/job.pid" ] && break
    sleep 0.01
  done
  [ -s "$tmp/job.pid" ] || fail "job-controlled fixture did not start"
  job="$(cat "$tmp/job.pid")"
  [ "$(ps -p "$job" -o pgid=)" != "$(ps -p "$other_child" -o pgid=)" ] || fail "job did not get a separate process group"
}
rm -f "$RWT_TEST_KILLED"
unset RWT_TEST_LSOF
echo session:stub >"$repo/.worktrees/fresh/.local/state/rwt-session"
set -m
start_job_shell
set +m
RWT_TEST_PROCESS="$(jq -cn --argjson p "$other_child" '{child:{pid:$p}}')"
out="$("$RWT" down fresh --json)" || fail "down job-controlled descendant: $out"
kill -0 "$other_child" 2>/dev/null && fail "down left the block shell alive"
kill -0 "$job" 2>/dev/null && fail "down left the shell's separate job group alive"
wait "$other_child" 2>/dev/null || true
jq -e --argjson shell "$other_child" --argjson job "$job" \
  '.ok and (.stopped | index($shell) != null and index($job) != null) and .swept == []' <<<"$out" >/dev/null || fail "down job-controlled descendant: $out"
[ -f "$RWT_TEST_KILLED" ] || fail "down did not close the job-controlled session"
other_child='' job=''
ok "down stops a block shell and its job-controlled descendant in a separate group"

# Even another, ordinary block must survive when Ultimate is a foreground job
# in its own process group, rather than in the block shell's group.
rm -f "$RWT_TEST_KILLED"
echo session:stub >"$repo/.worktrees/fresh/.local/state/rwt-session"
set -m
sleep 1000 &
child=$!
start_job_shell
set +m
export RWT_TEST_BLOCKS='{"blocks":[{"block_id":"block:terminal"},{"block_id":"block:host"}]}'
export RWT_TEST_OTHER_PROCESS
RWT_TEST_PROCESS="$(jq -cn --argjson p "$child" '{child:{pid:$p}}')"
RWT_TEST_OTHER_PROCESS="$(jq -cn --argjson p "$other_child" --argjson job "$job" '{child:{pid:$p},foreground:{pid:$job}}')"
RWT_TEST_INSTANCES="$(jq -cn --argjson p "$job" '[{pid:$p,url:"http://ultimate.test",port:1,project:"test-project"}]')"
set +e
out="$("$RWT" down fresh --json)"
rc=$?
set -e
[ "$rc" -eq 6 ] || fail "down host session: rc=$rc $out"
jq -e --arg error "session runs the Ultimate host for test-project (pid $job); stop it there" \
  '.ok == false and .code == 6 and .error == $error' <<<"$out" >/dev/null || fail "down host session: $out"
kill -0 "$child" 2>/dev/null || fail "down signalled an ordinary block before refusing the host"
kill -0 "$other_child" 2>/dev/null || fail "down signalled the host's block shell"
kill -0 "$job" 2>/dev/null || fail "down signalled the Ultimate host's separate process group"
[ ! -e "$RWT_TEST_KILLED" ] || fail "down killed the host's Rex session"
[ "$(cat "$repo/.worktrees/fresh/.local/state/rwt-session")" = session:stub ] || fail "down removed the host's session record"
kill "$child" "$other_child" "$job"
wait "$child" 2>/dev/null || true
wait "$other_child" 2>/dev/null || true
child='' other_child='' job=''
ok "down refuses a host in a separate foreground group before signalling any group or killing Rex"

# rwt pr: one gh lookup per worktree, coloured for status lines, cached, and
# the source prune's squash-merge check trusts.
cd "$repo"
cat >"$tmp/gh" <<'EOF'
#!/usr/bin/env bash
echo x >>"$RWT_TEST_GH_CALLS"
[ -z "${RWT_TEST_GH_FAIL:-}" ] || exit 1
printf '%s\n' "$RWT_TEST_GH"
EOF
chmod +x "$tmp/gh"
export RWT_GH="$tmp/gh" XDG_CACHE_HOME="$tmp/cache" RWT_TEST_GH_CALLS="$tmp/gh-calls"
head="$(git rev-parse feat/y)"
pr() { # rollup review merge-state draft -> gh JSON for feat/y
  jq -cn --arg h "$head" --argjson c "$1" --arg r "$2" --arg m "$3" --argjson d "$4" \
    '[{number:7, url:"https://x/7", state:"OPEN", isDraft:$d, headRefOid:$h, reviewDecision:$r,
       mergeable:"MERGEABLE", mergeStateStatus:$m, statusCheckRollup:$c}]'
}
ok_run='{"__typename":"CheckRun","status":"COMPLETED","conclusion":"SUCCESS"}'
for case in "yellow|[$ok_run,{\"__typename\":\"CheckRun\",\"status\":\"IN_PROGRESS\",\"conclusion\":\"\"}]|REVIEW_REQUIRED|BLOCKED|false" \
  "red|[$ok_run,{\"__typename\":\"StatusContext\",\"state\":\"FAILURE\"}]|APPROVED|UNSTABLE|false" \
  "green|[$ok_run]|APPROVED|CLEAN|false" \
  "blue|[$ok_run]|REVIEW_REQUIRED|BLOCKED|false" \
  "blue|[$ok_run]||CLEAN|true"; do
  IFS='|' read -r want c r m d <<<"$case"
  RWT_TEST_GH="$(pr "$c" "$r" "$m" "$d")"
  out="$(RWT_TEST_GH="$RWT_TEST_GH" "$RWT" pr feat/y --refresh)" || fail "pr: $out"
  jq -e --arg w "$want" '.pr.number == 7 and .pr.colour == $w and .pr.head_matches and (.pr.stale | not)' <<<"$out" >/dev/null ||
    fail "pr $want ($r $m draft=$d): $out"
done
ok "pr colours: yellow running, red failed, green approved and clean, blue waiting or draft"

: >"$RWT_TEST_GH_CALLS"
RWT_TEST_GH_FAIL=1 "$RWT" pr feat/y | jq -e '.pr.colour == "blue" and (.pr.stale | not)' >/dev/null || fail "pr cache"
[ ! -s "$RWT_TEST_GH_CALLS" ] || fail "pr called gh within the cache window"
RWT_TEST_GH_FAIL=1 "$RWT" status feat/y --refresh | jq -e '.pr.stale and .pr.number == 7' >/dev/null ||
  fail "status --refresh offline: $(RWT_TEST_GH_FAIL=1 "$RWT" status feat/y --refresh)"
RWT_TEST_GH_FAIL=1 "$RWT" pr feat/y --refresh | jq -e '.pr.stale and .pr.number == 7' >/dev/null || fail "pr offline not stale"
RWT_TEST_GH='[]' "$RWT" pr feat/y --refresh | jq -e '.pr == null' >/dev/null || fail "pr none"
[ "$("$RWT" pr "$repo" | jq -c .pr)" = null ] || fail "pr on the default branch"
ok "pr: cached 60 s, stale when gh fails, null without a PR or on main"

# a/b and a-b slug alike; neither reads the other's PR, fresh or stale.
for r in a/b a-b; do
  git init -q -b main "$tmp/$r"
  HK=0 git -C "$tmp/$r" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  git -C "$tmp/$r" worktree add -q -b feat/y "$tmp/$r/.worktrees/feat-y"
done
RWT_TEST_GH="$(pr "[$ok_run]" APPROVED CLEAN false)" "$RWT" pr "$tmp/a/b/.worktrees/feat-y" --refresh |
  jq -e '.pr.number == 7' >/dev/null || fail "pr a/b"
RWT_TEST_GH='[]' "$RWT" pr "$tmp/a-b/.worktrees/feat-y" | jq -e '.pr == null' >/dev/null || fail "pr a-b read a/b's fresh cache"
rm -f "$tmp"/cache/rwt/pr/*
RWT_TEST_GH="$(pr "[$ok_run]" APPROVED CLEAN false)" "$RWT" pr "$tmp/a/b/.worktrees/feat-y" --refresh >/dev/null
RWT_TEST_GH_FAIL=1 "$RWT" pr "$tmp/a-b/.worktrees/feat-y" --refresh | jq -e '.pr == null' >/dev/null ||
  fail "pr a-b read a/b's stale cache"
ok "pr: the cache belongs to one checkout"

# A squash merge leaves no ancestry; prune trusts only a merged PR of the head.
HK=0 git -C .worktrees/feat-y -c user.email=t@t -c user.name=t commit -q --allow-empty -m work
head="$(git rev-parse feat/y)"
merged_pr() { jq -cn --arg h "$1" '[{number:7, url:"u", state:"MERGED", isDraft:false, headRefOid:$h, statusCheckRollup:[]}]'; }
set +e
p="$(RWT_TEST_GH="$(merged_pr old)" "$RWT" prune feat/y --json 2>/dev/null)"
rc=$?
p2="$(RWT_TEST_GH_FAIL=1 "$RWT" prune feat/y --json 2>/dev/null)"
rc2=$?
set -e
[ "$rc" -eq 6 ] && [ "$rc2" -eq 6 ] && [ -d .worktrees/feat-y ] || fail "prune trusted a stale or other-head PR: $p / $p2"
RWT_TEST_GH="$(merged_pr "$head")" "$RWT" prune feat/y --json 2>/dev/null | jq -e '.ok' >/dev/null || fail "prune merged PR"
[ ! -d .worktrees/feat-y ] || fail "prune left the worktree"
ok "prune: a merged PR of the current head counts; another head or a stale cache does not"

# prune --all: every merged, clean branch worktree goes; dirty, unmerged,
# detached and Ultimate-owned ones stay.
for b in gone dirty wip owned; do git worktree add -q -b "$b" ".worktrees/$b" main; done
touch .worktrees/dirty/new-file
HK=0 git -C .worktrees/wip -c user.email=t@t -c user.name=t commit -q --allow-empty -m wip
export RWT_TEST_INSTANCES='[{"pid":99999999,"url":"http://ultimate.test","port":1,"project":"unused"}]'
RWT_TEST_CONVERSATIONS="$(jq -cn --arg cwd "$repo/.worktrees/owned" '{result:[{id:42,cwd:$cwd,concluded:false}]}')"
out="$(RWT_TEST_GH='[]' "$RWT" prune --all --json 2>/dev/null)" || fail "prune --all: $out"
jq -e '.ok and ([.pruned[].branch] | index("gone") != null)
  and ([.skipped[].branch] | sort == ["dirty", "owned", "wip"])
  and (.skipped[] | select(.branch == "owned") | .reason | test("conversation #42"))' <<<"$out" >/dev/null ||
  fail "prune --all: $out"
[ ! -d .worktrees/gone ] && [ -d .worktrees/dirty ] && [ -d .worktrees/wip ] && [ -d .worktrees/owned ] &&
  [ -d .worktrees/loose ] && [ -d "$tmp/lander" ] || fail "prune --all removed the wrong worktrees"
set +e
"$RWT" prune gone --all >/dev/null 2>&1
rc=$?
"$RWT" ls --all >/dev/null 2>&1
rc2=$?
set -e
[ "$rc" -eq 2 ] && [ "$rc2" -eq 2 ] || fail "--all with a name or outside prune: rc=$rc/$rc2"
ok "prune --all prunes merged clean branches and skips dirty, unmerged, detached and Ultimate-owned ones"

echo "all $pass checks passed"
