---
id: dot-umte
status: open
deps: 4:1:deps: 4:1:deps: [, dot-0wfk, dot-slwf]
links: []
created: 2026-06-03T20:11:26Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Make registry the fast path; gate background scans

Plan Step 8. Exact parent registry wins. Explicit buffer/env target still works. Ranked manifest/tmux discovery only runs when no parent registry exists or user explicitly asks via :PiSessions / :PiTarget / doctor commands. Disable or heavily gate recurring Pi-side Nvim peer scan and Nvim-side manifest scan when exact registry entry exists. Files: config/nvim/lua/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Automatic reconnect never picks unrelated ephemeral/child sockets for current parent
2. Manual :PiSessions / :PiTarget selection still works
3. bin/pinvim-protocol-smoke passes
4. nvim --headless '+lua require("pinvim").setup(); print("resolve ok")' +qa succeeds
5. Startup remains cheap (no recurring scan when registry hit)
