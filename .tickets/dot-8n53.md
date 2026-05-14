---
id: dot-8n53
status: open
deps: [dot-p2ad]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Restore previous pi targets from nvim MRU history

Implement Step 5 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Add nvim-side target history in `config/nvim/lua/pinvim.lua` so link state can fall back to previous alive parked pi target when current target disappears. Add explicit commands for previous/restore behavior and reflect link mode in statusline data.

## Acceptance Criteria

1. Nvim tracks MRU pi targets with enough metadata to distinguish auto, manual, ephemeral, and parked links.
2. When active socket disappears, `pinvim.lua` can restore previous alive parked target instead of dropping straight to discovery.
3. User commands for previous/restore behavior exist and are documented in pinvim keymaps or command definitions.
4. Statusline data reflects current link mode and restored-target state.
5. `nvim --headless "+lua require('pinvim').setup()" +qa` passes and manual close/restore testing works.
