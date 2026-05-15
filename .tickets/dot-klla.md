---
id: dot-klla
status: closed
deps: []
links: []
created: 2026-05-15T14:57:01Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Remove implicit live_context and editor_state from pinvim

Remove the current live_context implementation from both nvim and pi sides. Current explicit send/queue paths are the only supported nvim→pi context path for now.

Relevant files:
- `config/nvim/lua/pinvim.lua`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `docs/pinvim-live-context-audit.md`
- `~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md`
- `~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_TASK.md`

Future live context must be redesigned separately: explicit nvim keymap/motion initiated, same tmux window / active handshake only, pi acknowledges injection, and the conversation visibly shows that nvim context was injected by the user. Implicit mode may be an opt-in later, but is not part of this cleanup.

## Acceptance Criteria

1. nvim-side live_context config, timers, autocmd registration, `build_editor_state`, `push_editor_state`, and `editor_state` sends are removed from `config/nvim/lua/pinvim.lua`.
2. pi-side hidden live_context injection, editorState storage for live context, stale live-context logic, and `before_agent_start` `pinvim-live-context` hook are removed from `pinvim.ts`.
3. `bridge.ts` no longer treats `editor_state` as supported nvim live context; transitional handling is removed or returns a clear unsupported response without affecting `explicit_send`, `prompt`, `hello`, and `heartbeat`.
4. Explicit send and queue flows still work through `gps`, `:PinvimSend`/`:PiSend`, `PinvimAdd`/`PiAdd`, and `PinvimFlush`/`PiFlush`.
5. Plans/docs/tickets no longer describe implicit live_context as current behavior; future live context is documented as explicit, acknowledged, same-window/handshaked research only.
6. Verification passes: `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and `bin/pinvim-protocol-smoke`.

## Notes

**2026-05-15T15:12:55Z**

Removed implicit nvim live_context/editor_state path from pinvim. Kept explicit send/queue via gps, PinvimSend/PiSend, PinvimAdd/PiAdd, and PinvimFlush/PiFlush; bridge now rejects editor_state/editor_disconnect with clear unsupported response.
