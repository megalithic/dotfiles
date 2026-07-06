---
description: Merge a worktree branch back to main with rebase for linear history
---

Merge worktree branch `$1` back to main with rebase. Follow these steps in order.

## 1. Check for dangling files

```bash
cd "$repo_root/.worktrees/$1"
git status --short
```

- Commit files that should be committed (completed tickets, finished work) using git-commit conventions
- Don't commit scratch files, build artifacts, or temporary files
- Ask me if unsure whether something should be committed
- Proceed only when `git status --short` is clean

## 2. Rebase onto main

```bash
cd "$repo_root"
git checkout main
git pull --rebase origin main
cd "$repo_root/.worktrees/$1"
git rebase main
```

If there are conflicts:

- **Obvious conflicts** (trivially resolvable imports, both sides added different lines, generated files): resolve and continue immediately with `GIT_EDITOR=true git rebase --continue`
- **Non-obvious conflicts** (logic changes, overlapping edits, unclear intent): stop and present the conflict to me. Wait for my direction before proceeding.

After rebase, verify: `git log --oneline main..HEAD`

## 3. Fast-forward merge to main

```bash
cd "$repo_root"
git checkout main
git merge --ff-only "$1"
git push origin main
```

If `--ff-only` fails, the rebase didn't work — go back to step 2.

## 4. Clean up

Only remove branch `$1` and its worktree. Never touch other branches or worktrees.

```bash
cd "$repo_root"
git worktree remove "$repo_root/.worktrees/$1" --force
git branch -D "$1"
git worktree prune
```
