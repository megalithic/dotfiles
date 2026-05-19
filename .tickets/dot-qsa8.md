---
id: dot-qsa8
status: open
deps: [dot-slr0]
links: []
created: 2026-05-19T16:12:17Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# pinvim review: jj current-change diff source

Plan step 2. Add jj-first VCS helpers for default scope=commit (current change @). Populate the nui.tree from 'jj diff -r @ --name-only'. Selecting a file loads a read-only diff buffer from 'jj diff -r @ --git -- <file>'. Add tree-local maps for refresh, next/previous file, select file, close, and g? help. Helpers live inline in config/nvim/lua/pinvim/review.lua for now (single-file dev mode); splitting into config/nvim/lua/pinvim/review/vcs.lua is deferred.

## Acceptance Criteria

1. Commit-scope jj helpers exposed inline from config/nvim/lua/pinvim/review.lua (single-file dev mode).
2. Opening review (gds) populates the file tree from jj diff -r @ --name-only.
3. Pressing <CR> on a tree entry loads a read-only diff buffer rendered from jj diff -r @ --git -- <file>.
4. Tree-local maps for refresh, next file, previous file, select, close, and g? help are registered with desc.
5. stylua --check config/nvim/lua/pinvim/review.lua clean.
6. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
7. bin/pinvim-protocol-smoke passes.

