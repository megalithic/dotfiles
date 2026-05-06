---
id: dot-pabp
status: in_progress
deps: []
links: []
created: 2026-05-06T12:43:11Z
type: bug
priority: 0
assignee: Seth Messer
tags: [ready-for-development]
---
# Fix /plan and /tickets to accept slug arg (P0 bug)

P0 bug. The /plan and /tickets command handlers in task-pipeline.ts use 'async (_args, _ctx)' — the underscore prefix silently drops the slug argument. The user-message text already references slug-passing semantics, but the handler never reads args. Only /task uses 'args' correctly.

Consequence: once a TASK+PLAN pair is complete, slash commands cannot retrieve them — orphan-scan finds 0, and the user has no way to pass the slug explicitly.

Fix: change '_args' to 'args' in both /plan and /tickets handlers, and inject the explicit slug into the emitted sendUserMessage when args.trim() is non-empty.

Source-of-truth file (edit this, NOT the symlink):
  home/common/programs/pi-coding-agent/extensions/task-pipeline.ts (lines ~76, ~104 — /plan and /tickets registerCommand blocks)

Plan ref: ~/.local/share/pi/plans/.dotfiles/pipeline-smart-retrieval_PLAN.md (Step 1 — P0 standalone)
Context: ~/.local/share/pi/plans/.dotfiles/pipeline-smart-retrieval.ticket-context.md

## Acceptance Criteria

1. /plan and /tickets handlers in task-pipeline.ts use 'args' (no underscore prefix) instead of '_args'
2. When args.trim() is non-empty, the handler injects the explicit slug into the sendUserMessage with text like 'Slug = <args> (passed explicitly, skip orphan scan)'
3. /task handler unchanged (already uses 'args' correctly)
4. just validate home passes
5. After just home, in a fresh session: /plan pi-wrapper-fetchfromgithub-extensions causes the agent to read pi-wrapper-fetchfromgithub-extensions_PLAN.md (no orphan scan, no 'run /task first' error)
6. /tickets pi-wrapper-fetchfromgithub-extensions same behavior

