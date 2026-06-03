---
id: dot-ds0s
status: open
deps: 4:1:deps: [, dot-vbyh]
links: []
created: 2026-06-03T20:11:26Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add Pi-side editor-service discovery

Plan Step 10. Pi extension reads PINVIM_NVIM_LISTEN_ADDRESS or registry lockfile. Add health/status output for editor-service availability with clear fallback when absent. Discovery is lazy and non-fatal. Pre-prompt queries use editor service cleanly, not chat injection. Files: home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Pi shows Nvim service address when launched from Nvim
2. Missing service reports clear fallback in /pinvim-status and /pinvim-doctor
3. just home passes
