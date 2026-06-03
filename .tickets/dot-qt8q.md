---
id: dot-qt8q
status: closed
deps: [dot-9xb9]
links: []
created: 2026-05-19T16:13:15Z
type: chore
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# pinvim review: docs, which-key labels, keymap notes

Plan step 10. Update nvim pinvim command/keymap docs for gds, gpa, gps, gpS, and review-buffer g?. Add which-key labels for gp review/send mappings if needed. Document native-window + nui.tree layout choice, review-local maps, scope names (commit, bookmark), bundle behavior, and the research lineage from dot-fpev and dot-t4dd. Keep this plan/ticket path independent for new dot-dylm tickets.

## Acceptance Criteria

1. config/nvim/AGENTS.md documents gds (toggle review), gpa (annotate, review-only), gps (send no-prompt, mode-aware), gpS (send with-prompt, mode-aware), and g? review help.
2. config/nvim/lua/plugins/whichkey.lua updated with labels for gp send keys and gds review toggle.
3. Docs describe layout (native nvim windows + nui.tree), scope names (commit, bookmark), bundle protocol (pinvim.review.v1), and reference research lineage dot-fpev and dot-t4dd.
4. stylua --check config/nvim/lua/plugins/whichkey.lua clean.
5. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
6. bin/pinvim-protocol-smoke passes.
7. Manual: which-key shows updated gp labels; g? in a review buffer lists review-local maps.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.
