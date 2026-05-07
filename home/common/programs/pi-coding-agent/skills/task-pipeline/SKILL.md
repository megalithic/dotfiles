---
name: task-pipeline
description: Structured workflow for research → plan → tickets → work. Use when starting or continuing a task with /task, /plan, /tickets, /retrieve, or /continue commands.
---

# Task pipeline

Phased workflow for complex tasks. State lives in files, not session memory. Any session can pick up where the last one left off.

## File structure

```
~/.local/share/pi/plans/$(basename $PWD)/
  {slug}_TASK.md            # research findings
  {slug}_PLAN.md            # implementation plan
  {slug}.ticket-context.md  # ticket-context (created by /tickets)
```

## Slug resolution

`{slug}` = `${TICKET_ID}-<kebab>` if a tk ticket is in progress, else `<kebab>` derived from the user's prompt (3–5 words).

When a slug isn't passed explicitly:

1. **Explicit arg** — `/plan my-slug` → use directly, skip other steps
2. **$TICKET_ID or in-progress tk ticket** — if `$TICKET_ID` is set, or exactly one tk ticket is `in_progress`, derive slug from it
3. **Orphan-scan** — scan plans dir for `*_TASK.md` with no matching `*_PLAN.md`:
   - 1 match → use silently
   - 2+ → list numbered with mtime, ask user to pick
   - 0 → fall through to step 4
4. **Recent-items scan** — all `*_TASK.md` and `*_PLAN.md`, group by slug, sort by mtime. Phase per slug:
   - TASK only → `research`
   - TASK + PLAN → `planning-complete`
   - TASK + PLAN + ticket-context.md → `tickets-seeded`
   - 0 results → tell user to run `/task <description>`
   - 1 → use silently
   - 2–3 → list as `<slug>  [<phase>]  <mtime>`, ask user
   - \>3 → top 3 + "and N more, use /retrieve <slug>"

Announce resolved slug so user knows which files are in play.

## VCS conventions

**VCS-agnostic.** Use `jj` if available, fall back to `git`. All VCS references below apply to both.

Detection: `command -v jj >/dev/null && echo jj || echo git`

### One ticket = one commit

Each ticket from a plan maps to exactly one VCS commit. The commit boundary is the ticket boundary.

### Commit workflow

1. **Auto-title on completion** — when ticket work is done, agent generates a brief conventional commit title: `type(scope): description`
2. **Prompt for description** — before moving to next ticket or pushing, agent asks the developer: "Ready to commit. Want to add a detailed description?" If yes, developer provides it. If no, commit with title only.
3. **VCS commands:**
   - jj: `jj describe -m "title"` or `jj describe -m "title" -m "detailed description"`
   - git: `git commit -m "title" -m "detailed description"`

### Status checks

Before and after each ticket, check VCS status:
- jj: `jj status` + `jj log -n 3`
- git: `git status` + `git log --oneline -3`

## Phase 1: Research

**Entry:** `/task <description>` or `/task` (continue)

Runs in an **isolated subagent** (`researcher`) — read-only, cannot modify files.

1. Resolve slug, ensure plans dir exists
2. If `{slug}_TASK.md` exists, read and pass as context
3. Invoke subagent: `{ agent: "researcher", task: "<research task + context>" }`
4. Save subagent output to `{slug}_TASK.md`

### Research doc format

```markdown
# <task description>

## Findings

- Finding with evidence (file paths, line numbers)

## Current state

How things work now. Relevant code snippets.

## Open questions

- Unanswered questions needing user input

## Sources

- file paths, URLs, VCS commits
```

## Phase 2: Plan

**Entry:** `/plan` or `/plan <slug>`

Runs in an **isolated subagent** (`planner`) — read-only.

1. Resolve slug, read `{slug}_TASK.md` (required — run `/task` first if missing)
2. Invoke subagent: `{ agent: "planner", task: "<research findings + context>" }`
3. Save output to `{slug}_PLAN.md`
4. Present to user for review. Do NOT create tickets until explicitly approved.

### Plan doc format

```markdown
# Plan: <task description>

Research: `~/.local/share/pi/plans/$(basename $PWD)/{slug}_TASK.md`

## Steps

### Step 1: <title>

- **What:** description
- **Files:** paths to change
- **Verify:** how to confirm it works
- **Commit:** `type(scope): suggested title`

### Step 2: <title>
...

## Notes

- Design decisions, trade-offs
```

Each step maps 1:1 to a ticket and a commit. Steps ordered by dependency.

## Phase 3: Tickets

**Entry:** `/tickets` or `/tickets <slug>`

1. Read `{slug}_PLAN.md`
2. Explore codebase for file hints and verification commands
3. Seed `{slug}.ticket-context.md` if missing (see ticket-creator skill)
4. Create one ticket per plan step using ticket-creator skill Mode 3
5. **Self-validate** (mandatory):
   - `tk list` — all tickets open
   - `tk show <id>` each — file hints, numbered acceptance criteria
   - `tk dep cycle` — no cycles
   - `tk ready -T ready-for-development` — at least one unblocked
6. Report what was created

## Retrieval and resumption

### `/retrieve`

- **`/retrieve <slug>`** — show phase summary + next command
- **`/retrieve`** (no args) — list all slugs with phase + mtime (0/1/2-3/>3 cases)

### `/continue` (alias: `/cont`)

Detects next phase from file existence, emits equivalent command — does NOT auto-invoke.

| Files present | Next step |
|---|---|
| No TASK | "Start with: /task \<description\>" |
| TASK only | "/plan {slug}" |
| TASK + PLAN | "/tickets {slug}" |
| TASK + PLAN + context | "work-tickets" |

## Phase transitions

| From | To | Trigger |
|------|----|---------|
| — | Research | `/task <description>` |
| Research | Plan | `/plan` |
| Plan | Tickets | `/tickets` |
| Tickets | Work | `work-tickets` |
| Any | Any | `/continue` — next-step hint |
| Any | Lookup | `/retrieve` |

Can go back: `/plan` after tickets to revise, then `/tickets` to recreate.

## Rules

- Work in current checkout (worktree support planned but not active)
- Read existing files before writing — pick up where you left off
- Research and plan docs are living documents
- Plan steps small enough for one agent session (~30 min)
- Never skip self-validation when creating tickets
- One ticket = one commit (see VCS conventions above)
- Source-of-truth for extension: `home/common/programs/pi-coding-agent/extensions/task-pipeline.ts`
