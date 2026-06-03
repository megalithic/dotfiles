---
id: dot-5acm
status: closed
deps: [dot-jkt6]
links: []
created: 2026-05-19T16:13:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# pinvim review: bookmark scope with PR-base fallback

Plan step 7. Add scope=bookmark alongside default scope=commit. For jj, resolve the active bookmark, prefer GitHub PR base via 'gh pr view', and fall back to main/trunk/trunk() when no PR is found. Use 'jj diff --from <base> --to @' for file list and diffs. Add PiReviewScope commit|bookmark / PinvimReviewScope commit|bookmark command and a review-local scope switch keymap. The scope-switch keymap is registered by config/nvim/lua/pinvim/review.lua itself (not by pinvim.lua). Bookmark-scope helpers added inline to config/nvim/lua/pinvim/review.lua (single-file dev mode); future split into config/nvim/lua/pinvim/review/vcs.lua is deferred.

## Acceptance Criteria

1. Bookmark-scope resolver exposed inline from config/nvim/lua/pinvim/review.lua resolves base via gh pr view, falling back to main/trunk/trunk() with a clear warning when no PR is found.
2. scope=bookmark populates file tree from jj diff --from <base> --to @ --name-only and renders per-file diffs from jj diff --from <base> --to @ --git -- <file>.
3. PiReviewScope/PinvimReviewScope commit|bookmark commands work and update UI immediately.
4. Review-local scope switch keymap registered by config/nvim/lua/pinvim/review.lua with desc.
5. stylua --check config/nvim/lua/pinvim/review.lua clean.
6. just validate home passes.
7. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
8. bin/pinvim-protocol-smoke passes.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.
