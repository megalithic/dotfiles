---
id: dot-h27d
status: closed
deps: [dot-71pq]
links: []
created: 2026-05-06T12:43:34Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Add /retrieve slash command

New slash command for explicit retrieval/listing of past TASK/PLAN combos. Accepts optional slug arg.

Behavior:
1. If args.trim() non-empty → treat as slug, emit message with phase summary (TASK? PLAN? ticket-context?) + suggested next command
2. Else → scan ~/.local/share/pi/plans/$(basename $PWD)/ for all *_TASK.md / *_PLAN.md
3. Extract unique slugs, sort by most recent mtime
4. 0 → 'No plans found. Start with /task <description>'
5. 1 → emit message with slug + phase + next command suggestion
6. 2-3 → list with numbered choices, ask user to pick
7. >3 → list top 3 + 'and N more. Use /retrieve <slug> for a specific one.'

Use pi.registerCommand('retrieve', { ... }). Same sendUserMessage pattern as /task and /plan — the handler emits a message instructing the agent to do the listing/asking; there is no direct list-pick UI.

Source-of-truth: home/common/programs/pi-coding-agent/extensions/task-pipeline.ts
Depends on dot-71pq (recent-items fallback) — share the same scan/sort logic to keep the message text consistent.

Plan ref: ~/.local/share/pi/plans/.dotfiles/pipeline-smart-retrieval_PLAN.md (Step 3)

## Acceptance Criteria

1. /retrieve registered as a slash command in task-pipeline.ts with a description string
2. /retrieve (no args) in a repo with multiple plans shows top 3 most recent with slug + phase + mtime
3. /retrieve <slug> emits a phase summary + suggested next command for that slug
4. /retrieve in a repo with 0 plans says 'No plans found, start with /task'
5. /retrieve in a repo with exactly 1 plan auto-selects (no listing UI)
6. just validate home passes


## Notes

**2026-05-06T12:55:38Z**

Added /retrieve registerCommand block. With slug arg: emits phase-detection steps + next-command mapping (research→/plan, planning-complete→/tickets, tickets-seeded→work-tickets). No-args: instructs agent to scan Dir, group by slug, sort by mtime, apply 0/1/2-3/>3 cases. No auto-subagent invocation. just validate home + just home pass; symlink shows 4 registerCommand calls (was 3).
