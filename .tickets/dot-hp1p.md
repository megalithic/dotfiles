---
id: dot-hp1p
status: open
deps: []
links: []
created: 2026-05-14T20:28:18Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [nvim, pi, infrastructure, ready-for-development]
---
# refactor(pi): move sockets+manifests to XDG state dirs

Move pi sockets and discovery manifests from /tmp/ into ~/.local/state/pi/ with sockets/ and manifests/ subdirs. Define PI_STATE_DIR once in nix module. Replace PI_SOCKET_DIR/PI_SOCKET_PREFIX with derivations from PI_STATE_DIR. Keep PI_SOCKET override for explicit targeting. Update bridge.ts (shim), pinvim.lua (primary nvim client), pinvim.ts (primary pi owner), hammerspoon pi.lua (legacy shim client), tmux-toggle-pi, and ftm. Ensure dirs created on startup. Must not break existing Telegram/tell/Hammerspoon/tmux flows. Verify: just validate home; confirm no stale /tmp/pi-*.sock created; confirm nvim/hammerspoon/tmux all discover correctly.

