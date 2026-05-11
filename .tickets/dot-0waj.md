---
id: dot-0waj
status: closed
deps: [dot-sbcv]
links: []
created: 2026-05-11T15:14:45Z
type: chore
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Migrate extension imports from @mariozechner to @earendil-works

All 23 custom extension .ts files import from @mariozechner/pi-coding-agent, @mariozechner/pi-ai, @mariozechner/pi-tui, and @mariozechner/pi-agent-core.
These must be updated to @earendil-works/* equivalents since pi v0.74.0 ships under the new scope.
This is a bulk find-and-replace — no functional changes.

Four mappings:
- @mariozechner/pi-coding-agent → @earendil-works/pi-coding-agent
- @mariozechner/pi-ai → @earendil-works/pi-ai
- @mariozechner/pi-tui → @earendil-works/pi-tui
- @mariozechner/pi-agent-core → @earendil-works/pi-agent-core

Files: all .ts files in home/common/programs/pi-coding-agent/extensions/
Also: statusline.ts.disabled (disabled but should be updated for consistency)

## Acceptance Criteria

1. No @mariozechner/ imports remain in extensions/ (rg '@mariozechner' extensions/ returns nothing)
2. All four package scopes correctly mapped to @earendil-works equivalents
3. just validate home builds without error
4. pi starts and loads all extensions without import errors
5. A working extension (e.g., sentinel, review, or loop) functions normally

