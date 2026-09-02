---
name: ticket-worker
description: Work on a single tk ticket end-to-end. Use when the user says 'work on ticket X' or when spawned by work-tickets.sh.
---

# Ticket worker

Work on a single ticket from start to finish. Follow each step in order. Do not skip verification.

## Workflow

### 1. Read the ticket

```bash
tk show <id>
```

Check that the ticket has the `ready-for-development` tag. If it doesn't, **stop** — the ticket is not refined enough for automated work. Add a note and exit:

```bash
tk add-note <id> "Skipped: ticket not tagged ready-for-development. Needs refinement before work can start."
```

If the tag is present, mark the ticket as in progress:

```bash
tk start <id>
```

Understand the title, description, acceptance criteria, and any file hints.

### 2. Explore the codebase

- If `lat.md/` exists at project root: run `lat search` with keywords from the ticket title and description. Read relevant sections with `lat section` to understand the architecture before exploring code files.
- Read the files mentioned in the description
- grep for relevant patterns, function names, imports
- Understand the scope of changes needed
- Do not start implementing yet

### 3. Discover verification commands

Check these files in order to find how to build, test, and lint:

1. `devenv.nix` — look for `scripts`, `tasks`, `processes`, `git-hooks`, test commands
2. `package.json` — look for `scripts.test`, `scripts.lint`, `scripts.build`
3. `Makefile` — look for `test`, `lint`, `check`, `build` targets
4. `flake.nix` — look for `checks`

Remember what you find. You will need these after every change.

### 4. Implement incrementally

- Make one focused change
- Run the verification commands you discovered in step 3
- If broken: fix before moving on
- If context is getting heavy: commit what you have, stop — the next session can continue

### 5. Verify each acceptance criterion

Go through the acceptance criteria one by one. For each criterion:

- If it specifies a command: run that command and check the output
- If it says "tests pass": run the test suite
- If it says "linter clean": run the linter
- If it is behavioral: verify by reading the changed code or running relevant commands
- Explicitly state whether each criterion passes or fails

If `lat.md/` exists at project root: run `lat check`. If it fails, update `lat.md/` to reflect your changes and re-run until it passes. The ticket is not complete with a failing `lat check`.

Do not declare victory until every criterion is verified.

### 6. Commit and close

If all acceptance criteria pass:

1. Commit using the conventions in the `git-commit` skill (`git commit -S -m "type(scope): description"`). If `lat.md/` was updated, include those changes in the same commit.
2. Close the ticket: `tk close <id>` (not `done` — `done` is not a valid status)
3. Add a summary note: `tk add-note <id> "Summary of what was done"`

### 7. If stuck

If you cannot complete the ticket:

1. Add a note to the ticket explaining the blocker: `tk add-note <id> "Blocked because..."`
2. Do not close the ticket
3. Commit any partial progress if it makes sense
4. Exit cleanly

## Rules

- **Verify, don't assume.** Run the commands. Check the output.
- **Stay focused.** Only change files relevant to the ticket.
- **No bonus refactoring.** Fix what the ticket asks, nothing more.
- **Weak acceptance criteria?** Fall back to: description satisfied + existing tests pass.
- **One ticket per session.** Don't carry context from unrelated work.
- **Work in the current checkout.** The pipeline handles worktree setup (task-pipeline skill). When invoked manually or via work-tickets.sh, just work in the current directory.
- **Commit message format.** Always use conventional commits, single line, GPG-signed, no AI attribution.
