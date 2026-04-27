---
id: dot-vta8
status: closed
deps: [dot-6jlp]
links: []
created: 2026-04-22T16:17:56Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Sync extensions/task-pipeline.ts + skills/task-pipeline/SKILL.md with otahontas (leaner subagent model)

Replace our verbose task-pipeline with otahontas's leaner version where subagents write their own output via write-task/write-plan tools (blocked by ticket-port-restricted-write dot-aqin).

## Files to sync

- Source extension: /tmp/otahontas-nix/home/configs/pi-coding-agent/extensions/task-pipeline.ts
- Source skill: /tmp/otahontas-nix/home/configs/pi-coding-agent/skills/task-pipeline/SKILL.md
- Our extension: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/task-pipeline.ts
- Our skill: ~/.pi/agent/skills/task-pipeline/SKILL.md (symlinked from home/common/.../skills/task-pipeline/SKILL.md — verify nix source path before editing)

## Key behavioral changes

- /task: main agent no longer saves output. Researcher subagent calls write-task itself. Main agent reads plans/task.md AFTER subagent finishes.
- /plan: same pattern with write-plan
- Shorter prompts = less main-agent context

## Coordination

This ticket should be worked together with dot-<ID of port-agents> which updates researcher.md and planner.md to reference write-task/write-plan. Neither makes sense without the other.

## Preserve

- Ticket-related message in skill: 'at least one ticket must be unblocked; all tickets must become unblocked through the dependency chain' — our phrasing is clearer than upstream, keep it

## Acceptance Criteria

1. extensions/task-pipeline.ts matches upstream structure (leaner prompts, subagent writes own output)
2. skills/task-pipeline/SKILL.md updated to document the new flow
3. 'just validate home' + 'just home' pass
4. '/task foo' command invokes researcher subagent; after return, plans/task.md exists and contains researcher output
5. '/plan' with existing plans/task.md invokes planner; plans/plan.md written
6. Ticket-related phrasing preserved in skill (see Preserve section)
7. Diff against our previous version committed in single jj change with conventional message



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
