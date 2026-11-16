---
name: git-worktrees
description: >-
  All Git worktree work through `rwt` (~/.dotfiles/bin/rwt): create, open, check, restart services, prune, and hand work off to the Pi agent in a new or existing worktree's Rex session. Use when the user mentions a worktree, `rwt` (or the old `wt`), branching work into a new checkout, or says things like "tell the agent in a new worktree X to take over this work".
---

# Worktrees

`rwt` is `~/.dotfiles/bin/rwt`. One worktree is one Rex session, labeled with the worktree id. One `rwt new` call creates or reuses the worktree under `<repo>/.worktrees/<branch, / as ->`, clones the ignored paths listed in the main checkout's `.worktreeinclude`, runs the project's `mise run dev:setup` in a visible `setup` tab, and builds the session: `code` (shell), `services:<port>` (`dev:services`), and `agent` (Pi). Don't repeat any of that by hand.

It works from any checkout of the repo; new worktrees always land under the main checkout's `.worktrees/`.

Never:

- run raw `git worktree add/remove` or `git branch -D` on a worktree branch;
- build Rex sessions, tabs or blocks yourself, or start `dev:services` yourself (use `rwt restart`);
- use `ftm` or tmux sessions/windows for worktrees (`wt` is gone; `ftm` stays only for tmux by hand);
- compute `GIT_WORKTREE` yourself (use `rwt id [NAME|PATH]`).

If `rwt` fails to run, stop and report the error. There is no fallback workflow.

## Naming

In repos under `~/code/work/strive/` (provider_portal, rx, devops, ...), name every new worktree `sm-<short name of the work>`: lowercase kebab-case chosen from the task, at most 5 words and 40 characters after `sm-`, e.g. `sm-expand-onboarding-reporting`. Never generic (`sm-fix`, `sm-wip`). `rwt new` adds a missing `sm-` (and prints the final name) and refuses anything else with exit 2; reopening an existing worktree by its name still works.

## Commands

