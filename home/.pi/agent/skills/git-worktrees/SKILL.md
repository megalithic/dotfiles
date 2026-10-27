---
name: git-worktrees
description: >-
  All Git worktree work through our custom `wt` (~/.dotfiles/bin/wt, v2): create, open, list, repair, prune, and hand work off to a Pi agent in a new or existing worktree. Use when the user mentions a worktree, `wt`, branching work into a new checkout, or says things like "tell the agent in a new worktree X to take over this work" (optionally "in a window").
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
| `wt NAME` | Ensure worktree + setup, build the canonical session (`code`, `agent` running Pi, `services` running `dev:services`), switch the client to it. Pi starts fresh in a just-created worktree and as `pi -c` otherwise. |
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

## Hand work to an agent in a new or existing worktree ("tell the agent in a new worktree X ...")

1. Resolve the target: `path="$(wt path NAME)"`. Exit 3 (`target_not_found`) means no worktree exists yet: use 3a. Otherwise use 3b. If the user names the worktree loosely, match it against the `wt list --json` items that have a non-null `.worktree.path`, and ask when more than one fits.
2. Write the handoff brief before creating or starting anything. Every brief, for a new or existing worktree, must stand alone and always include:
   - Explicit instructions: what the agent should do, as a direct task, not just background.
   - Goal, context and decisions from this conversation, relevant files, what's done, next steps, how to verify.
   - A closing line: "No communication back to the calling agent is needed; work with the user directly." Only when the user asks for updates or a report, replace it with that request and the reply target `pi:$(hostname -s):$PI_SESSION_ID`.
3. Get a live agent in the worktree.

   Each bash call is a fresh shell, so define these helpers in every call that uses them. `find_agents PATH` lists live Pi agents whose cwd is exactly `PATH`. It skips stale manifests (no heartbeat for 60s; Pi beats every 10s), headless `pi -p` runs (no tmux pane), and you. `agent_pane PATH` prints `<pane_id> <command>` for the `agent` window of the ftm session tagged with that worktree.

   ```bash
   find_agents() {
     jq -s -c --arg cwd "$1" --arg self "${PI_SESSION_ID:-}" --argjson now "$(date +%s)" '
       [.[] | select(.cwd == $cwd and .pane != null and .sessionId != null and .sessionId != $self
                     and ($now - (.heartbeatAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) < 60)
        | {sessionId, session, window, pane, state, sessionName}]' \
       "${PI_STATE_DIR:-$HOME/.local/state/pi}"/manifests/*.info 2>/dev/null
   }
   agent_pane() {
     tmux list-panes -a -F '#{@ftm_worktree}|#{window_name}|#{pane_id} #{pane_current_command}' |
       awk -F'|' -v p="$1" '$1 == p && $2 == "agent" { print $3; exit }'
   }
   ```

   **3a. New worktree.** Pick the base (section above), then create the worktree and start Pi.

   In a window (user said "in a window"):

   ```bash
   out="$(wt -t w NAME --base BASE --json)"; echo "$out"
   path="$(jq -r .worktree.path <<<"$out")"
   pane="$(jq -r .tmux.left_pane <<<"$out")"
   win="$(jq -r .tmux.window_id <<<"$out")"
   tmux send-keys -t "$pane" '"$HOME/.local/bin/pi"' Enter
   ```

   Default (own session; `ftm` starts a fresh `pi` in its `agent` window, never resuming sessions left by an earlier worktree at the same path):

   ```bash
   out="$(wt ensure NAME --base BASE --json)"; echo "$out"
   path="$(jq -r .worktree.path <<<"$out")"
   id="$(jq -r .worktree.id <<<"$out")"
   pane="$(agent_pane "$path" | cut -d' ' -f1)"
   ```

   Stop and report if `.status != "ok"`. Then wait for registration (step 4).

   **3b. Existing worktree.** Don't run `wt` first; look for a live agent:

   ```bash
   find_agents "$path"; agent_pane "$path"
   ```

   - One agent: use its `sessionId` and skip step 4.
   - Several: use the one whose `.pane` matches the `agent_pane` id. If none matches, ask with `ask_user_question`, one option per agent showing `session:window`, `state`, and `sessionName`. Don't guess.
   - None: start Pi in the worktree's `agent` window, then wait for registration (step 4). `pi -c` resumes that directory's latest session, so the agent keeps its earlier context.

     ```bash
     read -r pane cmd <<<"$(agent_pane "$path")"
     if [ -z "$pane" ]; then
       out="$(wt ensure NAME --json)"; echo "$out"
       read -r pane cmd <<<"$(agent_pane "$path")"
     else
       case "$cmd" in
         fish|zsh|bash|sh) tmux send-keys -t "$pane" '"$HOME/.local/bin/pi" -c' Enter ;;
         *) echo "agent pane runs $cmd, not a shell" ;;
       esac
     fi
     ```

     With no `agent` window, `wt ensure` rebuilds the session (rerunning setup) and starts `pi -c` itself; stop and report if `.status != "ok"`. If the pane runs anything other than a shell, stop and report it. Never type into it.

4. Wait for a newly started Pi to register, then build its tell id:

   ```bash
   for _ in $(seq 60); do
     sid="$(find_agents "$path" | jq -r --arg pane "$pane" \
       '[.[] | select($pane == "" or .pane == $pane)][0].sessionId // empty')"
     [ -n "$sid" ] && break; sleep 1
   done
   echo "pi:$(hostname -s):$sid"
   ```

   On timeout, run `list_pi_sessions` and match the worktree path and pane. Ignore entries marked `busy/unreachable`; they are stale. Don't guess.

5. Send the brief with `tell_pi` (target = `pi:$(hostname -s):<sessionId>`, message = brief). Keep the default `follow_up` mode so a busy agent gets the brief after its current turn. Use `steer` only when the user wants to interrupt it.
6. Switch the user over:
   - 3a window: `tmux select-window -t "$win"`.
   - 3a session: `ftm "$id"`.
   - 3b: `tmux switch-client -t "$session" \; select-window -t "$pane" \; select-pane -t "$pane"`, using the agent's `.session` and `.pane`.
7. Report the worktree path, branch, base (new worktrees only), tell id, whether the agent was found or started, and the services state from `.tmux` when `wt` ran.

Use `wt ensure NAME --json` with no tell when the user only wants a worktree created. Plain `wt NAME` and `-t w` without `--json` are for when the user asks to open it themselves.

## Prune and recovery

`wt prune NAME` refuses (exit 3/6, `.status == "refused"`) for: dirty worktrees, branches not integrated or empty, the main worktree, the worktree you are in, remote-only targets, and ambiguous tmux sessions. Report the refusal; don't work around it.

On `.status == "partial"`, nothing retries with force. Run `wt repair NAME`, fix the reported cause, then rerun `wt prune NAME`. Destructive escapes need explicit user approval.

A background auto-prune (`wt step prune`, daily per repo) removes merged worktrees, so an integrated worktree disappearing is normal.

## Project templates

Setup and services come from `<repo>/.config/wt.toml` plus the project's `dev:setup` / `dev:services` mise tasks. If a task is missing, `wt` reports it `missing` rather than failing. Generate config only when it's missing and the stack is known (`mise run gen:elixir && mise run gen:wt-elixir`, `mise run gen:shopify && mise run gen:wt-shopify`). Never overwrite existing config.
