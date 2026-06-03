---
id: dot-msws
status: open
deps: []
links: []
created: 2026-06-03T20:11:03Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add pinvim workspace identity, registry layout, and launch lock

Plan Step 1. Add stable workspace + process identity. Workspace root at $PI_STATE_DIR/pinvim/<workspace-hash>/ with persisted parent.id; per-Nvim-instance dirs under instances/<nvim-instance-id>/. Separate writer files: main.intent.json (Nvim), main.runtime.json (Pi), children/<child-id>/{intent,runtime}.json. Atomic launch lock for main-session spawn. Existing manifests stay as fallback. One-time import from current tmux options/manifests when registry absent. Files: config/nvim/lua/pinvim.lua. Plan: ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md

## Acceptance Criteria

1. :PiInfo shows parent/workspace/instance ids and registry root
2. Headless registry write works
3. First run can seed registry from existing live state without breaking current sessions
4. nvim --headless '+lua require("pinvim").setup(); print(vim.inspect(require("pinvim").api.info()))' +qa succeeds
5. Existing pinvim handshake still works
