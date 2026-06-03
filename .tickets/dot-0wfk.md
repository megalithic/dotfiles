---
id: dot-0wfk
status: open
deps: 4:1:deps: [, dot-zo25]
links: []
created: 2026-06-03T20:11:03Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Model :PiSplit as explicit child session under registry

Plan Step 6. Replace ephemeral socket generation with child session id and child socket path under children/<child-id>/. PINVIM_SESSION_ROLE=child. Child sessions never replace main registry entry, never auto-selected by normal socket resolution, stay out of default reconnect/repair. Identity is explicit; do not rely on socket basename parsing. Files: config/nvim/lua/pinvim.lua, bin/pimux, home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Closing child split does not affect main session
2. :PiSplit never becomes :PiPanel target unless explicitly selected
3. bin/pinvim-protocol-smoke passes
4. Manual: :PiPanel still talks to main after :PiSplit child pane closes
