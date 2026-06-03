---
id: dot-jkt6
status: closed
deps: [dot-bfr1]
links: []
created: 2026-05-19T16:12:57Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# pinvim review: review-scoped ephemeral pimux split

Plan step 6. Add review split support to bin/pimux: allow 25% split sizing and review-mode env hints. Extend spawn_ephemeral_split to accept review options. When review mode starts, spawn/focus a right 25% ephemeral pi split scoped to the review session, then send initial diff-mode context after socket handshake (env hint plus initial review_bundle frame). On review close/end, attempt to clean up only the review split without disturbing other pi panes.

## Acceptance Criteria

1. bin/pimux supports a review option that creates a right 25% split and exports a review-mode env hint.
2. Starting review mode in nvim spawns the review pi split, pairs nvim to its socket, and preserves the previous target.
3. Ephemeral pi receives an initial diff-mode context (env hint + initial review_bundle after handshake) so /pinvim-review reflects the active review immediately.
4. Closing review mode cleans up only the review-scoped pi pane and restores the previous pinvim target.
5. bash -n bin/pimux clean.
6. stylua --check config/nvim/lua/pinvim.lua config/nvim/lua/pinvim/review.lua clean.
7. just validate home passes.
8. nvim --headless '+lua require("pinvim").setup()' '+qa' exits 0.
9. bin/pinvim-protocol-smoke passes.
10. Manual in tmux: gds opens review UI and a 25% pi pane; closing review removes only that pane.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.
