---
id: dot-6jlp
status: closed
deps: [dot-aqin]
links: []
created: 2026-04-22T16:18:25Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Port agents/planner.md + agents/researcher.md with write-task/write-plan tool refs

Replace our read-only planner/researcher agents with otahontas's versions that write their own output files via the write-task/write-plan tools. Depends on dot-aqin (restricted-write.ts port).

## Files

- Source planner: /tmp/otahontas-nix/home/configs/pi-coding-agent/agents/planner.md
- Source researcher: /tmp/otahontas-nix/home/configs/pi-coding-agent/agents/researcher.md
- Dest planner: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/agents/planner.md
- Dest researcher: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/agents/researcher.md

## Key changes vs current

- frontmatter tools: add write-plan / write-task respectively (e.g. 'tools: read, grep, find, ls, bash, write-plan')
- frontmatter description: change from 'Read-only — no mutations allowed' to 'Creates implementation plans in plans/plan.md from research findings' (researcher analog)
- Body: change 'You are READ-ONLY. Never modify any file' to 'Use the write-plan tool to write your plan to plans/plan.md. This is the only file you can modify.'
- Workflow: add steps '1. Read plans/task.md (continuing prior research)' for researcher; 'Write the plan to plans/plan.md using the format below' for planner

## Coordination

Worked in tandem with dot-vta8 (task-pipeline sync). Merge as one logical unit.

## Acceptance Criteria

1. Both agent files updated with write-task / write-plan tool refs in frontmatter
2. Bodies updated to instruct agent to write output themselves
3. 'just validate home' + 'just home' pass
4. After dot-aqin is closed: subagent tool invocation with agent: 'researcher' produces plans/task.md
5. After dot-aqin + dot-vta8 closed: /task foo end-to-end writes plans/task.md
6. jj diff shows ONLY agent file changes in this commit



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
