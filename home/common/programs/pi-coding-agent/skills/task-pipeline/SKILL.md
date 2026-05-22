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

Launches the **researcher** subagent. The researcher reads existing `plans/task.md` if present (continuing research), investigates the codebase, and writes findings to `plans/task.md`.

The user reviews and iterates. Run `/task` again to continue research.

## Phase 2: Plan

**Entry:** `/plan` or `/plan <context>`

Launches the **planner** subagent. The planner reads `plans/task.md`, optionally receives inline context from the user, and writes the plan to `plans/plan.md`.

Prerequisite: `plans/task.md` must exist (run `/task` first).

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
