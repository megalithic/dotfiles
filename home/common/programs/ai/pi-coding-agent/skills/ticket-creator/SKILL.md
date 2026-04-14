---
name: ticket-creator
description: Create and refine tickets for the tk ticket system. Use when the user says 'create tickets for X', 'refine ticket X', 'break this into tickets', 'seed tickets from plan', or anything about creating or refining tk tickets.
---

# Ticket creator

Create well-structured tickets that the ticket-worker skill can consume without ambiguity.

## Ticket format contract

Every ticket must have:

| Field               | Required           | How                                                                            |
| ------------------- | ------------------ | ------------------------------------------------------------------------------ |
| Title               | Yes                | Imperative, scoped action: `tk create "Add rate limiting to auth endpoints"`   |
| Description         | Yes                | What to do, why, and file hints (`see src/auth/`)                              |
| Acceptance criteria | Yes                | Numbered, each independently verifiable. Prefer criteria that map to a command |
| Type                | Yes                | `bug`, `feature`, `task`, `epic`, `chore`                                      |
| Dependencies        | When order matters | `tk dep <id> <blocks-id>` — the second arg depends on the first                |
| Parent              | For subtasks       | `--parent <epic-id>` — ticket is a subtask of an epic                          |

### Good ticket example

```bash
tk create "Fix token refresh returning 401 on expired tokens" \
  -d "The /auth/refresh endpoint returns 401 when the refresh token is expired.
Should return 403 with a clear error message instead.
Relevant code in src/auth/refresh.ts and src/auth/middleware.ts." \
  --acceptance "1. POST /auth/refresh with expired token returns 403 (not 401)
2. Response body includes 'error' field with descriptive message
3. Existing tests pass
4. New test covers expired token case" \
  -t bug
```

### Bad ticket example

```bash
tk create "Fix the bug" -d "There's a bug somewhere in auth"
```

No acceptance criteria, no file hints, no verification command. The agent will wander.

## Acceptance criteria guidelines

- Each criterion must be independently verifiable
- Prefer criteria that map to a command: "tests pass", "linter clean", "curl returns X"
- Always include "existing tests still pass" as one criterion (unless no tests exist)
- For refactors: "behavior unchanged" + "tests pass" is sufficient
- Never use vague criteria like "code is clean" or "well-structured"

## Parent vs dependency

Use `--parent` when one ticket is a logical subtask of an epic (e.g., "implement login form" under "add auth system"). Use `dep` when two tickets are independent work items where one must finish before the other starts. When in doubt, use `dep` — it's the more common relationship.

Only add `dep` when there is a real ordering constraint (e.g., ticket B requires code that ticket A will create). If two tickets could be worked on in parallel, do not link them with deps.

## Tagging rule

Only add `--tags ready-for-development` when the ticket is fully refined: description, acceptance criteria, and file hints are all present. Vague or wishlist tickets should have **no tag** — they live in the backlog until refined.

Refining is done via Mode 4 — do not hand-edit YAML frontmatter.

## Size rule

A single ticket should be completable in one agent session (~30 min of agent work). If a task is larger, split it into multiple tickets with dependencies.

## Modes

### Mode 1: single ticket

User says: "create a ticket for X" or "add a ticket for X"

1. Clarify scope if ambiguous
2. Explore the codebase to find relevant files
3. Create the ticket
4. Show the created ticket to the user

If the request is vague ("add a ticket for that auth thing I mentioned"), create a backlog ticket: brief title, minimal description, **no tag**. The user or a later refine session will fill in the details.

If the request is specific enough to write proper acceptance criteria and file hints, create a fully-formed ticket **with** `--tags ready-for-development`.

### Mode 2: decompose

User says: "break this goal into tickets" or "create tickets for refactoring X"

1. Understand the full goal
2. Explore the codebase to understand scope and relevant files. If `lat.md/` exists at project root, run `lat search "<goal description>"` to discover relevant context from the knowledge graph
3. Seed context file if it doesn't exist (see "Context seeding" below)
4. Break into small, independently completable tickets
5. Create tickets in dependency order (create the prerequisite tickets first so you have their IDs)
6. Set dependencies: `tk dep <downstream-id> <upstream-id>` (downstream depends on upstream)
7. Validate the dep graph: `tk dep cycle` and `tk ready` — if there are cycles or no ready tickets, fix before proceeding
8. Show all created tickets and their dependency chain

