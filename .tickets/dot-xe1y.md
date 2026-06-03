---
id: dot-xe1y
status: open
deps: []
links: []
created: 2026-06-03T20:11:43Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Retire Nvim semantics from bridge.ts compatibility

Plan Step 15. Verify if any Nvim semantics still remain in bridge.ts after new ingress paths land. If none remain, remove the stale compatibility code; otherwise keep bridge as non-Nvim ingress only and defer this step. Files: home/common/programs/pi-coding-agent/extensions/bridge.ts.

## Acceptance Criteria

1. pinvim smoke passes
2. Telegram/tell ingress checks still pass
3. No remaining Nvim/pinvim frame handling in bridge
4. just home passes
