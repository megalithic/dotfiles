---
id: dot-a07u
status: open
deps: [dot-d6wm, dot-gew8, dot-f5le, dot-s3l8]
links: []
created: 2026-05-18T13:46:06Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Retire bridge.ts after focused ingress replacements land

Remove the legacy bridge.ts extension only after nvim, Hammerspoon/Telegram, tell/delegation, and session-discovery callers have focused owners. This ticket is final cleanup, not first migration step.

## Acceptance Criteria

rg finds no active bridge.ts consumers or docs requiring it; pinvim.ts no longer carries telegram/tell/no-type legacy compatibility unless separately justified; bridge.ts removed from nix-managed extension set; pinvim-bridge audit updated with final decision; relevant smoke tests pass.

