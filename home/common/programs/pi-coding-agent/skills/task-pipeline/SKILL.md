---
name: task-pipeline
description: Structured workflow for research → plan → tickets → work. Use when starting or continuing a task with /task, /plan, /tickets, /retrieve, or /continue commands.
---

# Task pipeline

A phased workflow for complex tasks. State lives in files, not session memory. Any session can pick up where the last one left off by reading the docs.

## File structure

Docs live outside the repo, keyed by repo basename + slug:

```
~/.local/share/pi/plans/$(basename $PWD)/
  {slug}_TASK.md            # research findings
  {slug}_PLAN.md            # implementation plan
  {slug}.ticket-context.md  # ticket-context (created by /tickets)
```

### Slug

`{slug}` = `${TICKET_ID}-<kebab>` if a tk ticket is in progress, else `<kebab>` derived from the user's prompt (3–5 words).

Resolution order when a slug isn't passed explicitly:

1. **Explicit arg** — if the user passes a slug arg (`/plan my-slug`), use it directly; skip all other steps
2. **$TICKET_ID or in-progress tk ticket** — if `$TICKET_ID` is set, or exactly one tk ticket is `in_progress` in the repo, derive slug from it
3. **Orphan-scan** — scan the plans dir for `*_TASK.md` with no matching `*_PLAN.md`:
   - 1 match → use silently
   - 2+ matches → list numbered with mtime, ask user to pick
   - 0 matches → fall through to recent-items scan
4. **Recent-items scan** — scan the plans dir for all `*_TASK.md` and `*_PLAN.md`, group by slug, sort by most recent mtime across each slug's files. Determine phase per slug:
   - TASK only → `research`
   - TASK + PLAN → `planning-complete`
   - TASK + PLAN + ticket-context.md → `tickets-seeded`
   - 0 results → tell user to run `/task <description>` first
   - 1 result → use silently
   - 2–3 results → list as `<slug>  [<phase>]  <mtime>` and ask user to pick
   - >3 results → list top 3 + "and N more, use /retrieve <slug> for a specific one"

Announce the resolved slug in output so the user sees which file is being read/written.

> **Note on worktrees:** upstream examples this pipeline borrowed from assume a git-worktree-per-feature layout. We are NOT currently using worktrees. Repo-basename + slug scoping gives the same isolation without the worktree overhead. A later migration to jj workspaces is tracked separately — until then, treat worktree mentions in this repo as documentation of supported-but-unused mode.

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `/task` | `<description>` or none | Start or resume research. With description: invoke researcher subagent. Without: resume existing task (slug resolution applies). |
| `/plan` | `<slug>` or none | Create implementation plan from research. With slug: skip scans. Without: resolve slug (orphan → recent-items fallback). |
| `/tickets` | `<slug>` or none | Create tickets from plan. With slug: skip scans. Without: resolve slug (orphan → recent-items fallback). |
| `/retrieve` | `<slug>` or none | List or look up past TASK/PLAN combos. With slug: show phase summary + next-command suggestion. Without: scan and list all slugs in the plans dir (0/1/2-3/>3 cases). |
| `/continue` (`/cont`) | `<slug>` or none | Resume the pipeline from wherever you left off. Detects next phase from file existence and emits the equivalent command — does NOT auto-invoke subagents. |
| `work-tickets` | — | Work open tickets in the current checkout (external script, not a slash command). |

All commands are scoped to the current repo: `~/.local/share/pi/plans/$(basename $PWD)/`.

## Phase 1: Research

**Entry:** `/task <description>` or `/task` (to continue existing research)

Any text after `/task` is the research context — the problem to investigate, requirements, constraints, etc. The agent passes this directly to the researcher subagent.

This phase runs in an **isolated subagent** (`researcher`) that physically cannot modify files. The main agent's only jobs are: invoking the subagent and saving output.

1. Main agent resolves the slug (see **Slug** above) and ensures the plans dir exists (`mkdir -p ~/.local/share/pi/plans/$(basename $PWD)`)
2. If `{slug}_TASK.md` exists: read it and pass contents as context to the researcher subagent
3. Main agent invokes the subagent tool: `{ agent: "researcher", task: "<research task + context; include the resolved slug and task file path>" }`
4. The researcher subagent runs in isolation — it can read, search, and run read-only commands, but **cannot edit, write, or modify anything**
5. Main agent saves the subagent output to `~/.local/share/pi/plans/$(basename $PWD)/{slug}_TASK.md`

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

**Entry:** `/plan` or `/plan <slug>`

This phase runs in an **isolated subagent** (`planner`) that physically cannot modify files.