### Mode 3: seed from plan

User says: "seed tickets from this plan" or provides a plan file path

1. Read the plan file
2. Explore the codebase to understand scope and relevant files. If `lat.md/` exists at project root, run `lat search "<goal description>"` to discover relevant context from the knowledge graph
3. Seed context file if it doesn't exist (see "Context seeding" below)
4. Identify discrete work items
5. Create tickets for each, preserving the plan's ordering via dependencies
6. Show the created tickets

### Mode 4: refine

User says: "refine ticket X" or "refine backlog tickets"

Turn a vague backlog ticket into a workable one. If the ticket is too large, split it first (Mode 2).

1. Read the ticket: `tk show <id>`
2. If the ticket already has `ready-for-development` tag, tell the user it's already refined and stop
3. Explore the codebase to find relevant files, understand scope, and gather context
4. If the ticket is unclear, ask the user for clarification before proceeding
5. Rewrite the ticket file with:
   - Clear title (imperative, scoped)
   - Description with what to do, why, and file hints
   - Numbered acceptance criteria (each independently verifiable)
   - Correct type if the current one is wrong
6. Add the `ready-for-development` tag to the frontmatter
7. Show the refined ticket to the user

Batch refine: if the user says "refine backlog tickets" or "refine all", repeat for each untagged open ticket. Stop on the first one that needs user clarification — don't guess.

To rewrite a ticket file, use the `write` tool on the file path shown by `tk show`. Preserve the existing YAML frontmatter fields (id, created, deps, links, parent) and only update: title, description, acceptance criteria, type, tags.

## Context seeding

Modes 2 and 3 create a context file to avoid redundant discovery in each ticket-worker session.

**Prerequisite**: if a `lat.md/` directory exists at the project root, skip context seeding entirely. The `lat search` command (run in step 2) provides living, queryable context that makes a static context file redundant.

After exploring the codebase (step 2 in both modes), check if `plans/.ticket-context.md` exists. If it does, skip — the context is already seeded. If not, create it:

```bash
mkdir -p plans
```

Write `plans/.ticket-context.md` with three sections:

```markdown
## Verification commands

- Build: <command>
- Test: <command>
- Lint: <command>

## Key directories

- path/ — description

## Conventions

- Description of relevant patterns
```

Fill in each section from what you discovered during exploration:

- **Verification commands**: look in `devenv.nix` (scripts, tasks, git-hooks), `package.json` (scripts.test, scripts.lint, scripts.build), `Makefile` (test, lint, check, build targets), `flake.nix` (checks)
- **Key directories**: list directories relevant to the batch of tickets being created
- **Conventions**: notable patterns found during exploration (error handling style, file structure, naming)

The context file is project-local and reusable across all tickets in the batch.

## Self-validation (always run after Mode 2/3)

After creating all tickets, run these checks:

1. `tk list` — confirm all tickets are open
2. For each ticket: `tk show <id>` — verify:
   - Description has file hints
   - Acceptance criteria are numbered and independently verifiable
   - If any are vague, refine immediately (Mode 4)
3. `tk dep cycle` — no cycles allowed. If found, fix.
4. `tk ready -T ready-for-development` — at least one ticket must be unblocked
5. If no tickets are ready, fix dependency ordering

Report: number of tickets created, any issues found and fixed, whether tickets are ready for work.

## Workflow

1. Read the user's request
2. Explore the codebase to understand relevant files and context
3. Draft ticket(s) mentally — title, description with file hints, acceptance criteria
4. Create tickets via `tk create` with all fields populated. Use real newlines in `-d` and `--acceptance` arguments — never pass literal `\n` characters
5. If multiple tickets: set dependencies via `tk dep <id> <dep-id>`
6. Run self-validation (see above)
7. Present created tickets for review
