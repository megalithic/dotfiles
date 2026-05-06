---
id: dot-idcr
status: open
deps: [dot-71pq]
links: []
created: 2026-05-06T12:43:44Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Add /continue slash command

New slash command for smart 'pick up where I left off' resumption. Accepts optional slug arg.

Behavior:
1. Same slug resolution as /plan / /tickets after dot-71pq lands (orphan-scan → recent-items fallback)
2. Once slug resolved, determine next phase from file existence:
   - TASK only (no PLAN) → emit 'Continue to planning. Slug: <slug>. Equivalent: /plan <slug>'
   - TASK + PLAN (no ticket-context.md) → emit 'Continue to ticket creation. Slug: <slug>. Equivalent: /tickets <slug>'
   - TASK + PLAN + ticket-context.md → emit 'All phases complete. Work tickets with: work-tickets. Slug: <slug>'
   - No TASK → 'No research found. Start with: /task <description>'
3. Multiple candidates → list top 3, ask user to pick

The handler does NOT auto-invoke subagents — it only tells the user/agent what the next step is.

Source-of-truth: home/common/programs/pi-coding-agent/extensions/task-pipeline.ts
Depends on dot-71pq (shares the scan/sort logic).

Plan ref: ~/.local/share/pi/plans/.dotfiles/pipeline-smart-retrieval_PLAN.md (Step 4)

## Acceptance Criteria

1. /continue registered as a slash command in task-pipeline.ts
2. /continue with TASK-only state emits the planning-phase suggestion with the slug
3. /continue with TASK+PLAN state emits the ticket-creation suggestion with the slug
4. /continue with all three files present says all phases done + suggests work-tickets
5. /continue with no TASK files says 'start with /task'
6. /continue does NOT auto-invoke any subagent
7. just validate home passes