1. Main agent resolves the slug (same rules as **Phase 1**) and reads `{slug}_TASK.md` — the research findings
2. If `{slug}_TASK.md` doesn't exist: tell the user to run `/task` first
3. Main agent invokes the subagent tool: `{ agent: "planner", task: "<research findings; include slug + task file path>" }`
4. The planner subagent runs in isolation — it can read files but **cannot edit or write anything**
5. Main agent saves the subagent output to `~/.local/share/pi/plans/$(basename $PWD)/{slug}_PLAN.md`

### Plan doc format

```markdown
# Plan: <task description>

Research: `~/.local/share/pi/plans/$(basename $PWD)/{slug}_TASK.md`

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

**Entry:** `/tickets` or `/tickets <slug>`

1. Read `~/.local/share/pi/plans/$(basename $PWD)/{slug}_PLAN.md`
2. Explore the codebase for file hints and verification commands
3. Seed `~/.local/share/pi/plans/$(basename $PWD)/{slug}.ticket-context.md` if it doesn't exist (see context seeding in ticket-creator skill)
4. Create one ticket per plan step using ticket-creator skill Mode 3
5. **Self-validate** (mandatory, every time):
   - `tk list` — check all tickets are open
   - For each ticket: `tk show <id>` — verify description has file hints, acceptance criteria are numbered and independently verifiable
   - Refine any weak tickets immediately
   - `tk dep cycle` — no cycles allowed
   - `tk ready -T ready-for-development` — at least one ticket must be unblocked
6. Report what was created

## Retrieval and resumption

### `/retrieve`

Look up past work in the current repo's plans dir. Two modes:

- **`/retrieve <slug>`** — show phase summary for that slug + suggest the next command (e.g., `/plan my-slug`, `/tickets my-slug`, or `work-tickets`)
- **`/retrieve`** (no args) — list all slugs in the plans dir with phase + mtime. 0/1/2-3/>3 listing cases apply (same as recent-items fallback in slug resolution)

Use `/retrieve` when you want to see what's been done without starting any work.

### `/continue` (alias: `/cont`)

Smart "pick up where I left off." Detects the next phase from file existence and emits the equivalent command — it does **not** auto-invoke subagents or run any slash command itself.

Phase detection:

| Files present | Next step |
|---|---|
| No TASK | "No research found. Start with: /task \<description\>" |
| TASK only | "Continue to planning. Equivalent: /plan {slug}" |
| TASK + PLAN (no context) | "Continue to ticket creation. Equivalent: /tickets {slug}" |
| TASK + PLAN + context | "All phases complete. Work tickets with: work-tickets" |

## Phase transitions

| From | To | Trigger |
|------|----|---------|
| — | Research | `/task <description>` |
| Research | Research | `/task` (continue) |
| Research | Plan | `/plan` or `/plan <slug>` |
| Plan | Plan | `/plan <slug>` (iterate) |
| Plan | Tickets | `/tickets` or `/tickets <slug>` |
| Tickets | Work | `work-tickets` in the current checkout |
| Any | Any | `/continue` or `/cont` — emits next-step hint |
| Any | Lookup | `/retrieve` or `/retrieve <slug>` — shows phase + suggests next command |

You can go back: run `/plan` after tickets exist to revise, then `/tickets` to recreate. Clean up old tickets first (`tk close` or recreate with new deps).

## Example scenarios

### Forgot which slug you were using

```
/retrieve                  # lists all slugs with phase + mtime
/continue                  # detects next phase and emits the command to run
```

### Mid-pipeline, fresh session

```
/continue my-feature      # "Continue to ticket creation. Slug: my-feature. Equivalent: /tickets my-feature"
/tickets my-feature        # picks up from the plan
```

### Fresh repo, no prior work

```
/task investigate auth token refresh   # start research
/plan                                   # after research done, orphan-scan picks up the slug
/continue                               # after plan done, "Continue to ticket creation..."
```

## Rules

- Work in the current checkout. Worktree support exists upstream but is not currently in use — isolation comes from repo-basename + slug scoping instead
- Always read existing files before writing — pick up where you left off
- Research and plan docs are living documents — update, don't replace with alternatives
- Plan steps must be small enough for one agent session (~30 min of work)
- Never skip self-validation when creating tickets
- Announce the resolved slug at the start of each phase so the user knows which files are in play
- Source-of-truth for the extension code: `home/common/programs/pi-coding-agent/extensions/task-pipeline.ts` (nix-managed; do NOT edit the `~/.pi/agent/extensions/` symlink)
