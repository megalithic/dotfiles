---
name: task-pipeline
description: Structured workflow for grill notes → research → plan → tickets → work. Use when starting or continuing a task with /task, /plan, /tickets, /continue, or /retrieve commands.
---

# Task pipeline

A phased workflow for complex tasks. State lives in files, not session memory. Any session can pick up work by reading the files under the repo's plans directory.

## File structure

Docs live outside the repo:

```text
~/.local/share/pi/plans/$(basename $PWD)/
  {slug}_grill.md          # optional grill-me output; uppercase _GRILL.md is also valid
  {slug}_TASK.md           # research findings
  {slug}_PLAN.md           # implementation plan
  {slug}.ticket-context.md # ticket creation context
```

Slug is a kebab-case task name. Commands may receive an explicit slug, such as `/plan shade-next`.

## Phase 0: Grill

**Entry:** `/grill-me <topic>`

The grill-me skill writes a distilled decision log to `{slug}_grill.md` or `{slug}_GRILL.md`.

A GRILL file is pre-research context. It does not replace research.

Next step:

```text
/task {slug}
```

When `/task {slug}` finds no TASK file but finds a GRILL file, read the GRILL file and start research from it.

## Phase 1: Research

**Entry:** `/task <description>`, `/task <slug>`, or `/task` to continue existing research.

1. Resolve slug.
2. Read `{slug}_TASK.md` if it exists.
3. If TASK is missing, read `{slug}_grill.md` or `{slug}_GRILL.md` if present.
4. Launch the researcher subagent.
5. Save output to `{slug}_TASK.md`.

The user reviews and iterates. Run `/task {slug}` again to continue research.

## Phase 2: Plan

**Entry:** `/plan`, `/plan <slug>`, or `/plan <context>`.

Prerequisite: `{slug}_TASK.md` must exist. If only GRILL exists, tell the user to run `/task {slug}` first.

1. Resolve slug.
2. Read `{slug}_TASK.md`.
3. Launch the planner subagent.
4. Save output to `{slug}_PLAN.md`.
5. Present the plan for review. Do not create tickets until the user explicitly approves.

## Phase 3: Tickets

**Entry:** `/tickets` or `/tickets <slug>`.

1. Resolve slug.
2. Read `{slug}_PLAN.md`.
3. Explore the codebase for file hints and verification commands.
4. Seed `{slug}.ticket-context.md` if missing (see ticket-creator skill).
5. Create one ticket per plan step using ticket-creator skill Mode 3.
6. Self-validate every time:
   - `tk list` — check all tickets are open.
   - For each ticket: `tk show <id>` — verify file hints exist and acceptance criteria are numbered and independently verifiable.
   - Refine weak tickets immediately.
   - `tk dep cycle` — no cycles allowed.
   - `tk ready -T ready-for-development` — at least one ticket must be unblocked.
7. Report what was created.

## Phase 4: Work

**Entry:** `work-tickets` in the worktree.

Work tickets one at a time. Verify each step before moving on.

## Slug resolution

For commands with an explicit argument that is a slug, use it directly.

For commands without a slug:

1. Scan `~/.local/share/pi/plans/$(basename $PWD)/` for `*_grill.md`, `*_GRILL.md`, `*_TASK.md`, `*_PLAN.md`, and `*.ticket-context.md`.
2. Group files by slug.
3. Sort groups by newest file mtime.
4. If zero groups exist, report the relevant start command.
5. If one group exists, use it silently.
6. If two or three groups exist, list slug, phase, and mtime; ask the user to pick.
7. If more than three groups exist, list the top three and say how many remain; suggest `/retrieve <slug>`.

Phase detection per slug:

| Files present                | Phase        | Next command      |
| ---------------------------- | ------------ | ----------------- |
| GRILL only                   | Grilled      | `/task {slug}`    |
| TASK only                    | Researched   | `/plan {slug}`    |
| TASK + PLAN                  | Planned      | `/tickets {slug}` |
| TASK + PLAN + ticket-context | Ticketed     | `work-tickets`    |
| PLAN without TASK            | Inconsistent | inspect files     |

## `/continue`

`/continue` and `/cont` resume the pipeline. They do not auto-invoke the next command.

Resolve slug, detect phase, and tell the user the next equivalent command:

- GRILL only → `Continue to research: /task {slug}`
- TASK only → `Continue to planning: /plan {slug}`
- TASK + PLAN → `Continue to ticket creation: /tickets {slug}`
- TASK + PLAN + ticket context → `All planning phases complete. Work tickets with work-tickets.`
- No files → `No research found. Start with /task <description>`

## `/retrieve`

`/retrieve` lists known GRILL/TASK/PLAN groups in the current repo's plans dir.

`/retrieve <slug>` reports which files exist for that slug, current phase, and next command. It does not run subagents or slash commands.

## Phase transitions

| From     | To       | Trigger                   |
| -------- | -------- | ------------------------- |
| —        | Grill    | `/grill-me <topic>`       |
| —        | Research | `/task <description>`     |
| Grill    | Research | `/task {slug}`            |
| Research | Research | `/task {slug}`            |
| Research | Plan     | `/plan {slug}`            |
| Plan     | Plan     | `/plan {slug}` or context |
| Plan     | Tickets  | `/tickets {slug}`         |
| Tickets  | Work     | `work-tickets`            |

You can go back: run `/plan {slug}` after tickets exist to revise, then `/tickets {slug}` to recreate. Clean up old tickets first (`tk close` or recreate with new deps).

## Rules

- Always read existing files before writing.
- Treat GRILL files as context, not final research.
- Research and plan docs are living documents. Update them instead of creating alternatives.
- Plan steps must be small enough for one agent session.
- Never skip ticket self-validation.
