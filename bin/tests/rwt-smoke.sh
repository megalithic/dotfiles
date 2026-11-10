#!/usr/bin/env bash
# End-to-end check of rwt against the live Rex server with a throwaway repo.
# The fake "Phoenix" is an IEx session with a TCP listener, so the services
# pane runs the same kind of program (BEAM + IEx shell) as the real thing.
# Creates Rex sessions labeled rwtsmoke-* and removes them on exit.
set -euo pipefail
RWT="$(cd "$(dirname "$0")/.." && pwd)/rwt"
REX="${REX_BIN_DIR:-$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS}/rex"
export REX_SERVER="${REX_SERVER:-unix://$HOME/Library/Application Support/rex/server.sock}"
tmp="$(mktemp -d /tmp/rwtsmoke.XXXX)"
repo="$tmp/rwtsmoke"
pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}
cleanup() {
  [ -z "${RWT_SMOKE_KEEP:-}" ] || {
    echo "kept $tmp and its sessions" >&2
    return
  }
  "$REX" ls --json 2>/dev/null | jq -r '.sessions[] | select(.label | startswith("rwtsmoke")) | .session_id' |
    while read -r s; do "$REX" kill "$s" >/dev/null 2>&1 || true; done
  trash "$tmp" 2>/dev/null || true
}
trap cleanup EXIT
unset GIT_WORKTREE

# ---- fixture repo: personal config lives only in ignored .config/ --------------
mkdir -p "$repo/.config" "$repo/deps/fake_dep"
cd "$repo"
git init -q -b main
printf 'deps/\n_build/\n.config/\n.local/\n.worktreeinclude\n' >.gitignore
echo 'IO.puts("hi")' >app.exs
git add . && git -c user.email=t@t -c user.name=t commit -qm init
echo "seeded" >deps/fake_dep/marker
printf '# copied into new worktrees\n.config/\ndeps/\n' >.worktreeinclude
cat >.config/port.sh <<'EOF'
# Deterministic per-checkout port, like phx-port.sh: 7400 + cksum(root) % 400.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PHX_PORT=$((7400 + $(printf %s "$root" | cksum | cut -d' ' -f1) % 400))
export PHX_PORT
EOF
cat >.config/server.exs <<'EOF'
port = String.to_integer(System.fetch_env!("PHX_PORT"))
serve = fn serve, l ->
  {:ok, s} = :gen_tcp.accept(l)
  :gen_tcp.recv(s, 0, 1000)
  :gen_tcp.send(s, "HTTP/1.1 200 OK\r\ncontent-length: 2\r\nconnection: close\r\n\r\nok")
  :gen_tcp.close(s)
  serve.(serve, l)
end
# The listener lives in its own process: the file's eval process exits.
spawn(fn ->
  {:ok, l} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true, ip: {127, 0, 0, 1}])
  IO.puts("[fake-phoenix] Running on http://127.0.0.1:#{port} from #{File.cwd!()}")
  serve.(serve, l)
end)
EOF
cat >.config/mise.toml <<'EOF'
[env]
_.source = "{{config_root}}/.config/port.sh"

[tasks."dev:setup"]
run = '''
echo "setup in $PWD"
test -f deps/fake_dep/marker && echo "deps seeded by clonefile"
[ "$(git branch --show-current)" != feat-bad ] || { echo "boom: setup failed on purpose"; exit 9; }
'''

[tasks."dev:services"]
raw = true
run = "iex .config/server.exs"
EOF
mise trust --all >/dev/null 2>&1

# ---- new worktree -> session with setup, code, services, agent ---------------
out="$("$RWT" new feat-x --json --no-agent)" || fail "rwt new failed: $out"
jq -e '.ok and .worktree.created and .session.created' <<<"$out" >/dev/null || fail "new JSON: $out"
wt="$(jq -r .worktree.path <<<"$out")"
sid="$(jq -r .session.id <<<"$out")"
ok "new created worktree and session ($(jq -r .setup <<<"$out"))"
[ -f "$wt/deps/fake_dep/marker" ] || fail "deps not seeded"
ok "ignored deps/ seeded into the worktree"
[ "$(cat "$wt/.local/state/rwt-session")" = "$sid" ] || fail "state file"
"$REX" window ls -s "$sid" --json | jq -e '[.windows[].label] | index("setup") | not' >/dev/null || fail "setup tab not closed"
ok "setup tab closed after success"

