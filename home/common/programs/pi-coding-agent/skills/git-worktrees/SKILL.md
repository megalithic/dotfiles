---
name: git-worktrees
description: Git worktree conventions and commands. Use when creating, switching to, or cleaning up git worktrees for branch work.
---

# Git worktrees

Do branch work in git worktrees under `<repo>/.worktrees/<branch>`, not in the main checkout. Pi runs non-interactive bash tool calls, so do not rely on Fish aliases/functions like `gwnew`, `gwpr`, `gwcd`, `gwprune`, `git-worktree-*`.

## Core worktree files

Some repo-local environment files are intentionally untracked but still needed in every worktree. After creating a worktree, copy missing core files from the main checkout into the new worktree.

Default core files:

```bash
worktree_core_files=(
  .env
  .envrc
  devenv.nix
  devenv.yaml
)
```

To add more files, extend `worktree_core_files` in the command before the copy loop. Keep this list near worktree creation commands so repo-specific additions are obvious.

Copy rules:

- Copy only files that exist in `$repo_root`.
- Do not overwrite files already present in the worktree.
- Preserve symlinks as symlinks.
- These files are often untracked or gitignored, so do not expect `git worktree add` to bring them over.

After creating a worktree and copying core files, run the one-time worktree setup task when available:

- Only run this immediately after a successful `git worktree add`, not when re-entering an existing worktree.
- Require `devenv.nix` in the new worktree.
- Require a `worktree:setup` task in `devenv tasks list`.
- Run `devenv tasks run worktree:setup` from the worktree cwd.

```bash
for file in "${worktree_core_files[@]}"; do
  src="$repo_root/$file"
  dest="$worktree_path/$file"
  if [ -e "$src" ] || [ -L "$src" ]; then
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  fi
done

if [ -e "$worktree_path/devenv.nix" ] || [ -L "$worktree_path/devenv.nix" ]; then
  if (cd "$worktree_path" && devenv tasks list | awk '{print $1}' | grep -qx 'worktree:setup'); then
    (cd "$worktree_path" && devenv tasks run worktree:setup)
  fi
fi
```

## Commands

### New branch worktree

```bash
repo_root=$(git rev-parse --show-toplevel)
worktree_path="$repo_root/.worktrees/$branch"
worktree_core_files=(.env .envrc devenv.nix devenv.yaml)
mkdir -p "$repo_root/.worktrees"
git worktree add "$worktree_path" -b "$branch"
for file in "${worktree_core_files[@]}"; do
  src="$repo_root/$file"
  dest="$worktree_path/$file"
  if [ -e "$src" ] || [ -L "$src" ]; then
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  fi
done
if [ -e "$worktree_path/devenv.nix" ] || [ -L "$worktree_path/devenv.nix" ]; then
  if (cd "$worktree_path" && devenv tasks list | awk '{print $1}' | grep -qx 'worktree:setup'); then
    (cd "$worktree_path" && devenv tasks run worktree:setup)
  fi
fi
```

### PR branch worktree (branch name known)

```bash
repo_root=$(git rev-parse --show-toplevel)
worktree_path="$repo_root/.worktrees/$branch"
worktree_core_files=(.env .envrc devenv.nix devenv.yaml)
mkdir -p "$repo_root/.worktrees"
pr_number=$(gh pr list --state open --head "$branch" --json number --jq '.[0].number')
git fetch origin "pull/$pr_number/head:$branch"
git worktree add "$worktree_path" "$branch"
for file in "${worktree_core_files[@]}"; do
  src="$repo_root/$file"
  dest="$worktree_path/$file"
  if [ -e "$src" ] || [ -L "$src" ]; then
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  fi
done
if [ -e "$worktree_path/devenv.nix" ] || [ -L "$worktree_path/devenv.nix" ]; then
  if (cd "$worktree_path" && devenv tasks list | awk '{print $1}' | grep -qx 'worktree:setup'); then
    (cd "$worktree_path" && devenv tasks run worktree:setup)
  fi
fi
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
