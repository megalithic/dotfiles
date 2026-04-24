---
id: dot-7ezy
status: open
deps: []
links: []
created: 2026-04-25T01:42:06Z
type: task
priority: 2
assignee: Seth Messer
external-ref: fff-snacks.nvim#fff-9mmd
tags: [ready-for-development]
---
# Track upstream fix for fff-snacks.nvim breakage (fff.nvim PR #387)

Watcher ticket. Tracks work being done in ~/code/oss/fff-snacks.nvim on ticket fff-9mmd.

Context: fff.nvim PR #387 (commit cebacb3, 'feat!: Revamp & optimize the way strings are stored in RAM') dropped the 'path' field from Lua items. Our fork fff-snacks.nvim breaks on <leader>ff with 'Item has no `file`'.

Upstream ticket: fff-9mmd in ~/code/oss/fff-snacks.nvim/.tickets/fff-9mmd.md
View: cd ~/code/oss/fff-snacks.nvim && tk show fff-9mmd

Nothing to fix in this repo — fff.nvim and fff-snacks.nvim are both managed via lazy.nvim from home/common/programs/neovim/ (or wherever plugin spec lives). Close this ticket once fff-9mmd is closed and :Lazy sync picks up the fix.

If fff-snacks fix requires a bumped lazy spec commit pin, update the spec here and re-run just rebuild.

## Acceptance Criteria

1. fff-9mmd in ~/code/oss/fff-snacks.nvim is closed
2. :Lazy sync (or equivalent) pulls fix into local lazy cache
3. <leader>ff renders files in nvim without error
4. If a plugin spec pin needed updating, change is committed here and 'just rebuild' succeeds

