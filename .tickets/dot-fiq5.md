---
id: dot-fiq5
status: closed
deps: 4:1:deps: [, dot-msws]
links: []
created: 2026-06-03T20:11:03Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Propagate pinvim parent identity through manifests and peer frames

Plan Step 2. Extend Nvim peer identity + manifests with parentId, workspaceId, instanceId, registryRoot, role (main|child|nested). Mirror on Pi extension identity/env/status. Keep old fields. When explicit parent identity exists, reject mismatched peers before score-based fallback. Files: config/nvim/lua/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts, bin/pinvim-protocol-smoke.

## Acceptance Criteria

1. bin/pinvim-protocol-smoke passes
2. nvim --headless '+lua require("pinvim").setup()' +qa succeeds
3. just home passes
4. Manifests on both sides include new identity fields
5. Child/nested sessions rejected unless they match current parent/workspace/session

## Notes

**2026-06-03T20:50:13Z**

Implemented pinvim registry identity in Nvim/Pi peer identities and manifests; smoke/headless/home/lat checks pass.
