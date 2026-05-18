---
id: dot-koz6
status: open
deps: [dot-8n53, dot-p2ad]
links: []
created: 2026-05-18T19:33:52Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Make pinvim split spawn fresh ephemeral pi and restore previous target

Correct the nvim/pi/tmux split behavior from the nvim-pi-custom-vision plan. Creating a split from nvim must spawn a fresh pi instance with link_mode=ephemeral in a 30%-width right tmux split, immediately switch the current nvim target to that new socket, and save the previous target for restore when the split closes. Existing pi instances must remain selectable through explicit target/session commands, but must not be adopted by default when creating a split. Relevant files: bin/pimux, config/nvim/lua/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts, home/common/programs/pi-coding-agent/extensions/bridge.ts if shim behavior is touched.

## Acceptance Criteria

1. Nvim split command/keymap creates a fresh pi process with link_mode=ephemeral and a unique socket in ~/.local/state/pi/sockets/; it does not adopt any existing tmux-session pi by default.
2. Current nvim target switches to the new ephemeral socket before first send, and status/notifications identify link_mode=ephemeral.
3. Previous target is recorded before the switch and restored automatically when the ephemeral split/socket closes if that previous target is still alive.
4. Explicit target switching still works through session/target commands so the user can swap among active pi instances, including parked/manual/auto targets and the current ephemeral target.
5. Ephemeral sockets remain excluded from auto-discovery/default selection for other nvim instances, Hammerspoon, Telegram, and tell unless explicitly targeted.
6. Verification passes: bash -n bin/pimux; nvim --headless '+lua require("pinvim").setup()' +qa; bin/pinvim-protocol-smoke; manual tmux+nvim smoke for fresh split, send-to-ephemeral, close split, restore previous target.

