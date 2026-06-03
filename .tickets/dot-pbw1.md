---
id: dot-pbw1
status: closed
deps: [dot-qsa8]
links: []
created: 2026-05-19T16:12:26Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# pinvim review: annotation store and gpa keymap

Plan step 3. Implement in-memory review annotations keyed by file plus line/range. Use a dedicated extmark namespace for source and diff buffers. The gpa keymap is registered by config/nvim/lua/pinvim/review.lua itself (not by config/nvim/lua/pinvim.lua); in review mode it prompts for an annotation/comment on the current line or visual range, and outside review mode it no-ops with guidance to start review mode with gds. Add review-local maps/functions for next/previous annotation, delete annotation, clear annotations, and preview bundle, all registered by the review module.

## Acceptance Criteria

1. Annotation store keyed by {file, line/range} with optional metadata is implemented in pinvim/review.lua.
2. Dedicated extmark namespace used; annotations render as virtual text or sign in both source and diff buffers.
3. gpa keymap is registered by config/nvim/lua/pinvim/review.lua (not by pinvim.lua); in review mode it prompts (line or visual range) and stores the annotation.
4. gpa outside review mode no-ops with a message guiding user to gds.
5. Maps for next-annotation, prev-annotation, delete-annotation, clear-all, preview-bundle registered with desc.
6. stylua --check config/nvim/lua/pinvim.lua config/nvim/lua/pinvim/review.lua clean.
7. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
8. bin/pinvim-protocol-smoke passes.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.
