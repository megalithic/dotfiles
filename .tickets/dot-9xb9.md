---
id: dot-9xb9
status: closed
deps: [dot-5acm]
links: []
created: 2026-05-19T17:58:37Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# pinvim review: wire jj/git and pi extensions to pinvim review

Plan step 9 of ~/.local/share/pi/plans/dotfiles/pinvim-review-diff-mode_PLAN.md. Make the nvim-based review UI the default diff/review tool for jj and git global config, and teach pi-coding-agent skills/extensions to invoke it. Add a small launcher (e.g. bin/pinvim-diff) that opens nvim with +PiReview (or scope-specific variant) against given refs/files. Configure jj (ui.diff-editor / ui.diff.tool / ui.merge-editor where applicable) and git (diff.tool / difftool.<name>.cmd / optional 'git review' alias) via nix-managed config under home/common/programs/jj/ and home/common/programs/git/. Update the stop-hook, ticket-worker, ticket-creator, task-pipeline, and preview extensions so any code-review / diff-presentation step routes through pinvim review (spawn or attach to an active review session via the existing pinvim socket protocol) instead of plain text dumps or ad-hoc previews. Document the launch contract: how an extension launches a review, passes scope (commit / bookmark / arbitrary refs / file list), and detects when pinvim/nvim is unavailable so it can fall back gracefully.

## Acceptance Criteria

1. bin/pinvim-diff (or equivalent) exists, accepts refs/file args from jj/git, and launches nvim with the appropriate PiReview invocation.
2. home/common/programs/jj/ sets ui.diff-editor (and ui.diff.tool / ui.merge-editor where applicable) so 'jj diff' / 'jj show' open the pinvim review UI by default.
3. home/common/programs/git/ sets diff.tool and difftool.<name>.cmd so 'git difftool' opens the pinvim review UI; optional 'git review' alias documented.
4. pi-coding-agent extensions stop-hook, ticket-worker, ticket-creator, task-pipeline, and preview launch or attach to a pinvim review session over the existing socket protocol instead of dumping raw diff text or using ad-hoc previewers.
5. Documented launch contract covers: how to launch a review, how scope (commit | bookmark | arbitrary refs | explicit file list) is passed, and the fallback path when nvim or the pinvim socket is unavailable.
6. Fallback path produces a clear human-readable message rather than a crash when nvim/pinvim socket is missing.
7. just validate home passes.
8. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
9. bin/pinvim-protocol-smoke passes.
10. Manual: 'jj diff' in a dirty repo opens pinvim review; 'git difftool' opens pinvim review; triggering a stop-hook / ticket-worker review surface launches or attaches to a pinvim review session; preview extension diff path renders through pinvim review.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.
