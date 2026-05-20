---
id: dot-rx8y
status: in_progress
deps: []
links: [dot-oiky, dot-0a9p, dot-kts9, dot-koz6, dot-8n53, dot-f6tr, dot-p2ad]
created: 2026-05-20T15:06:23Z
type: feature
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# Implement bidirectional pinvim peer repair after nvim restart

Follow-up discovery from live pinvim usage: after restarting Neovim, a live ephemeral pimux could still be typing in the same tmux window, but nvim-side buffer-local target state was gone. The immediate nvim-side manifest resume helps, but durable repair should be bidirectional.

Implement a canonical repair loop between config/nvim/lua/pinvim.lua and home/common/programs/pi-coding-agent/extensions/pinvim.ts:

- nvim advertises fresh peer presence/heartbeat in XDG state or an equivalent pinvim-owned rendezvous channel.
- pi-side pinvim.ts scans or receives nvim peer candidates in the same tmux session/window/root and attempts/accepts repair when its linked nvim peer is missing or stale.
- nvim-side discovery remains active so either side can reestablish the hello/hello_ack/heartbeat link.
- Ephemeral pi instances may repair to same-window nvim peers; non-ephemeral repair stays conservative to avoid stealing links.
- Link repair should be visible in PiStatus/PiHealth/notifications and avoid context bleed across unrelated nvim/pi instances.

Relevant files: config/nvim/lua/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts, bin/pimux, lat.md/lat.md, and related pinvim protocol smoke tests.

Related discovery links: dot-dylm parent epic, dot-kts9 original ownership epic, dot-f6tr handshake, dot-oiky ranked discovery, dot-p2ad parked/MRU registry, dot-8n53 restore, dot-koz6 ephemeral split restore.

## Acceptance Criteria

1. nvim publishes enough peer metadata (id, cwd/root, tmux session/window/pane, pid, heartbeat, current socket/link mode) for pi-side repair without relying on buffer-local state.
2. pinvim.ts can detect a stale/missing nvim peer and select a same-tmux-session candidate, preferring same window, then same cwd/root, then freshest heartbeat.
3. Ephemeral pi repair is allowed only for same-window or explicit/recent same-root matches; non-ephemeral repair cannot steal unrelated nvim instances.
4. Either side can reestablish hello/hello_ack/heartbeat after Neovim restart or pi-side peer loss, and PiStatus/PiHealth show repaired peer state.
5. Repair path does not route context to unrelated primary pi, unrelated ephemeral pi, Hammerspoon/Telegram/tell targets, or another nvim instance in same cwd but different window.
6. Verification passes: nvim --headless '+lua require("pinvim").setup()' +qa; bin/pinvim-protocol-smoke; manual tmux smoke where ephemeral pimux survives nvim restart and repairs to the new same-window nvim.
7. lat.md pinvim section and nvim-pi-custom-vision plan/task notes document bidirectional repair and updated ephemeral auto-resume rules.
