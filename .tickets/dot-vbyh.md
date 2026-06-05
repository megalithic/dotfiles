---
id: dot-vbyh
status: closed
deps: 4:1:deps: [, dot-msws]
links: []
created: 2026-06-03T20:11:26Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add separate Nvim editor-service transport (msgpack-RPC)

Plan Step 9. Expose separate editor-service transport from Nvim using v:servername (or serverstart()). Persistent msgpack-RPC client in pinvim.ts. Distinct from Pi peer socket. Define timeout, reconnect, and stale-service behavior; editor-service failures must not break peer. Files: config/nvim/lua/pinvim.lua, optional config/nvim/lua/pinvim/editor_service.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Editor service appears and can be diagnosed independently of Pi peer socket
2. Stale service visible in doctor/status output
3. Peer startup does not block on editor-service availability
4. nvim --headless '+lua require("pinvim").setup(); vim.cmd("PiDoctor")' +qa succeeds

## Notes

**2026-06-03T21:55:18Z**

Implemented editor-service transport, added unref guards so pinvim doctor/no-session probes cannot leave orphaned pi processes, cleaned orphan panes, and verified formatting/home/lat checks.
