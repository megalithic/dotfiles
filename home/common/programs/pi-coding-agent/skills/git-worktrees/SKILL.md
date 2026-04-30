---
name: git-worktrees
description: Git worktree conventions and commands. Use when creating, switching to, or cleaning up git worktrees for branch work.
---

# Git worktrees

Do branch work in git worktrees under `<repo>/.worktrees/<branch>`, not in the main checkout. Pi runs non-interactive bash tool calls, so do not rely on Fish aliases/functions like `gwnew`, `gwpr`, `gwcd`, `gwprune`, `git-worktree-*`.

## Commands

### New branch worktree

```bash
repo_root=$(git rev-parse --show-toplevel)
mkdir -p "$repo_root/.worktrees"
git worktree add "$repo_root/.worktrees/$branch" -b "$branch"
```

### PR branch worktree (branch name known)

```bash
repo_root=$(git rev-parse --show-toplevel)
mkdir -p "$repo_root/.worktrees"
pr_number=$(gh pr list --state open --head "$branch" --json number --jq '.[0].number')
git fetch origin "pull/$pr_number/head:$branch"
git worktree add "$repo_root/.worktrees/$branch" "$branch"
```

### Remove/prune

```bash
git worktree remove "$repo_root/.worktrees/$branch" --force
git branch -D "$branch"  # only if branch exists
```

### Run commands in a worktree

Each bash call starts from session cwd:

```bash
cd "$repo_root/.worktrees/$branch" && <command>
```
