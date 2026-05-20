---
id: dot-koz6
status: closed
deps: [dot-8n53, dot-p2ad]
links: [dot-oiky, dot-0a9p, dot-kts9, dot-rx8y, dot-8n53, dot-f6tr, dot-p2ad]
created: 2026-05-18T19:33:52Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development, done]
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

## Notes

**2026-05-18T20:15:00Z**

Implemented ephemeral split spawn with automatic previous-target restore.

Changes in `config/nvim/lua/pinvim.lua`:

- `generate_ephemeral_socket_path()`: creates `pi-{session}-{window}-eph-{epoch}-{pid}.sock` paths
- `is_ephemeral_socket()`: detects `-eph-` pattern in socket paths
- `api.spawn_ephemeral_split()`: generates ephemeral socket, records previous target in MRU, calls `pimux --new --socket`, sets buffer-local target, polls for socket creation, then connects
- `start_ephemeral_watch_timer()`: 2s polling timer that detects ephemeral socket disappearance and triggers restore of previous alive parked target
- `schedule_reconnect()`: when connected to an ephemeral socket that disappears, skips reconnection and restores previous target instead
- `PinvimSplit` / `PiSplit` commands and `gpp` keymap
- `target_link_mode()`: recognizes `"ephemeral"` source
- `statusline_data()`: includes `ephemeral` boolean
- `conn.ephemeral_watch_timer` field + stop/start/cleanup functions

No changes to `bin/pimux` (already had `--new --socket`), `pinvim.ts` (already marks IS_EPHEMERAL and excludes from discovery), or `bridge.ts` (not involved).

Verification: `bash -n bin/pimux` ✓, `nvim --headless` setup ✓, `bin/pinvim-protocol-smoke` ✓, `just validate home` ✓, `just home` ✓.

**2026-05-20T15:06:23Z**

Discovery from live use: nvim restart while typing in an ephemeral pimux loses buffer-local target state. Nvim-side manifest resume is a partial fix, but durable design should use bidirectional repair: nvim advertises peer heartbeat, pi-side pinvim.ts can repair to same-window nvim, and both sides converge through hello/hello_ack/heartbeat. Follow-up ticket: dot-rx8y.
