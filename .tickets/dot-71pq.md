---
id: dot-71pq
status: open
deps: [dot-pabp]
links: []
created: 2026-05-06T12:43:23Z
type: feature
priority: 1
assignee: Seth Messer
tags: [ready-for-development]
---
# Add recent-items fallback to slug resolution

Upgrade the orphan-scan fallback in /task (no-args), /plan, /tickets handlers. Currently when no orphan TASK.md exists, the message says 'run /task first' — but valid completed TASK+PLAN pairs are invisible.

New behavior when orphan-scan finds 0:
- Find all *_TASK.md / *_PLAN.md in the plans dir (~/.local/share/pi/plans/$(basename $PWD)/)
- Sort by mtime (most recent first)
- Extract unique slugs, determine phase per slug (has TASK? has PLAN? has ticket-context.md?)
- 0 results → still show 'run /task first'
- 1 result → use silently
- 2-3 results → list with slug + phase + mtime, ask user to pick
- >3 → list top 3 + 'and N more, use /retrieve <slug>'

Update sendUserMessage content in all three commands to instruct the agent on this scan/listing behavior.

Source-of-truth: home/common/programs/pi-coding-agent/extensions/task-pipeline.ts
Depends on dot-pabp (the /plan and /tickets handlers must accept args first, otherwise this enhancement can't be triggered explicitly).

Plan ref: ~/.local/share/pi/plans/.dotfiles/pipeline-smart-retrieval_PLAN.md (Step 2)

## Acceptance Criteria

1. /task with no args, /plan with no args, /tickets with no args — when orphan-scan returns 0 — emit a message instructing the agent to scan the plans dir for all *_TASK.md / *_PLAN.md, sort by mtime, present top 3 with phase summary
2. Single-result case auto-selects silently (no listing)
3. >3 results case shows top 3 + summary count of remaining
4. just validate home passes
5. In a repo with completed TASK+PLAN: /plan with no args lists candidates instead of 'run /task first'

