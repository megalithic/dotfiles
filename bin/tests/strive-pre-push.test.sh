#!/usr/bin/env bash
# config/git/config.strive switches Ultimate's trailer hook off under ~/code/work/strive/, and
# bin/strive-pre-push refuses commits that name the harness. Runs against a throwaway HOME.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(realpath "$(mktemp -d)")"
trap 'rm -rf "$tmp"' EXIT
pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

include="$(git config -f "$ROOT/config/git/config" --get 'includeIf.gitdir:~/code/work/strive/.path')" ||
  fail "config has no includeIf for ~/code/work/strive/"
[[ "$include" == config.strive ]] || fail "includeIf path: $include"
ok "the global config includes config.strive for strive repos"

# A HOME with only this include, and the same process-local trailer hook Ultimate's bash tool sets.
export HOME="$tmp" GIT_CONFIG_NOSYSTEM=1 XDG_CONFIG_HOME="$tmp/.config"
for var in $(env | sed -n 's/^\(GIT_CONFIG_\(KEY\|VALUE\)_[0-9]*\)=.*/\1/p'); do unset "$var"; done
mkdir -p "$tmp/.config/git" "$tmp/code/work/strive" "$tmp/elsewhere"
ln -s "$ROOT/config/git/config.strive" "$tmp/.config/git/config.strive"
ln -s "$ROOT/bin" "$tmp/bin"
printf '[includeIf "gitdir:~/code/work/strive/"]\n  path = config.strive\n[user]\n  name = Test\n  email = test@example.com\n' >"$tmp/.config/git/config"
export GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=hook.ultimate-prepare-commit-msg.event GIT_CONFIG_VALUE_0=prepare-commit-msg \
  GIT_CONFIG_KEY_1=hook.ultimate-prepare-commit-msg.command \
  GIT_CONFIG_VALUE_1='git interpret-trailers --in-place --trailer "Ultimate-Conversation: 42" "$1" #'

repo() {
  git init -q -b main "$1"
  git -C "$1" commit -q --allow-empty -m "feat: first"
}
repo "$tmp/elsewhere/app"
git -C "$tmp/elsewhere/app" log -1 --format=%B | grep -q 'Ultimate-Conversation: 42' || fail "control: no trailer outside strive"
ok "outside strive the trailer hook still runs"

app="$tmp/code/work/strive/app"
repo "$app"
! git -C "$app" log -1 --format=%B | grep -q Ultimate-Conversation || fail "trailer added in a strive repo"
git -C "$app" worktree add -q -b wt "$app/.worktrees/wt"
git -C "$app/.worktrees/wt" commit -q --allow-empty -m "feat: in a worktree"
! git -C "$app" log -1 --format=%B wt | grep -q Ultimate-Conversation || fail "trailer added in a strive worktree"
ok "the trailer hook is off in a strive repo and its worktrees"

git init -q --bare "$tmp/remote.git"
git -C "$app" remote add origin "$tmp/remote.git"
git -C "$app" commit -q --allow-empty -m "fix: ultimately the same"
git -C "$app" push -q origin main 2>"$tmp/err" || fail "a clean push was refused: $(cat "$tmp/err")"
ok "words like 'ultimately' push"

git -C "$app" commit -q --allow-empty -m "fix: harness" -m "Checked in the Ultimate thread."
if git -C "$app" push -q origin main 2>"$tmp/err"; then fail "a commit naming the harness was pushed"; fi
grep -q "fix: harness" "$tmp/err" && grep -q "line 3:Checked in the Ultimate thread." "$tmp/err" ||
  fail "refusal names the commit and line: $(cat "$tmp/err")"
ok "a commit naming the harness is refused with its subject and line"

git -C "$app" commit -q --amend --allow-empty -m "fix: harness" -m "Ultimate-Conversation: 42"
if git -C "$app" push -q origin main 2>/dev/null; then fail "a trailer commit was pushed"; fi
git -C "$app" commit -q --amend --allow-empty -m "fix: clean"
git -C "$app" push -q origin main 2>"$tmp/err" || fail "the reworded commit was refused: $(cat "$tmp/err")"
ok "a trailer is refused, and the reworded commit pushes"
