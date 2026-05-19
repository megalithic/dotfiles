---
id: dot-slr0
status: closed
deps: []
links: [dot-rv9w]
created: 2026-05-19T16:12:09Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# pinvim review: skeleton module and gds toggle UI

Plan step 1 of ~/.local/share/pi/plans/dotfiles/pinvim-review-diff-mode_PLAN.md. Create config/nvim/lua/pinvim/review.lua as separate module required from config/nvim/lua/pinvim.lua without rewriting core transport. The gds review-toggle keymap is registered by the review module itself (in its own setup()/loader); pinvim.lua only loads the module. Opening review uses native nvim windows: left nui.tree changed-file tree at 20% width, right scratch diff viewer placeholder; closing restores prior layout. Add review-buffer local maps with desc values and g? buffer-local which-key help. Add PiReview/PinvimReview, PiReviewClose/PinvimReviewClose, PiReviewStatus/PinvimReviewStatus commands.

## Acceptance Criteria

1. config/nvim/lua/pinvim/review.lua exists and is required from config/nvim/lua/pinvim.lua without rewriting existing transport.
2. gds review-toggle keymap is registered by config/nvim/lua/pinvim/review.lua itself (not by config/nvim/lua/pinvim.lua); toggling opens 20%/80% left tree + right diff placeholder, second press restores prior layout.
3. PiReview/PinvimReview, PiReviewClose/PinvimReviewClose, PiReviewStatus/PinvimReviewStatus commands defined and functional.
4. Review-buffer local maps registered with desc; g? in a review buffer shows which-key listing of those maps.
5. stylua --check config/nvim/lua/pinvim.lua config/nvim/lua/pinvim/review.lua clean.
6. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
7. bin/pinvim-protocol-smoke passes.


## Notes

**2026-05-19T18:23:23Z**

Implemented pinvim review skeleton module, gds toggle UI, review commands, native 20/80 review layout, and review-buffer maps with which-key help.
