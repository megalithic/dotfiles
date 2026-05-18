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

Implement Step 4 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Add fresh bin/pimux command for nvim-driven ephemeral pi splits plus reusable parked pi panes or sessions. Default nvim split UX must spawn a fresh pi instance in a 30%-width right tmux split, immediately pair nvim with that new ephemeral socket, and save the previous nvim target for restore when the split closes. Existing pi instances remain selectable through explicit target/session commands, but must not be adopted by default when creating a split.

## Acceptance Criteria

1. Primary nvim UX provides a command/keymap to create a 30%-width tmux split to the right of the current nvim pane, spawning a fresh pi instance rather than adopting any existing tmux-session pi.
2. Spawned split pi uses `link_mode = "ephemeral"`, a unique socket, and becomes the current nvim target before the first send.
3. Nvim records the previous target before switching to the ephemeral split and restores that previous alive target when the split/socket closes.
4. Explicit target switching remains available so the user can swap among active pi instances, including parked/manual/auto targets and the current ephemeral target.
5. `pimux` can park and restore reusable pi panes or sessions for explicit reuse without making parked adoption the default split behavior.
6. Active, previous, MRU, ephemeral, and parked socket metadata is persisted in tmux/nvim state with a documented schema.
7. `bash -n bin/pimux` passes and manual tmux+nvim smoke confirms: split creates a fresh pi/socket, nvim target switches to it, explicit target switching works, and closing the split restores the prior target.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