| Command | Effect |
| --- | --- |
| `rwt new NAME [--base REF] [--prompt TEXT]` | Ensure the worktree and its session. A new branch starts at `REF` (default: the local default branch); an existing local branch is checked out; an `origin/NAME`-only branch is tracked. Blocks while setup runs. Same as `rwt open`. |
| `rwt open [NAME\|PATH]` | Ensure worktree and session; reuse a live session and restart a missing services tab. Rebuilds a session whose setup failed. |
| `rwt status [NAME\|PATH]` | Always JSON: `.worktree{path,branch,id,dirty}`, `.session{id,label}` or null, `.services{running,last_exit,...}` or null, `.port`, `.http{app,tidewave,tidewave_url}`, `.pidewave`. |
| `rwt ls` | Always JSON: `.worktrees[]{path,branch,session}` for every worktree of the repo. Detached ones (such as Ultimate's lander checkout) have `branch: null`; skip them. |
| `rwt wait-ready [NAME\|PATH] [--timeout S]` | Block until the app answers on its port (default 180 s). Use it instead of a poll loop. |
| `rwt logs [NAME\|PATH] [-n N]` | Last N lines (default 200) of the services tab. |
| `rwt restart [NAME\|PATH]` | Stop the server and start `dev:services` in a fresh terminal in the same place. |
| `rwt prune NAME\|PATH` | Remove a clean, merged worktree, its session, and its branch. |
| `rwt id [NAME\|PATH]` | The `GIT_WORKTREE` id (`{repo}-{branch slug}`) that names the worktree's database and port; empty in the main checkout. |

No target means the checkout you're in. Flags:

- `--json` (`new`, `open`, `restart`, `prune`): one JSON object on stdout, progress on stderr. Any failure under `--json` prints `{ok:false, code, error}`. `status` and `ls` always print JSON; `logs` prints the raw scrollback and `wait-ready` prints nothing on stdout (check its exit code).
- `--show` (`new`, `open`): switch the Rex app to the worktree's session.
- `--prompt TEXT` (`new`, `open`): the first message for the agent tab's Pi. It only works when `rwt` creates the session; with a live session it refuses (exit 6), so use `tell_pi` instead.
- `--no-services`, `--no-agent` (`new`, `open`): leave that tab out of a session `rwt` creates; they don't remove tabs from a live session. Use only when the user asks, or for a read-only checkout.

Exit codes: 0 ok, 2 usage, 3 not found, 4 setup failed (the `setup` tab keeps the full output; rerun `rwt open` after fixing it), 6 refused, 7 other.

`rwt new`/`open` wait for setup, up to 30 minutes: give the bash call a long timeout (1800 s). Pi in the `agent` tab starts once the app answers (or after 180 s): fresh in a just-created worktree, `pi -c` otherwise.

Agent bash calls can't change the parent shell's cwd. Run follow-up commands with `cd "$(rwt status NAME | jq -r .worktree.path)" && ...`.

## Choosing the base for a new branch

Only when `NAME` doesn't exist yet (no local branch, no `origin/NAME`). An existing branch ignores `--base`.

```bash
default="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"; default="${default#origin/}"; default="${default:-main}"
current="$(git branch --show-current)"
git rev-parse --verify --quiet "refs/heads/$NAME" >/dev/null ||
  git rev-parse --verify --quiet "refs/remotes/origin/$NAME" >/dev/null || echo new
```

- If `current` is the default branch (or empty/detached): use the default branch without asking.
- Otherwise ask with `ask_user_question` (header "Base branch"):
  - `<default> (latest origin)` (Recommended)
  - `<current> (local HEAD)`
- Default branch: always `git fetch origin "$default"` first, then pass `--base "origin/$default"`. Local `main` can be stale and `rwt` never fetches.
- Current branch: pass `--base "$current"`. If `git status --porcelain` is non-empty, warn that uncommitted changes stay behind.

## Hand work to an agent in a new or existing worktree

Whenever a request names a worktree (new or existing) and includes any work, always hand the work to the Pi agent in that worktree's Rex session, even if the user doesn't say "tell the agent". Examples: "new wt X - fix Y", "in wt X, do Y", "tell the agent in a new worktree X to Y". Never do the work yourself from the calling session.

You only orchestrate; the agent in the worktree does the work. Your whole job: resolve or create the worktree, get the brief to its agent, switch the user over, and report.

- Never do any of the task yourself: no edits, commands, tests, or commits in the target worktree, before or after the handoff, and no continuing it in your own checkout.
- If a step fails (`rwt` error, `tell_pi` error), stop and report it. Never fall back to doing the work yourself.
- Communication is one-way by default. You send one brief; don't wait for, poll for, or expect a reply, and don't send follow-up tells. Updates flow back only when the user's initial request asks for them ("keep me posted", "report back", "let me know when it's done").

1. Resolve the target: `st="$(rwt status NAME)"`. The worktree exists when `[ -d "$(jq -r .worktree.path <<<"$st")" ]`; a live session shows as a non-null `.session`. If the user names the worktree loosely, match it against the `rwt ls` items with a non-null `.branch`, pass the matching path instead of NAME, and ask when more than one fits.
2. Write the handoff brief before creating or starting anything. Every brief, for a new or existing worktree, must stand alone and always include:
   - Explicit instructions: what the agent should do, as a direct task, not just background.
   - Goal, context and decisions from this conversation, relevant files, what's done, next steps, how to verify.
   - A closing section on communication. By default, end with:

     > Do not contact the calling agent. Send it no `tell_pi` or `/tell` messages: no progress, questions, or final report. Work with the user directly in this session.

     Only when the user's initial request asks for updates, end with this instead. Fill in the reply target from `echo "pi:$(hostname -s):$PI_SESSION_ID"`:

     > Report meaningful updates to the calling agent with `tell_pi` (target `<reply target>`, mode `follow_up`): when you start, at each milestone, when you are blocked or need a decision, and when done, with verification results. Skip step-by-step chatter. Keep working with the user directly in this session.

   Put the brief in a shell variable with a quoted heredoc so no quoting breaks it:

   ```bash
   brief="$(cat <<'BRIEF'
   ...
   BRIEF
   )"
   ```
3. Deliver it.
   - **New worktree, or an existing worktree with no session** (`.session == null`): the brief becomes Pi's first message.

     ```bash
     rwt new NAME --base BASE --prompt "$brief" --json --show   # new: pick BASE first (section above)
     rwt open NAME --prompt "$brief" --json --show              # existing worktree, no session
     ```

     Stop and report on a non-zero exit. In an existing worktree Pi starts with `pi -c`, so it keeps the directory's earlier context.
   - **Live session** (`.session != null`): run `rwt open NAME --json --show` (repairs services, switches the user over), then send the brief with `tell_pi`, target `rex:<.session.id>/agent` (for example `rex:session:01a1…/agent`). Keep the default `follow_up` mode so a busy agent gets it after its current turn; use `steer` only when the user wants to interrupt it. Never type the brief into the terminal. The brief is the only message you send.

     If `tell_pi` finds no target there, Pi isn't running in the `agent` tab. Stop and ask the user to start it in that tab (`pi -c`), then send the brief once they confirm. Don't guess another Pi.
4. Report the worktree path, branch, base (new worktrees only), Rex session label, how the brief went (first prompt, or the `tell_pi` target), whether updates were requested, and the port and services state from `rwt status`. Then end your turn. If updates were requested, relay each one to the user when it arrives; don't act on the work yourself.

Use `rwt new NAME --json` with no prompt only when the user asks for a worktree and gives no work. Add `--show` when they want to look at it.

## Prune

`rwt prune NAME|PATH` refuses (exit 6) for: the main checkout, the worktree you are in, a detached checkout, uncommitted or untracked changes, and a branch that is neither merged into the default branch (local or `origin/`) nor the head of a merged PR. Report the refusal; don't work around it. There is no force flag, and destructive escapes need explicit user approval.

## Project setup

Setup and services come from the project's `dev:setup` and `dev:services` mise tasks; a missing task is skipped. `rwt` clones the plain paths listed in the main checkout's `.worktreeinclude` (no globs) into each new worktree. `<repo>/.config/rex/layout.lua` replaces the default layout (`~/.dotfiles/config/rex/rwt-layout.lua`); keep its `services` block label. Generate missing config only when the stack is known (`mise run gen:elixir`, `mise run gen:shopify`, which also sync `.worktreeinclude`). Never overwrite existing config.
