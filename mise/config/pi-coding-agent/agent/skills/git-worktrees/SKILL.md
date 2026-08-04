---
name: git-worktrees
description: Manage, query, enter, and remove Git worktrees with Worktrunk through the local `wt` wrapper and mise project templates. First verify `wt` can reach Worktrunk. If unavailable, use preserved legacy git-worktree workflow.
---

# Worktrees

Use Worktrunk through `wt` for all worktree management when available. Do not use raw `git worktree` commands, hand-copy ignored files, write `GIT_WORKTREE`, or create tmux layouts manually while `wt` works. `wt` owns those steps.

## Availability gate

Run before any worktree action:

```bash
if command -v wt >/dev/null 2>&1 && wt --version >/dev/null 2>&1; then
  echo "Worktrunk available: $(wt --version)"
else
  echo "Worktrunk wrapper unavailable"
fi
```

`wt` must pass both checks. It is local shell-agnostic wrapper, not bare Worktrunk binary. Wrapper verifies real Worktrunk binary, then adds default project-hook approval, branch creation, tmux targeting, `GIT_WORKTREE`, and Pi Lens setup.

If either check fails:

1. Report failed command and output.
2. Read `references/legacy-git-worktrees.md` fully.
3. Follow legacy workflow unchanged for this task.
4. Do not install Worktrunk or alter global mise config without user request.

## Worktrunk preflight

From repository root:

```bash
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
wt config show --full
wt hook show
```

Worktrunk global config keeps worktrees at `<repo>/.worktrees/<sanitized-branch>`.

Project config lives at `<repo>/.config/wt.toml`. Generate only when missing and project stack is known:

```bash
# Elixir/Phoenix
mise run gen:wt-elixir

# Shopify theme
mise run gen:wt-shopify
```

Template generation is idempotent. It writes project Worktrunk config plus stack helpers, then trusts generated mise config. Do not overwrite an existing `.config/wt.toml` or guess project stack. Worktrunk still works without a project template; hooks and stack services will not exist.

## Create, enter, and navigate

`wt` accepts implicit branches. It injects `switch`, `--create` when branch exists neither locally nor on `origin`, and `--yes` for approved hooks.

```bash
# Create or open branch worktree; default target creates/reuses tmux session.
wt feature/login

# Explicit new branch from base.
wt -t session switch --create feature/login --base origin/main

# Reuse/create current tmux session window.
wt -t window feature/login

# Use normal Worktrunk directive behavior in an interactive shell.
wt -t cd feature/login
```

Target behavior:

- `session` — create or reuse `<repo>-<branch>` tmux session with `code` and `services[-PORT]` windows; switch client inside tmux, attach outside.
- `window` — create or reuse worktree window in current tmux session; outside tmux, falls back to `session`.
- `cd` — restore Worktrunk's plain parent-shell change-directory behavior. Only useful from interactive shell wrapper; agent Bash calls cannot change parent cwd.

The wrapper creates missing `.pi-lens.json` in linked worktrees with formatting disabled. It derives and exports `GIT_WORKTREE`; query it instead of reimplementing derivation:

```bash
wt id /path/to/worktree
```

## Query worktrees

Use Worktrunk JSON for discovery and scripting:

```bash
wt list --format=json
wt list --branches --full --format=json
wt config show --format=json
wt hook show
```

Resolve branch path before commands that must run there:

```bash
branch="feature/login"
worktree_path=$(wt list --format=json | jq -er \
  --arg branch "$branch" \
  '.[] | select(.kind == "worktree" and .branch == $branch) | .path')
cd "$worktree_path"
mise trust
mise tasks ls
mise run <task>
```

Run project commands through `mise` from resolved worktree. Do not use `devenv` as generic setup path. For unavailable tools, use `MISE_AUTO_INSTALL=false mise exec … -- <command>` so mise fails instead of installing implicitly.

## Hooks, files, and services

Project `.config/wt.toml` controls Worktrunk lifecycle hooks. Elixir and Shopify templates:

- run `mise trust` in `pre-start`;
- install stack service runner in private worktree git dir;
- run `wt step copy-ignored` in `post-start`;
- expose local server URL in `wt list`.

`wt-tmux-target` starts or reuses `code` and `services` windows. Private service runner runs stack `mise` tasks and logs through tmux without writing runner into worktree. Reenter with `wt -t session <branch>`; do not reimplement setup with copy loops, `.env` edits, or detached `devenv` processes.

Use hooks only when needed:

```bash
wt hook show
wt -C "$worktree_path" hook pre-start -y  # Repair missing template service runner.
wt -C "$worktree_path" step copy-ignored --dry-run
```

`wt-tail-logs <branch>` only tails Worktrunk hook logs. Use project `mise run logs` or `mise run logs:follow` when template provides them.

## Remove and prune

Use Worktrunk removal so configured hooks run:

```bash
# Remove merged worktree and branch; reclaim non-interactive child processes.
wt remove --reap feature/login

# Keep branch.
wt remove --reap --no-delete-branch feature/login
```

`--force`, `--force-delete`, and removal of dirty or unmerged worktrees destroy work. Request explicit user approval before these flags. `--reap` leaves interactive shells and terminal editors alive; inspect or close tmux session before forcing removal.

## Rules

- Use `wt`, never bare `worktrunk` or raw `git worktree`, while availability gate passes.
- Use `wt list --format=json` for path and state queries.
- Use `mise` tasks and generated `.config/wt.toml` templates for project setup and services.
- Keep worktree commands scoped with `wt -C "$worktree_path"` or `cd "$worktree_path"`.
- If `wt` unavailable, use only preserved legacy reference.
