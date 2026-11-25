#!/usr/bin/env bash
# Offline snapshot checks: tree contents, base selection and no target mutations.
set -euo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/review-snapshot"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tmp=$(cd "$tmp" && pwd -P)
pass=0
ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}
fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}
export GIT_OPTIONAL_LOCKS=0
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
mkdir "$tmp/repo"
cd "$tmp/repo"
git init -q -b main
git config commit.gpgsign false
printf 'ignored\n' >.gitignore
printf 'original\n' >modified
printf 'original\n' >staged
printf 'original\n' >deleted
git add .
git commit -qm initial
fork=$(git rev-parse HEAD)
git worktree add -qb feature "$tmp/feature space"
wt="$tmp/feature space"
printf 'branch\n' >"$wt/branch-file"
git -C "$wt" add .
git -C "$wt" commit -qm 'branch commit'
printf 'modified\n' >"$wt/modified"
printf 'staged\n' >"$wt/staged"
git -C "$wt" add staged
printf 'untracked\n' >"$wt/untracked"
printf 'ignored\n' >"$wt/ignored"
rm "$wt/deleted"
index=$(git -C "$wt" rev-parse --git-path index)
[[ $index == /* ]] || index="$wt/$index"
record() {
  git -C "$wt" status --porcelain=v2 --untracked-files=all >"$1.status"
  git -C "$wt" stash list >"$1.stash"
  git -C "$wt" rev-parse HEAD >"$1.head"
  shasum "$index" >"$1.index"
  git for-each-ref >"$1.refs"
  (
    cd "$wt"
    # ls-files includes the deleted path; shasum still hashes every existing file.
    git ls-files -co --exclude-standard -z | xargs -0 shasum 2>/dev/null || true
    shasum ignored
  ) >"$1.files"
}
record "$tmp/before"
# Resolve from a nested cwd as well as accepting a path containing spaces.
mkdir nested
cd nested
for target in "$wt" feature; do
  out=$("$SCRIPT" "$target") || fail "snapshot $target"
  head=$(jq -r .head <<<"$out")
  jq -e --arg wt "$wt" --arg base "$fork" '.worktree == $wt and .branch == "feature" and .dirty and .base == $base and .range == (.base + ".." + .head)' <<<"$out" >/dev/null || fail "metadata $target"
  for file in modified staged untracked; do
    [[ $(git show "$head:$file") == "$file" ]] || fail "snapshot content $file"
  done
  for file in deleted ignored; do
    if git cat-file -e "$head:$file" 2>/dev/null; then fail "snapshot includes $file"; fi
  done
  ok "snapshot by $target includes dirty files, excludes deleted and ignored files"
  [[ $(git rev-list --count "$fork..$head") == 2 ]] || fail 'range must contain branch commit and snapshot'
  log=$(git log --format=%s "$fork..$head")
  [[ $log == *$'\nbranch commit' ]] || fail 'branch commit missing'
  ok 'base is the fork point and range contains branch commit plus snapshot'
  record "$tmp/after"
  for field in status stash head index refs files; do
    cmp -s "$tmp/before.$field" "$tmp/after.$field" || fail "target $field changed"
  done
  ok 'status, stash, HEAD, index, refs and file contents unchanged'
done
cd ..
out=$("$SCRIPT" .)
jq -e --arg head "$fork" '.head == $head and .dirty == false and .branch == "main"' <<<"$out" >/dev/null || fail 'clean worktree'
ok 'clean worktree reuses HEAD without a snapshot'
git init -q --bare -b main "$tmp/origin.git"
git remote add origin "$tmp/origin.git"
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git push -qu origin main
printf 'new local main\n' >new-main
git add new-main
git commit -qm 'local main ahead'
new_base=$(git rev-parse HEAD)
git worktree add -qb newer "$tmp/newer"
out=$("$SCRIPT" newer)
jq -e --arg base "$new_base" '.base == $base and .head == $base and .dirty == false' <<<"$out" >/dev/null || fail 'newer local merge base'
ok 'local main ahead of origin supplies the newest merge base'
git branch parked newer
out=$("$SCRIPT" parked --base "$fork")
jq -e --arg base "$fork" --arg head "$new_base" '.worktree == null and .branch == "parked" and .head == $head and .base == $base and .dirty == false' <<<"$out" >/dev/null || fail 'unchecked branch or explicit base'
ok 'unchecked branch uses its tip and accepts an explicit base'
if "$SCRIPT" nonexistent >"$tmp/out" 2>"$tmp/err"; then
  fail 'unknown target succeeded'
else
  [[ $? == 2 && -s $tmp/err && ! -s $tmp/out ]] || fail 'unknown target error contract'
fi
ok 'unknown target exits 2 with stderr only'
printf '1..%d\n' "$pass"
