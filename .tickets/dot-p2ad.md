---
id: dot-p2ad
status: open
deps: [dot-oiky]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Add parked tmux pi registry and MRU tracking

Implement Step 4 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Extend bin/tmux-toggle-pi to keep reusable parked pi panes or sessions instead of treating split close as teardown only. Track active, last, MRU, and parked socket state in tmux user options so pi panes can be hidden and restored without losing session history.

## Acceptance Criteria

1. `tmux-toggle-pi` can park and restore reusable pi panes or sessions instead of always creating a fresh process.
2. Active, last, MRU, and parked socket metadata is persisted in tmux user options with a documented schema.
3. Toggling hide/show preserves history and reconnects to the intended parked pi instance.
4. `bash -n bin/tmux-toggle-pi` passes and manual tmux smoke test confirms park/restore behavior.

