---
name: git-worktrees
description: >-
  All Git worktree work through our custom `wt` (~/.dotfiles/bin/wt, v2): create, open, list, repair, prune, and hand work off to a new Pi agent in a fresh worktree. Use when the user mentions a worktree, `wt`, branching work into a new checkout, or says things like "tell the agent in a new worktree X to take over this work" (optionally "in a window").
---

# Worktrees

`wt` is `~/.dotfiles/bin/wt`, the v2 lifecycle wrapper over a pinned Worktrunk backend. One `wt` call creates or reuses the worktree under `<repo>/.worktrees/<branch>`, copies ignored files, runs blocking `mise run dev:setup`, exports `GIT_WORKTREE`, and builds the tmux presentation through `ftm`. Do not repeat any of that by hand.

It works from any checkout of the repo: the primary checkout or any linked worktree. New worktrees always land under the primary repo's `.worktrees/`.

Never:

- run raw `git worktree`, `git branch -D`, or `wt remove --force*`;
- build tmux windows or sessions yourself, or start `dev:services` yourself;
- compute `GIT_WORKTREE` (use `wt id [path]`);
- use `wt switch` (raw upstream passthrough: no setup, no tmux).

If `wt --version` fails, stop and report the error. There is no fallback workflow.

## Commands

| Command | Effect |
| --- | --- |
| `wt NAME` | Ensure worktree + setup, build the canonical session (`code`, `agent` running `pi -c`, `services` running `dev:services`), switch the client to it. |
| `wt -t w NAME` | Same lifecycle; one `wt:<id>` window in the current session. Left pane (60%) is a shell, right pane (40%) runs `dev:services`. Outside tmux falls back to cd. |
| `wt -t cd NAME` | Same lifecycle; only cd the interactive shell. No tmux. |
| `wt ensure NAME --json` | Same lifecycle; builds the canonical session detached. Never cds, selects, or attaches. |
| `wt new NAME [--base B]` | Like `ensure`, but refuses if the branch exists locally or on a remote. |
| `... --no-services` | Full lifecycle, but the services pane/window stays a plain shell. Use only when the user asks for no services. |
| `... --base B` | Base for a new branch only (error if the branch exists). Shortcuts: `@` current HEAD, `^` default branch, `-` previous branch. |
| `wt repair [NAME] [--restart-services]` | Rerun setup and rebuild the session. Never attaches. |
| `wt path NAME` / `wt path .` | Print the validated worktree path. |
| `wt list --json` | `.repo.default_branch`, `.items[].branch`, `.items[].worktree.path`. |
| `wt prune NAME` | Safe removal of a clean, integrated, non-current worktree plus its session and branch. |
| `wt id [path]` | `GIT_WORKTREE` id (`{repo}-{branch-slug}`); empty in the primary checkout. |

All `--json` results are one `schema_version: 1` document. `.status` is `ok`, `refused`, `partial`, or `error`; `.error.code` names the failure; `.completed_phases` shows progress. `busy` means another `wt`/`ftm` holds the lock: wait and retry.

Agent bash calls can't change the parent shell's cwd. Run follow-up commands with `cd "$(wt path NAME)" && ...`.

## Choosing the base for a new branch

Only when `NAME` doesn't exist yet (no local branch, no `origin/NAME`). An existing branch gets no `--base`.

```bash
default="$(wt list --json | jq -r '.repo.default_branch // "main"')"
current="$(git branch --show-current)"
git rev-parse --verify --quiet "refs/heads/$NAME" >/dev/null ||
  git rev-parse --verify --quiet "refs/remotes/origin/$NAME" >/dev/null || echo new
```

- If `current` is the default branch (or empty/detached): use the default branch without asking.
- Otherwise ask with `ask_user_question` (header "Base branch"):
  - `<default> (latest origin)` (Recommended)
  - `<current> (local HEAD)`
- Default branch: always `git fetch origin "$default"` first, then pass `--base "origin/$default"`. Local `main` can be stale and `wt` never fetches.
- Current branch: pass `--base @`. If `git status --porcelain` is non-empty, warn that uncommitted changes stay behind.

## Hand work to a new agent ("tell the agent in a new worktree X ...")

1. Pick the base (section above).
2. Write the handoff brief before creating anything. It must stand alone: goal, context and decisions from this conversation, relevant files, what's done, next steps, how to verify. Add the reply target `pi:$(hostname -s):$PI_SESSION_ID` so the new agent can report back.
3. Create the worktree and start Pi:

   In a window (user said "in a window"):

   ```bash
   out="$(wt -t w NAME --base BASE --json)"; echo "$out"
   path="$(jq -r .worktree.path <<<"$out")"
   pane="$(jq -r .tmux.left_pane <<<"$out")"
   win="$(jq -r .tmux.window_id <<<"$out")"
   tmux send-keys -t "$pane" '"$HOME/.local/bin/pi"' Enter
   ```

   Default (own session; `ftm` starts `pi -c` in its `agent` window):

   ```bash
   out="$(wt ensure NAME --base BASE --json)"; echo "$out"
   path="$(jq -r .worktree.path <<<"$out")"
   id="$(jq -r .worktree.id <<<"$out")"
   pane=  # match on cwd only
   ```

   Stop and report if `.status != "ok"`.

4. Wait for the new Pi to register, then build its tell id:

   ```bash
   for _ in $(seq 60); do
     sid="$(jq -rs --arg cwd "$path" --arg pane "$pane" \
       '[.[] | select(.cwd == $cwd and ($pane == "" or .pane == $pane))][0].sessionId // empty' \
       "${PI_STATE_DIR:-$HOME/.local/state/pi}"/manifests/*.info 2>/dev/null)"
     [ -n "$sid" ] && break; sleep 1
   done
   echo "pi:$(hostname -s):$sid"
   ```

   On timeout, run `list_pi_sessions` and match the worktree path (and pane). Don't guess.

5. Send the brief with `tell_pi` (target = that exact id, message = brief).
6. Switch the user over: `tmux select-window -t "$win"` (window) or `ftm "$id"` (session).
7. Report the worktree path, branch, base, tell id, and the services state from `.tmux`.

Use `wt ensure NAME --json` with no tell when the user only wants a worktree created. Plain `wt NAME` and `-t w` without `--json` are for when the user asks to open it themselves.

## Prune and recovery

`wt prune NAME` refuses (exit 3/6, `.status == "refused"`) for: dirty worktrees, branches not integrated or empty, the main worktree, the worktree you are in, remote-only targets, and ambiguous tmux sessions. Report the refusal; don't work around it.

On `.status == "partial"`, nothing retries with force. Run `wt repair NAME`, fix the reported cause, then rerun `wt prune NAME`. Destructive escapes need explicit user approval.

A background auto-prune (`wt step prune`, daily per repo) removes merged worktrees, so an integrated worktree disappearing is normal.

## Project templates

Setup and services come from `<repo>/.config/wt.toml` plus the project's `dev:setup` / `dev:services` mise tasks. If a task is missing, `wt` reports it `missing` rather than failing. Generate config only when it's missing and the stack is known (`mise run gen:elixir && mise run gen:wt-elixir`, `mise run gen:shopify && mise run gen:wt-shopify`). Never overwrite existing config.
