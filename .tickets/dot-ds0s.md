---
id: dot-ds0s
status: closed
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

## Notes

**2026-06-04T00:45:38Z**

Implemented Pi-side editor-service discovery from PINVIM_NVIM_LISTEN_ADDRESS, active peers, Nvim manifests, and registry intent files. Added source/fallback output for status/doctor and verified hard-timeout pi probes, just home, just validate home, and lat check.
