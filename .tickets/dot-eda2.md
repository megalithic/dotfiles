---
id: dot-eda2
status: open
deps: 4:1:deps: [, dot-fiq5]
links: []
created: 2026-06-03T20:11:03Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add read-only :PiDoctor and /pinvim-doctor diagnostics

Plan Step 3. Diagnostics-only command before behavior changes. Report parent/workspace/instance ids, registry files, current socket/source, manifest candidates, tmux pane/options, heartbeat age, stale warnings, editor-service state, cleanup hints. No mutation; headless path must not trigger connect/discovery. Pi-side adds /pinvim-doctor with same data. Files: config/nvim/lua/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. :PiDoctor works with no Pi, live Pi, and stale socket path
2. Headless diagnostic path does not trigger connect/discovery side effects
3. nvim --headless '+lua require("pinvim").setup(); vim.cmd("PiDoctor"); print("doctor ok")' +qa succeeds
4. /pinvim-doctor prints registry/identity/health info on Pi side
