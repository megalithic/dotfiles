---
id: pca-2nge
status: in_progress
deps: []
links: []
created: 2026-04-23T21:33:14Z
type: chore
priority: 2
assignee: Seth Messer
tags: [pi, refactor, paths]
---
# Replace worktree-assumed plans/tasks paths with per-repo shared dirs

Our pi-coding-agent setup borrowed examples that assume git-worktree-per-feature workflows with ephemeral plans/ and tasks/ dirs. We don't use worktrees, so fixed filenames like plans/task.md and plans/plan.md collide across concurrent work. Replace references within subagent/ticket/worker/plan/researcher configs to use ~/.local/share/pi/plans/$(basename $PWD)/<ticket_id_or_short_title> and ~/.local/share/pi/tasks/$(basename $PWD)/<ticket_id_or_short_title>.

## Acceptance Criteria

All references to plans/PLAN.md, plans/task.md, plans/plan.md, tasks/TASK.md, and related hardcoded relative paths in agents/, prompts/, skills/, extensions/, and sources/ updated to use ~/.local/share/pi/<plans|tasks>/$(basename $PWD)/<id_or_slug>/. Worktree assumption removed from task-pipeline docs. No remaining references to plans/ or tasks/ as relative dirs (except intentional docs about the new scheme).

