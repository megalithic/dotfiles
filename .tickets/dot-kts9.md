---
id: dot-kts9
status: closed
deps: []
links: [dot-gm39, dot-dylm, dot-0oy1]
parent: dot-0fjk
created: 2026-04-14T19:36:06Z
type: epic
priority: 1
assignee: Seth Messer
tags: [ready-for-development]
---
# Unify nvim↔pi communication: pinvim.ts + pinvim.lua primary link, bridge.ts shim cleanup

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:
1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

> **🔗 Cross-repo coordination:** finish nvim↔pi work in this repo. Final artifact (`pinvim.ts` + `pinvim.lua` primary link, with `bridge.ts` only if still needed as shim) ports to megadots **nvim Stage 2 reconcile** (`meg-pygn`) after closure. Tracked in `~/.local/share/pi/plans/megadots/cross-repo-status.md` + `dot-0oy1`/`meg-ppzd`.

Blend best of carderne/pi-nvim and current dotfiles workflow into a unified architecture, but make `pinvim.ts` and Neovim `pinvim.lua` the semantic owners of nvim↔pi communication.

## Background

Earlier ticket text assumed `bridge.ts` would become the durable nvim protocol owner. That is no longer target.

Current direction:
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts` owns pi-side nvim semantics
- `config/nvim/lua/pinvim.lua` owns nvim-side peer/client behavior
- `config/nvim/after/plugin/pinvim.lua` stays a thin loader/bootstrap entrypoint
- `home/common/programs/pi-coding-agent/extensions/bridge.ts` remains shim/legacy support for Hammerspoon, Telegram, tell, tmux-oriented socket compatibility, and any transitional ingress that still needs it

`bridge.ts` may remain for non-nvim clients or be deprecated later, but it should not be long-term semantic owner of nvim live context, handshake state, review state, or pinvim UX.

## Architecture

**pinvim.ts (primary pi-side nvim owner):**
- Own nvim peer/session state in pi memory
- Own `hello` / `hello_ack` / `heartbeat` semantics and peer freshness
- Own live editor context state and `before_agent_start` injection
- Own pinvim footer/status surfaces and `/pinvim-*` commands
- Own future review-bundle state, policy injection, and nvim-aware routing
- Stay transport-agnostic where possible; transport details should not dominate this file

**pinvim.lua (primary nvim-side peer/client):**
- Persistent `vim.uv.new_pipe()` connection
- Socket discovery, ranked target selection, reconnect, ping/pong, and lifecycle
- Send `hello`, `heartbeat`, live `editor_state`, explicit sends, and future structured envelopes
- Own compose/raw-prompt/selection/file-send parity on nvim side
- Own link history, MRU restore, and statusline-facing link metadata

**after/plugin/pinvim.lua (thin loader):**
- Guard/feature-flag/bootstrap only
- Require `lua/pinvim.lua` and avoid housing core logic

**bridge.ts (shim / legacy ingress):**
- Keep socket + manifest support needed by Hammerspoon / Telegram / tell / tmux helpers
- Preserve compatibility for non-nvim ingress that still relies on current socket contract
- May proxy or forward transitional frames only when necessary
- Must not become source of truth for pinvim protocol semantics, live editor state ownership, review UX, or pi-side policy decisions

**Legacy pi.lua path:**
- Legacy compatibility may remain outside the fresh primary module while migration finishes.
- New semantic ownership should not depend on legacy `mega.p.pi` code paths.
- Fresh `pinvim.lua` must not restore `mega.p.pi` or legacy keymaps as its public API.

## UX boundary update (2026-05-14)

Fresh primary UX should start with these expectations:

1. From nvim, create or focus a tmux split 30% wide to the right of the nvim pane. The split runs pi and should be able to adopt/take over the current nvim↔pi handshake when an existing pi in the tmux session is active.
2. Explicit send beats implicit live streaming for user-facing workflow: select code (or use cursor/word context), press a fresh keybinding such as `gps` if available, send structured context to the handshaked `pinvim.ts`, then focus the linked pi pane so prompt text can continue there.
3. `vim.notify` feedback should accurately report connect, target, split, send, focus, stale target, failure, and cleanup events.
4. Annotation/queue is future fresh UX: likely `gpa` to annotate word/selection through annotator.nvim, then batch file/diff annotations to pi. hunk.nvim and codediff.nvim may supply diff/hunk context.
5. Statusline and notifications should use new pinvim state directly, not legacy `mega.p.pi` compatibility.
6. Provide user commands for bidirectional communication health/status/info and explicit send to the handshaked pi instance.
7. Keep core fresh link: socket discovery, persistent `vim.uv.new_pipe()`, `hello`/`hello_ack`/`heartbeat`, explicit editor context send, status/health/info commands.

## Key files

- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `config/nvim/after/plugin/pinvim.lua`
- `config/nvim/lua/pinvim.lua`
- `config/hammerspoon/lib/interop/pi.lua`

## Canonical protocol direction

Primary nvim↔pi protocol should be between `config/nvim/lua/pinvim.lua` and `home/common/programs/pi-coding-agent/extensions/pinvim.ts`.

Canonical frame types for this ticket line:
- `{ type: 'hello', protocol, peer, capabilities }`
- `{ type: 'hello_ack', protocol, peer, accepts }`
- `{ type: 'heartbeat', protocol, peerId, sentAt }`
- `{ type: 'editor_state', state: { file, cursor, selection, filetype, ... } }`
- raw prompt / explicit send / compose payloads needed for parity
- future structured envelopes and review bundles build on this owner split

Whether some frames temporarily pass through `bridge.ts` is implementation detail. Semantic ownership still belongs to `pinvim.ts` + `pinvim.lua`.

## Future state (not in scope)

- Full HTTP/SSE transport replacement
- ACP (Agent Context Protocol) for multi-agent orchestration
- Final `bridge.ts` deprecation decision after Hammerspoon / Telegram / tell / tmux dependencies are clearer
- Tidewave Web MCP integration (nvim + pi + tidewave runtime intelligence)

## Acceptance Criteria

1. `pinvim.ts` is documented and implemented as primary pi-side owner for nvim semantics: peer metadata, live context, footer/status, commands, and future nvim-aware state.
2. `config/nvim/lua/pinvim.lua` is documented and implemented as primary nvim-side peer/client, with `config/nvim/after/plugin/pinvim.lua` as thin loader only.
3. End-to-end `hello` / `hello_ack` / `heartbeat` path exists for primary pinvim link, including peer id, cwd/root, tmux identity, link mode, and freshness tracking.
4. Live editor state sync from `pinvim.lua` reaches `pinvim.ts` with debounced autocmd updates, reconnect handling, and disconnect cleanup.
5. `pinvim.ts` injects `[NEOVIM LIVE CONTEXT]` via `before_agent_start` when editor state is available.
6. `pinvim.ts` shows nvim status in pi footer and exposes inspection/debug command(s) for current peer/editor state.
7. `pinvim.lua` uses persistent `vim.uv.new_pipe()` communication with reconnect/health checks and discovery from manifest/env/buffer/tmux sources.
8. `pinvim.lua` supports fresh explicit send UX for visual selection and cursor/word context to the handshaked `pinvim.ts`; it does not restore legacy `mega.p.pi` or legacy keymaps.
9. `pinvim.lua` preserves key new UX: statusline-facing state, accurate notifications, buffer-local/session target state, tmux right-split integration, and recoverable target context across reconnects or parked sessions.
10. `bridge.ts` is limited to shim/legacy support for Hammerspoon, Telegram, tell, tmux-oriented helpers, manifests, and transitional ingress; it does not own pinvim semantic state.
11. Existing Telegram, tell, Hammerspoon, and tmux helper flows continue to work during migration.
12. `just validate home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and manual smoke tests confirm primary `pinvim.lua` ↔ `pinvim.ts` link behavior.
