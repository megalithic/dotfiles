---
id: dot-8n53
status: closed
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
4. Statusline data reflects current link mode and restored-target state using ` mega.p.pinvim` state directly. It must not depend on or restore legacy `mega.p.pi` compatibility.
5. `nvim --headless "+lua require('pinvim').setup()" +qa` passes and manual close/restore testing works.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.


## Notes

**2026-05-18T18:36:36Z**

Implemented nvim-side pinvim MRU target history with parked-target restore, PiPrevious/PiRestore commands, gpR keymap, and statusline link-mode/restored indicators. Verified just home, pinvim headless setup, protocol smoke, command/statusline smoke, and manual mocked parked restore.
