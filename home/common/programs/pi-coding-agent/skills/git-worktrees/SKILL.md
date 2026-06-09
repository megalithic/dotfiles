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
- Log setup output to `$worktree_path/.worktree-setup.log` and run in background.
- The wrapper appends `WORKTREE_SETUP_EXIT=N` as the final line so the agent can check the result.
- Immediately tail the log in a **separate bash call** (timeout 300s) so output streams live.
- The `--pid` flag on `tail` auto-exits when the setup process finishes.

**Post-setup verification (REQUIRED):**

After the tail command finishes (or times out), the agent MUST run a verification step:

1. Check if setup process is still running: `pgrep -f 'worktree:setup'`
   - If still running, setup didn't finish. Report to user with last 30 lines of log.
2. Check exit code sentinel: `tail -1 "$setup_log"` should contain `WORKTREE_SETUP_EXIT=0`
3. Scan for failures: `rg -i 'failed|\(exit status|exception|WORKTREE_SETUP_EXIT=[^0]' "$setup_log" | head -20`
4. **If any errors found:** report them clearly with relevant log lines. Do NOT say "worktree is ready".
5. **If tail timed out and process still running:** report setup incomplete, show last 30 lines, ask user.
6. **Only if `WORKTREE_SETUP_EXIT=0` and no error patterns:** confirm worktree is fully ready.

After setup completes, create a detached tmux session for the worktree:

- Session name: `<repo_basename>-<branch>` (e.g. repo at `~/code/work/strive/rx` with branch `sm-spp-custom-strength` → session `rx-sm-spp-custom-strength`).
- Start detached (`-d`) so it doesn't switch focus.
- Set the session's working directory to the worktree path.
- Skip if a tmux session with that name already exists.

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
  if (cd "$worktree_path" && devenv tasks list 2>/dev/null | awk '{print $NF}' | rg -qx 'worktree:setup'); then
    setup_log="$worktree_path/.worktree-setup.log"
    (cd "$worktree_path" && devenv tasks run worktree:setup; echo "WORKTREE_SETUP_EXIT=$?") > "$setup_log" 2>&1 &
    setup_pid=$!
    echo "Setup running in background (PID $setup_pid), log: $setup_log"
  fi
fi

# Create detached tmux session for the worktree
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  tmux new-session -d -s "$tmux_session" -c "$worktree_path"
  tmux setenv -t "$tmux_session" DEVENV_CWD "$worktree_path"
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
  if (cd "$worktree_path" && devenv tasks list 2>/dev/null | awk '{print $NF}' | rg -qx 'worktree:setup'); then
    setup_log="$worktree_path/.worktree-setup.log"
    (cd "$worktree_path" && devenv tasks run worktree:setup; echo "WORKTREE_SETUP_EXIT=$?") > "$setup_log" 2>&1 &
    echo "Setup running in background (PID $!), log: $setup_log"
  fi
fi
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  tmux new-session -d -s "$tmux_session" -c "$worktree_path"
  tmux setenv -t "$tmux_session" DEVENV_CWD "$worktree_path"
fi
```

Then tail the log in a separate bash call (timeout 300s):

```bash
tail -f "$worktree_path/.worktree-setup.log" --pid=$(pgrep -f "worktree:setup" | head -1)
```

Then verify setup result (separate bash call):

```bash
setup_log="$worktree_path/.worktree-setup.log"
# Check if process still running
if pgrep -f 'worktree:setup' > /dev/null 2>&1; then
  echo "WARNING: setup still running"
  tail -30 "$setup_log"
else
  exit_line=$(tail -1 "$setup_log")
  echo "Exit sentinel: $exit_line"
  echo "---"
  rg -i 'failed|\(exit status|exception|WORKTREE_SETUP_EXIT=[^0]' "$setup_log" | head -20
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
  if (cd "$worktree_path" && devenv tasks list 2>/dev/null | awk '{print $NF}' | rg -qx 'worktree:setup'); then
    setup_log="$worktree_path/.worktree-setup.log"
    (cd "$worktree_path" && devenv tasks run worktree:setup; echo "WORKTREE_SETUP_EXIT=$?") > "$setup_log" 2>&1 &
    echo "Setup running in background (PID $!), log: $setup_log"
  fi
fi
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  tmux new-session -d -s "$tmux_session" -c "$worktree_path"
  tmux setenv -t "$tmux_session" DEVENV_CWD "$worktree_path"
fi
```

Then tail + verify same as new branch worktree above.

### Remove/prune

```bash
# Kill tmux session FIRST so devenv down can run while directory still exists
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
tmux-kill-session "$tmux_session" 2>/dev/null || true

git worktree remove "$repo_root/.worktrees/$branch" --force
git branch -D "$branch"  # only if branch exists
```

### Run commands in a worktree

Each bash call starts from session cwd:

```bash
cd "$repo_root/.worktrees/$branch" && <command>
```
