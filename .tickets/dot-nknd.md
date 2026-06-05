---
id: dot-nknd
status: closed
deps: 4:1:deps: [, dot-umte]
links: []
created: 2026-06-03T20:11:43Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Retire old ephemeral auto-resume paths

Plan Step 13. Remove or gate resumable_ephemeral_target() and parked ephemeral auto-resume. pimux may park durable main panes but does not park child panes by default. Explicit :PiTarget <socket> escape hatch remains for manual overrides. Files: config/nvim/lua/pinvim.lua, bin/pimux.

## Acceptance Criteria

1. No automatic target source reports manifest-ephemeral for parent-owned sessions
2. Child panes die or remain child-only
3. bin/pinvim-protocol-smoke passes
4. :PiTarget <socket> still works as manual override
