---
id: dot-f36u
status: open
deps: [dot-y4vm]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Add explicit nvim↔pi peer handshake metadata

Implement Step 2 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Add an explicit hello/hello_ack handshake between config/nvim/after/plugin/pi.lua, home/common/programs/pi-coding-agent/extensions/bridge.ts, and home/common/programs/pi-coding-agent/extensions/pinvim.ts. Each side should track peer id, cwd/root, tmux session/window/pane, link mode, and heartbeat timestamps while keeping current payloads backward-compatible.

## Acceptance Criteria

1. Bridge and nvim exchange explicit `hello` / `hello_ack` metadata on connect, including peer id, cwd/root, tmux identity, and link mode.
2. Peer metadata is exposed to pinvim state without breaking existing selection/cursor/file/editor_state flows.
3. Legacy payloads still work during rollout; older messages are rejected gracefully or upgraded without crashing the bridge.
4. `nvim --headless "+lua print('nvim ok')" +qa` and `just validate home` both pass after the protocol change.

