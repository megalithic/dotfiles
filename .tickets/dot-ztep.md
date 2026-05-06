---
id: dot-ztep
status: closed
deps: [dot-pabp, dot-71pq, dot-h27d, dot-idcr]
links: []
created: 2026-05-06T12:43:56Z
type: chore
priority: 3
assignee: Seth Messer
tags: [ready-for-development]
---
# Update task-pipeline SKILL.md docs for new commands + resolution flow

Update the task-pipeline skill doc to reflect the changes from dot-pabp, dot-71pq, dot-h27d, dot-idcr:

- /plan and /tickets now accept slug args (was a P0 bug — see dot-pabp)
- New recent-items fallback when orphan-scan returns 0
- /retrieve command syntax + behavior
- /continue command syntax + behavior
- Updated 'Slug' section with the full resolution order: explicit arg → TICKET_ID → in-progress tk ticket → orphan-scan → recent-items
- Example usage for: forgot slug, mid-pipeline, fresh session

Source-of-truth: home/common/programs/pi-coding-agent/skills/task-pipeline/SKILL.md (NOT the ~/.pi/agent/skills symlink)

Depends on the four implementation tickets above (dot-pabp, dot-71pq, dot-h27d, dot-idcr) — docs should reflect what shipped.

Plan ref: ~/.local/share/pi/plans/.dotfiles/pipeline-smart-retrieval_PLAN.md (Step 5)

## Acceptance Criteria

1. SKILL.md Slug section documents the 5-step resolution order (explicit → TICKET_ID → in-progress → orphan-scan → recent-items)
2. SKILL.md has a 'Commands' section listing /task, /plan, /tickets, /retrieve, /continue with brief descriptions and slug-arg semantics
3. SKILL.md includes example usage for the 'forgot slug', 'mid-pipeline', 'fresh session' scenarios
4. Doc references the source-of-truth path (home/common/programs/pi-coding-agent/extensions/task-pipeline.ts) so future agents know not to edit the symlink
5. Doc accurately reflects whatever shipped in dot-pabp, dot-71pq, dot-h27d, dot-idcr


## Notes

**2026-05-06T13:02:21Z**

Rewrote SKILL.md: 5-step slug resolution order, Commands table (/task /plan /tickets /retrieve /continue /cont work-tickets), Retrieval and resumption section with phase-detection table, 3 example scenarios (forgot slug, mid-pipeline, fresh repo), source-of-truth path warning in Rules. just validate home passes.
