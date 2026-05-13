---
id: dot-dylm
status: open
deps: []
links: [dot-kts9, dot-0oy1]
created: 2026-05-13T20:48:05Z
type: epic
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [ready-for-development]
---
# Build custom nvim+pi vision integration

Seeded from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_TASK.md and ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md.

Extend current persistent nvim↔pi bridge with XDG state directories, explicit peer identity, ranked discovery, parked tmux pi sessions, structured review bundles, and editor-aware policy injection. Keep current bridge architecture; only borrow capture/ranking ideas from vision.nvim. Relevant files span home/common/programs/pi-coding-agent/, config/nvim/, config/hammerspoon/, and bin/.

## Acceptance Criteria

1. Child tickets exist for all 9 implementation steps in nvim-pi-custom-vision_PLAN.md.
2. Planned work preserves current persistent nvim→pi bridge; vision.nvim ideas are additive, not a transport replacement.
3. Planned work keeps ephemeral sockets explicit-only and never auto-selects them.
4. Final integrated result is verifiable with `just validate home` plus tmux+nvim manual smoke tests for primary, parked, and ephemeral pi flows.

