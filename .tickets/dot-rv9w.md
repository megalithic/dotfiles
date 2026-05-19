---
id: dot-rv9w
status: closed
deps: [dot-slr0]
links: [dot-slr0]
created: 2026-05-19T18:25:44Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Normalize pinvim user commands to Pi prefix

Follow-up to dot-slr0. Ensure :PiReview is the primary user command for invoking review mode, and normalize pinvim-related Neovim user commands so user-facing commands use the Pi* prefix instead of Pinvim*.

Relevant files: config/nvim/lua/pinvim.lua, config/nvim/lua/pinvim/review.lua, config/nvim/AGENTS.md. Preserve internal Lua module names and transport naming; this ticket is about Neovim user-command surface and docs.

## Acceptance Criteria

1. :PiReview opens review mode and remains the documented command for invoking it.
2. All pinvim/pi-related Neovim user commands exposed by config/nvim/lua/pinvim.lua and config/nvim/lua/pinvim/review.lua use the Pi* prefix; no Pinvim* user-command aliases remain unless explicitly justified in code comments and docs.
3. config/nvim/AGENTS.md command table and conventions reflect Pi* as the command prefix and remove outdated Pinvim* dual-prefix guidance.
4. stylua --check config/nvim/lua/pinvim.lua config/nvim/lua/pinvim/review.lua passes.
5. nvim --headless '+lua require("pinvim").setup(); vim.cmd("PiReview"); vim.cmd("PiReviewClose")' '+qa' exits 0.
6. bin/pinvim-protocol-smoke passes.


## Notes

**2026-05-19T18:28:00Z**

Removed Pinvim* Neovim user-command aliases, kept PiReview as review entry point, updated pinvim command docs to Pi* only, and verified stylua/headless nvim/protocol smoke.
