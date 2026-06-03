---
id: dot-m3c1
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

# Deprecate pinvim review UI; switch to simpler native diff/preview path

Plan Step 14. Deprecate config/nvim/lua/pinvim/review.lua, its commands, and keymaps. Do not carry forward the half-built review UI as a rewrite dependency. Replace later with a simpler native diff/preview flow first. Files: config/nvim/lua/pinvim/review.lua, config/nvim/lua/pinvim.lua, related keymap glue.

## Acceptance Criteria

1. Review UI no longer part of the rewrite path
2. Any review flow left in-tree is minimal and based on native diff/preview
3. nvim --headless '+lua require("pinvim").setup(); print("review deprecated")' +qa succeeds
