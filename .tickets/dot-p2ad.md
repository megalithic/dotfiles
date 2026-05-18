---
id: dot-p2ad
status: closed
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

Implement Step 4 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Add fresh bin/pimux command to keep reusable parked pi panes or sessions instead of treating split close as teardown only. Track active, last, MRU, and parked socket state in tmux user options so pi panes can be hidden and restored without losing session history. Keep bin/tmux-toggle-pi as legacy for later deprecation/sunset.

## Acceptance Criteria

1. Primary nvim UX provides a command/keymap to create or focus a 30%-width tmux split to the right of the current nvim pane, running pi. When an existing handshaked pi is active for the tmux session, the split adopts/takes over that handshake instead of spawning a fresh unlinked pi.
2. `pimux` can park and restore reusable pi panes or sessions instead of always creating a fresh process.
3. Active, last, MRU, and parked socket metadata is persisted in tmux user options with a documented schema.
4. Toggling hide/show preserves history and reconnects to the intended parked pi instance.
5. `bash -n bin/pimux` passes and manual tmux smoke test confirms park/restore behavior.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

