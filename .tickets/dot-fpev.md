---
id: dot-fpev
status: open
deps: [dot-vnmm]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Export codediff and annotator review bundles for pi

Implement Step 7 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Add review-bundle export from config/nvim/lua/plugins/codediff.lua and new nvim review helpers (for example config/nvim/lua/pi/review.lua) wired through config/nvim/after/plugin/pi.lua. Export diff session, hunk context, annotations, selected ranges, VCS metadata, and requested action as a `pinvim.review.v1` payload.

## Acceptance Criteria

1. Nvim can export a `pinvim.review.v1` bundle containing diff session metadata, hunk context, annotations, selected ranges, and requested action.
2. Review export is wired into existing codediff/annotator surfaces rather than requiring a separate scratch workflow.
3. Bundle generation handles both jj and git-backed diffs where current codediff integration supports them.
4. `nvim --headless "+lua require('pi.review')" +qa` succeeds and manual review-bundle smoke test produces a payload for pi.

