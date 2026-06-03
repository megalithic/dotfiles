---
id: dot-zo25
status: open
deps: 4:1:deps: 4:1:deps: [, dot-fiq5, dot-vnkm]
links: []
created: 2026-06-03T20:11:03Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Make :PiPanel launch or reuse one durable parent-owned main session

Plan Step 5. :PiPanel computes durable main socket from registry root; asks pimux to show pane. Default surface = tmux split. If no main session exists, Nvim claims main.intent.json under launch lock and launches exactly one main process. pimux is display/spawn helper that honors registry claim instead of tmux heuristics. Files: config/nvim/lua/pinvim.lua, bin/pimux.

## Acceptance Criteria

1. :PiPanel, :PiPanel!, :PiPanel reuses same pid/socket/session for same parent
2. No double-spawn race under the launch lock
3. bin/pinvim-protocol-smoke passes
4. Startup does not depend on tmux guessing when registry already exists
5. Manual: pid/socket unchanged across hide/show cycles per /pinvim-status
