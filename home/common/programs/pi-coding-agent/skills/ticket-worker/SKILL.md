---
name: ticket-worker
description: Work on a single tk ticket end-to-end. Use when the user says 'work on ticket X' or when spawned by work-tickets.sh.
---

# Ticket worker

Work on a single ticket from start to finish. Follow each step in order. Do not skip verification.

## VCS detection

Detect which VCS is in use at the start of every session:

```bash
if command -v jj >/dev/null 2>&1 && jj root >/dev/null 2>&1; then
  VCS=jj
else
  VCS=git
fi
```

Use `$VCS` for all version control operations below.

## Workflow

### 1. Read the ticket

```bash
tk show <id>
```

Check for `ready-for-development` tag. If missing, **stop** — ticket not refined:

```bash
tk add-note <id> "Skipped: ticket not tagged ready-for-development. Needs refinement."
```

If tag present, mark in progress:

```bash
tk start <id>
```

### 2. Check VCS state

Before any work, check current VCS status:

```bash
# jj
jj status && jj log -n 3

# git
git status && git log --oneline -3
```

Ensure working directory is clean or that uncommitted changes are unrelated to this ticket.

### 3. Explore the codebase

- If `lat.md/` exists at project root: run `lat search` with keywords from the ticket
- Read files mentioned in description
- grep for relevant patterns, function names, imports
- Understand scope of changes needed
- Do not start implementing yet

### 4. Discover verification commands

Check in order:

1. `devenv.nix` — scripts, tasks, processes, git-hooks, test commands
2. `package.json` — scripts.test, scripts.lint, scripts.build
3. `Makefile` — test, lint, check, build targets
4. `flake.nix` — checks

Remember what you find — you need these after every change.

### 5. Implement incrementally

- Make one focused change
- Run verification commands from step 4
- If broken: fix before moving on
- If context is getting heavy: commit what you have, stop — next session continues

### 6. Verify each acceptance criterion

Go through criteria one by one:

- Command specified → run it, check output
- "tests pass" → run test suite
- "linter clean" → run linter
- Behavioral → verify by reading code or running relevant commands
- State whether each criterion passes or fails

If `lat.md/` exists: run `lat check`. Update lat.md if needed. Ticket not done with failing `lat check`.

Do not declare victory until every criterion is verified.

### 7. Commit and close

If all acceptance criteria pass:

1. **Generate commit title** — brief conventional commit: `type(scope): description`
2. **Prompt developer for description:**
   > "Ready to commit as `type(scope): title`. Want to add a detailed description before committing?"
   - If yes: wait for developer input, include as commit body
   - If no: commit with title only
3. **Commit:**
   ```bash
   # jj
   jj describe -m "type(scope): title"
   # or with description:
   jj describe -m "type(scope): title" -m "Detailed description from developer"

   # git
   git add -A && git commit -m "type(scope): title"
   # or with description:
   git add -A && git commit -m "type(scope): title" -m "Detailed description"
   ```
4. **Close ticket:** `tk close <id>`
5. **Add summary note:** `tk add-note <id> "Summary of what was done"`
6. **Suggest next work** (see section below)
7. **Prompt for next action:**
   > "Ticket closed. Push to remote, or move to next ticket?"

### 8. If stuck

1. Add blocker note: `tk add-note <id> "Blocked because..."`
2. Do not close the ticket
3. Commit partial progress if it makes sense:
   ```bash
   # jj
   jj describe -m "wip(scope): partial work on <ticket>"

   # git
   git add -A && git commit -m "wip(scope): partial work on <ticket>"
   ```
4. Exit cleanly

## Suggesting next work

After closing a ticket (step 7.6), evaluate what to work on next:

```bash
# Show unblocked, ready tickets sorted by priority
tk ready -T ready-for-development
```

Present top 1–3 candidates to the developer with:
- Ticket ID + title
- Priority level
- Whether it was newly unblocked by the just-closed ticket (check deps)

If an associated plan exists, check it for recommended ordering:

```bash
# Look for plan files in the plans dir
ls ~/.local/share/pi/plans/"$(basename "$PWD")"/*_PLAN.md 2>/dev/null
```

If a plan exists and its steps have an ordering, prefer the plan's sequence over raw priority. Mention this: "Per plan X, next step is Y."

If `tk ready` returns nothing:
- Check `tk blocked` — are remaining tickets waiting on external work?
- Check `tk list --status=open` — are there unrefined tickets that need `/refine`?
- If all tickets are closed, say so: "All tickets complete."

## Rules

- **Verify, don't assume.** Run commands. Check output.
- **Stay focused.** Only change files relevant to the ticket.
- **No bonus refactoring.** Fix what the ticket asks, nothing more.
- **Weak acceptance criteria?** Fall back to: description satisfied + existing tests pass.
- **One ticket per session.** Don't carry context from unrelated work.
- **One ticket = one commit.** Each ticket produces exactly one VCS commit.
- **Work in current checkout.** Worktree support planned but not active.
- **Commit message format.** Conventional commits, brief title. Developer provides description.
- **VCS-agnostic.** Use jj if available, git otherwise. Never hardcode one.
