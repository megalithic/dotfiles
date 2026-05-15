---
id: dot-f6tr
status: closed
deps: [dot-hp1p]
links: []
created: 2026-05-14T20:28:21Z
type: feature
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [nvim, pi, protocol, ready-for-development]
---
# feat(pinvim): peer handshake + hello/hello_ack protocol

Primary protocol handshake between config/nvim/lua/pinvim.lua (nvim-side) and home/common/programs/pi-coding-agent/extensions/pinvim.ts (pi-side). Add explicit peer identity: peer id, cwd/root, tmux session/window/pane identity, link mode (auto/manual/ephemeral/parked), heartbeat timestamps. bridge.ts not involved in nvim semantic ownership; update only if shim manifest compatibility for non-nvim clients needs preservation. Must work after dot-hp1p XDG dir change. Verify with `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and `bin/pinvim-protocol-smoke`.

Builds on https://github.com/carderne/pi-nvim and https://github.com/azorng/vision.nvim peer concepts but stays with persistent vim.uv.new_pipe() model, not pull/hook model.

## Acceptance Criteria

1. End-to-end `hello` / `hello_ack` / `heartbeat` path exists for primary pinvim link, including peer id, cwd/root, tmux session/window/pane identity, link mode (auto/manual/ephemeral/parked), and freshness tracking.
2. `pinvim.ts` is documented and implemented as primary pi-side owner for nvim semantics: peer metadata, live context, footer/status, commands, and future nvim-aware state.
3. `config/nvim/lua/pinvim.lua` is documented and implemented as primary nvim-side peer/client, with `config/nvim/after/plugin/pinvim.lua` as thin loader only.
4. `vim.notify` accurately reports every lifecycle event: connect, target selection, split creation/focus, send success/failure, stale target, missing socket, disconnect, and cleanup. Notifications must use new pinvim state directly; never restore legacy `mega.p.pi` wrappers or keymaps.
5. User commands exist for bidirectional communication health/status/info and explicit send to the handshaked pi instance (e.g. `/pinvim-health`, `/pinvim-status`, `/pinvim-send`).
6. `pinvim.ts` shows nvim status in pi footer and exposes inspection/debug command(s) for current peer/editor state.
7. `pinvim.lua` uses persistent `vim.uv.new_pipe()` communication with reconnect/health checks and discovery from manifest/env/buffer/tmux sources.
8. `bridge.ts` is limited to shim/legacy support for Hammerspoon, Telegram, tell, tmux-oriented helpers, manifests, and transitional ingress; it does not own pinvim semantic state.
9. Live context is audited and safe: default automatic `live_context` is disabled, explicit `gps`/`:PinvimSend` remains primary nvim→pi context path, `/pinvim-info` documents architecture/setup, and safety controls cover opt-in enablement, debounce, buftype/file checks, size limits, freshness, and idle/follow-up delivery behavior.
10. `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and `bin/pinvim-protocol-smoke` all pass; smoke test confirms deterministic hello -> hello_ack -> heartbeat cycle.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