"$RWT" wait-ready "$wt" --timeout 60 2>/dev/null || fail "server never came up"
st="$("$RWT" status "$wt")"
jq -e '.services.running and .http.app == 200 and .port != null' <<<"$st" >/dev/null || fail "status: $st"
pid1="$(jq -r .services.beam_pid <<<"$st")"
block1="$(jq -r .services.block <<<"$st")"
ok "services up on :$(jq -r .port <<<"$st") (pid $pid1)"
sleep 2
ps="$("$RWT" status "$wt" | jq -c .services.program_status)"
printf '# program_status: %s\n' "$ps"

"$RWT" logs "$wt" | rg -q 'fake-phoenix\] Running' || fail "logs missing server line"
ok "logs read from Rex scrollback"

# ---- restart replaces the terminal, not just the process -----------------------
r="$("$RWT" restart "$wt" --json)" || fail "restart: $r"
block2="$(jq -r .block <<<"$r")"
[ "$block2" != "$block1" ] || fail "restart reused the block"
"$RWT" wait-ready "$wt" --timeout 60 2>/dev/null || fail "server not back after restart"
st="$("$RWT" status "$wt")"
pid2="$(jq -r .services.beam_pid <<<"$st")"
[ "$pid2" != "$pid1" ] && ! kill -0 "$pid1" 2>/dev/null || fail "old BEAM still alive or pid unchanged"
[ "$(jq -r .services.block <<<"$st")" = "$block2" ] || fail "label lookup after restart"
ok "restart: new block $block2, new pid $pid2, old BEAM gone"

# ---- a crashed server stays visible, and open repairs a missing pane ----------
kill -KILL "$pid2"
sleep 2
st="$("$RWT" status "$wt")"
jq -e '.services.running == false and .services.last_exit != null' <<<"$st" >/dev/null || fail "crash not reported: $st"
ok "crash reported (last_exit $(jq -c .services.last_exit <<<"$st"))"
"$REX" block close -s "$sid" "$block2" >/dev/null
o="$("$RWT" open "$wt" --json)"
jq -e '.ok and (.session.created | not) and .layout.services' <<<"$o" >/dev/null || fail "open repair: $o"
"$RWT" wait-ready "$wt" --timeout 60 2>/dev/null || fail "repaired server not up"
ok "open reused the session and re-created the services pane"
set +e
"$RWT" open "$wt" --prompt hi --json >/dev/null 2>&1
rc=$?
set -e
[ "$rc" -eq 6 ] || fail "--prompt on an existing session: rc=$rc"
ok "--prompt refuses an existing session instead of dropping the prompt"

# ---- failing setup surfaces the error ------------------------------------------
set +e
f="$("$RWT" new feat-bad --json 2>/dev/null)"
rc=$?
set -e
[ "$rc" -eq 4 ] && jq -e '.ok == false and (.error | test("setup failed"))' <<<"$f" >/dev/null || fail "setup failure: rc=$rc $f"
ok "setup failure exits 4 and keeps the setup tab"

# ---- prune refuses unmerged, then removes merged -----------------------------
(cd "$wt" && echo change >>app.exs && git -c user.email=t@t -c user.name=t commit -qam change)
set +e
"$RWT" prune feat-x --json >/dev/null 2>&1
rc=$?
set -e
[ "$rc" -eq 6 ] || fail "prune of unmerged branch: rc=$rc"
ok "prune refuses an unmerged branch"
git merge -q --ff-only feat-x
p="$("$RWT" prune feat-x --json)" || fail "prune: $p"
[ ! -d "$wt" ] && ! git show-ref --verify --quiet refs/heads/feat-x && ! "$REX" session inspect "$sid" >/dev/null 2>&1 ||
  fail "prune left something behind"
ok "prune removed worktree, branch, and session"

echo "all $pass checks passed"
