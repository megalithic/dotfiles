---
name: git-worktrees
description: Manage, query, enter, and remove Git worktrees with Worktrunk through the local `wt` wrapper and mise project templates. First verify `wt` can reach Worktrunk. If unavailable, use preserved legacy git-worktree workflow.
---

# Worktrees

Use the local `wt` wrapper (`~/.dotfiles/bin/wt`) for every worktree operation. It runs a pinned Worktrunk (0.76.0 through mise), validates worktree identity, runs blocking project setup (`mise run dev:setup`), copies ignored files, derives `GIT_WORKTREE`, and owns tmux presentation through `ftm`.

Never, while `wt` works:

- run raw `git worktree` commands;
- call `wt-tmux-target`, `wt-tail-logs`, or build worktree tmux layouts manually;
- write or derive `GIT_WORKTREE` yourself (query `wt id`);
- hand-copy ignored files or re-run setup steps `wt` already ran;
- use `wt switch` for navigation — it is the legacy/upstream escape path, not the workflow.

## Availability gate

Run before any worktree action:

```bash
if command -v wt >/dev/null 2>&1 && wt --version >/dev/null 2>&1; then
  echo "Worktrunk available: $(wt --version)"
else
  echo "Worktrunk wrapper unavailable"
fi
```

If either check fails:

1. Report failed command and output.
2. Read `references/legacy-git-worktrees.md` fully.
3. Follow legacy workflow unchanged for this task.
4. Do not install Worktrunk or alter global mise config without user request.

## Command contract

| Command | Effect |
| --- | --- |
| `wt NAME` | Ensure the worktree exists (create branch/worktree when missing), run copy-ignored plus blocking `dev:setup`, then cd the invoking interactive shell into it. |
| `wt -t cd NAME` | Same as `wt NAME` (explicit escape spelling). |
| `wt -t w NAME` (`-t window`) | Same lifecycle; inside tmux, create or reuse one tagged `wt:<id>` window in the current session — left pane interactive shell (60%), right pane `mise run dev:services` or a shell (40%). Outside tmux, falls back to cd behavior. |
| `wt -t s NAME` (`-t session`) | Same lifecycle; create or repair the canonical per-worktree session (`code`, `agent`, `services` windows) and switch/attach to it. |
| `wt open NAME` | Alias for the session presentation. |
| `wt ensure NAME [--json]` | Full lifecycle with no presentation: never cds, selects, or attaches. Preferred for agents. |
| `wt new NAME [--base BRANCH]` | Like ensure, but refuses when the branch already exists locally or on a remote. |
| `wt repair` | Bare: infer the containing checkout from the cwd (nested directories and the primary checkout both work), run full setup, and repair the canonical session. Never attaches. `wt repair NAME` targets another worktree. |
| `wt path NAME` / `wt path .` | Print the validated worktree path (`.` resolves the containing checkout). |
| `wt list --json` | Normalized JSON: `.items[].branch`, `.items[].worktree.path`. |
| `wt prune NAME` | Safe removal of one clean, integrated (or empty), non-main, non-current local worktree: removes the tmux session, then the worktree and branch, then verifies. |
| `wt id [path]` | Print the `GIT_WORKTREE` id (`{repo}-{branch-slug}`); empty in the primary checkout. |

The primary checkout is a valid target: it skips copy-ignored and unsets `GIT_WORKTREE`. Upstream builtins (`wt list`, `wt merge`, `wt step`, `wt hook`, `wt config`, `wt remove`, `wt switch`) pass through to Worktrunk unchanged.

## Agent usage

Agent bash calls cannot change the parent shell cwd, so the cd presentation only helps interactive shells. From an agent:

```bash
wt ensure feature/login --json          # full setup, structured result, no attach
wtp="$(wt path feature/login)"          # then run commands from that path
cd "$wtp" && mise run <task>
```

- JSON results are one `schema_version: 1` document. `.status` is `ok`, `refused`, `partial`, or `error`; `.error.code` names the failure; `.completed_phases` shows progress.
- Use `-t w` / `-t s` only when the user asked for tmux presentation. Both are idempotent: they reuse tagged windows/sessions and never duplicate or kill panes.
- `busy` errors mean another `wt`/`ftm` operation holds the repository or worktree lock; wait and retry rather than working around it.
- Setup and services run through project mise tasks (`dev:setup`, `dev:services`). A missing task is reported `missing`, not failed. Do not start project services yourself; the services pane or `wt repair --restart-services` owns that.

## Prune and recovery

`wt prune NAME` refuses (exit 3/6, `.status == "refused"`): dirty worktrees, branches not `integrated`/`empty`, the main worktree, the worktree you are standing in, remote-only targets, and ambiguous tmux session matches.

Partial results (`.status == "partial"`, e.g. the tmux session was removed but Worktrunk removal failed or the branch moved): nothing retries with force. Recover with `wt repair NAME` to rebuild the session, fix the reported cause, then rerun `wt prune NAME`. Never fall back to `git worktree remove`, `git branch -D`, or `wt remove --force*` without explicit user approval — those destroy the safety checks prune exists for.

A background auto-prune (`wt step prune`, throttled daily per repo) also removes merged worktrees; unexpected disappearance of an integrated worktree is normal.

## Project templates

Project config lives at `<repo>/.config/wt.toml` plus a mise stub. Generate only when missing and the stack is known:

```bash
mise run gen:elixir      # mise task stub (dev:setup / dev:services)
mise run gen:wt-elixir   # Worktrunk hook config
mise run gen:shopify && mise run gen:wt-shopify
```

Generation is idempotent; do not overwrite existing config or guess the stack. `wt` still works without a template — setup and services are then reported `missing`.

## Rules

- Use `wt`, never bare `worktrunk` or raw `git worktree`, while the availability gate passes.
- Prefer `wt ensure --json` + `wt path` in agent contexts; presentation flags only on user request.
- Use `wt list --json` for discovery and `wt id` for the worktree id.
- Keep worktree commands scoped with `cd "$(wt path NAME)"` or `wt -C`.
- Use `wt prune` for cleanup; `wt remove` only as an approved upstream escape.
- If `wt` is unavailable, use only the preserved legacy reference.
