---
id: dot-mg2c
status: closed
deps: 4:1:deps: [, dot-t4an]
links: []
created: 2026-06-09T15:10:54Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Add SQLite schema and migration runner for shade-next

In ~/code/shade-next, add initial persistence layer for drafts, history, route decisions, previews/results, and migration metadata. Define schema and migration runner in app/core code, with tests next to implementation. File hints: ~/code/shade-next/Sources/, ~/code/shade-next/Tests/, and persistence/migration modules created by ticket 1. Keep design aligned with ~/.local/share/pi/plans/.dotfiles/shade-next_TASK.md.

## Acceptance Criteria

1. Initial SQLite schema includes tables for drafts, history, route decisions, previews/results, and migration metadata.
2. Migration runner can bootstrap an empty database.
3. Test coverage proves empty-db bootstrap and at least one forward migration path.
4. timeout 600 bash -lc "cd ~/code/shade-next && devenv shell -- swift test" passes, or equivalent repo-local test command is added and passes.
5. Ticket notes list exact files added or changed.
