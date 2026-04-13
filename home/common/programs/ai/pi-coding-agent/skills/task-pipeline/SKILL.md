---
name: task-pipeline
description: Structured workflow for research → plan → tickets → work. Use when starting or continuing a task with /task, /plan, or /tickets commands.
---

# Task pipeline

A phased workflow for complex tasks. State lives in files, not session memory. Any session can pick up where the last one left off by reading the docs.

## File structure

All work happens in a worktree at `<repo>/.worktrees/<branch>/`. Docs go in `plans/`:

```
plans/
  task.md     # research findings (fixed filename)
  plan.md     # implementation plan (fixed filename)
```

Fixed filenames because worktrees already isolate tasks — no need for unique slugs. Overwrite if exists.

## Phase 1: Research

**Entry:** `/task <description>` or `/task` (to continue existing research)

Any text after `/task` is the research context — the problem to investigate, requirements, constraints, etc. The agent passes this directly to the researcher subagent.

This phase runs in an **isolated subagent** (`researcher`) that physically cannot modify files. The main agent's only jobs are: invoking the subagent and saving output.

1. If `plans/task.md` exists: main agent reads it and passes contents as context to the researcher subagent
2. Main agent invokes the subagent tool: `{ agent: "researcher", task: "<research task with context>" }`
3. The researcher subagent runs in isolation — it can read, search, and run read-only commands, but **cannot edit, write, or modify anything**
4. Main agent saves the subagent output to `plans/task.md`

### Research doc format

```markdown
# <task description>

## Findings

- Finding 1 with evidence
- Finding 2 with source references
- ...

## Open questions

- Question that couldn't be answered
- ...

## Sources

- file paths, URLs, session references
```

Keep writing until you can't find more. The user will tell you when to move on.

## Phase 2: Plan

**Entry:** `/plan` or `/plan <context>`

This phase runs in an **isolated subagent** (`planner`) that physically cannot modify files.

1. Main agent reads `plans/task.md` — the research findings
2. If `plans/task.md` doesn't exist: tell the user to run `/task` first
3. If the user passed inline context (`/plan <context>`), prepend it to the research findings before passing to the planner
4. Main agent invokes the subagent tool: `{ agent: "planner", task: "<user context + research findings>" }`
5. The planner subagent runs in isolation — it can read files but **cannot edit or write anything**
6. Main agent saves the subagent output to `plans/plan.md`

### Plan doc format

```markdown
# Plan: <task description>

Research: `plans/task.md`

## Steps

### Step 1: <title>

- **What:** description
- **Files:** paths to change
- **Verify:** how to confirm it works

### Step 2: <title>

- **What:** description
- **Files:** paths to change
- **Verify:** how to confirm it works

## Notes

- Design decisions, trade-offs, things to watch out for
```

Each step maps 1:1 to a ticket. Steps are ordered by dependency.

The user reviews and iterates. Do not proceed to tickets until the user explicitly says to.

## Phase 3: Tickets

**Entry:** `/tickets`

1. Read `plans/plan.md`
2. Explore the codebase for file hints and verification commands
3. Seed `plans/.ticket-context.md` if it doesn't exist (see context seeding in ticket-creator skill)
4. Create one ticket per plan step using ticket-creator skill Mode 3
5. **Self-validate** (mandatory, every time):
   - `tk list` — check all tickets are open
   - For each ticket: `tk show <id>` — verify description has file hints, acceptance criteria are numbered and independently verifiable
   - Refine any weak tickets immediately
   - `tk dep cycle` — no cycles allowed
   - `tk ready -T ready-for-development` — at least one ticket must be unblocked
6. Report what was created

## Phase transitions

| From     | To       | Trigger                        |
| -------- | -------- | ------------------------------ |
| —        | Research | `/task <description>`          |
| Research | Research | `/task` (continue)             |
| Research | Plan     | `/plan` or `/plan <context>`   |
| Plan     | Plan     | `/plan <context>` (iterate)    |
| Plan     | Tickets  | `/tickets`                     |
| Tickets  | Work     | `work-tickets` in the worktree |

You can go back: run `/plan` after tickets exist to revise, then `/tickets` to recreate. Clean up old tickets first (`tk close` or recreate with new deps).

## Rules

- Always work in the worktree, not main checkout
- Always read existing files before writing — pick up where you left off
- Research and plan docs are living documents — update, don't replace with alternatives
- Plan steps must be small enough for one agent session (~30 min of work)
- Never skip self-validation when creating tickets
