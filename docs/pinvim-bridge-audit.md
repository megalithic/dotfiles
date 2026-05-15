# Pinvim / bridge audit

## Scope

Files audited for `dot-kts9`:

- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/pinvim_legacy.ts`
- `config/nvim/lua/pinvim.lua`
- `config/hammerspoon/lib/interop/pi.lua`

## What `bridge.ts` does today

`bridge.ts` is current Unix-socket ingress point for pi-side integrations.

Responsibilities observed during audit:

- own per-session socket path resolution
- write `.info` manifest for discovery
- parse newline-delimited JSON from clients
- respond with `{ ok: true }` / `{ ok: false, error }`
- route `prompt` payloads into `pi.sendUserMessage(...)`
- route Telegram payloads into pi user messages
- route tell/delegate payloads into pi user messages
- forward legacy nvim `editor_state` and `editor_disconnect` to pi event bus
- accept legacy nvim payloads without a `type` field and format them as user text

## What `bridge.ts` does not do today

Before any implementation detour, audited baseline was:

- no `hello` handler
- no `hello_ack` handler
- no `heartbeat` handler
- no pinvim-specific peer-state ownership
- no live-context injection logic
- no pinvim-specific footer/status ownership

That is why wiring handshake semantics directly into `bridge.ts` felt wrong: it would turn transport into protocol owner.

## Why `pinvim.ts` should be primary pi-side extension

`pinvim.ts` is better place for nvim behavior because it now owns:

- nvim↔pi socket lifecycle
- manifest writing for nvim-discoverable sockets
- request/response framing for pinvim frames
- footer/status rendering
- peer metadata (`hello`, `hello_ack`, `heartbeat`)
- user-facing pinvim commands
- explicit context delivery

This keeps nvim protocol out of `bridge.ts`.

## Recommended ownership split

### `pinvim.ts`

Primary pi-side nvim extension.

Owns:

- nvim↔pi socket lifecycle
- manifest writing for nvim-discoverable sockets
- request/response framing for pinvim frames
- status/footer display
- peer handshake state
- explicit context delivery

### `bridge.ts`

Legacy transport shim. Disabled by default unless `PI_BRIDGE_LEGACY_SOCKET=1`.

Owns:

- temporary Telegram ingress if explicitly enabled
- temporary tell ingress if explicitly enabled
- legacy request/response framing for non-nvim clients

Should not own:

- nvim socket lifecycle
- pinvim handshake semantics
- pinvim UI decisions
- pinvim context formatting
- pinvim product behavior

### `config/nvim/lua/pinvim.lua`

Editor-side peer/client.

Owns:

- discovery
- connection lifecycle
- message sending
- autocmd-driven sync
- local commands and buffer awareness

## Current direction (2026-05-15)

`bridge.ts` is now a deprecation target, not a durable architecture layer.

Immediate next steps:

1. `dot-klla`: remove implicit `live_context` / `editor_state` from nvim + pi.
2. Immediate follow-up: move nvim socket ownership from `bridge.ts` into `pinvim.ts`.
3. `dot-3t42`: inventory remaining non-nvim `bridge.ts` users and plan focused replacements.

Target split:

- `pinvim.ts`: pi↔nvim socket, peer handshake, explicit send/queue/review/policy payloads.
- possible `hs.ts`: Hammerspoon↔pi ingress.
- possible `tmux.ts`: tmux helper/session discovery APIs.
- possible `ntfy.ts`: richer pi-side counterpart to `~/bin/ntfy`; Telegram only matters through current ntfy usage.
- tell/delegation owner: focused task delegation ingress instead of shared bridge monolith.
- shared utility only if needed: socket/manifest helpers without product semantics.

Research must enumerate remaining bridge consumers before removal: Hammerspoon, Telegram/ntfy, tell/skills, any legacy clients, and any additional socket clients found by code search. nvim/pinvim moved to `pinvim.ts`.

## Deprecation paths for `bridge.ts`

### Path A — keep bridge, narrow scope

Keep `bridge.ts`, but only as transport shim.

Good if:

- Telegram and tell still need same socket entrypoint
- Hammerspoon still depends on current socket contract
- nvim transport still wants same Unix socket

### Path B — deprecate bridge for nvim only

Implemented: nvim transport moved to `pinvim.ts`; `bridge.ts` only remains as opt-in legacy socket for non-nvim clients.

Good because:

- pinvim owns its protocol end-to-end
- nvim protocol evolves without bridge coupling

### Path C — full deprecation

Remove `bridge.ts` after all clients move elsewhere.

Requires:

- Telegram ingress replacement
- tell ingress replacement
- nvim transport replacement
- manifest/discovery replacement where needed

## Decision from earlier ticket pass

- revert handshake logic from `bridge.ts`
- make `pinvim.ts` primary pi-side nvim extension
- move nvim socket ownership into `pinvim.ts`
- keep `bridge.ts` opt-in legacy transport for non-nvim clients only
- leave final `bridge.ts` deletion for later, after non-nvim ingress replacements are clear

## Updated decision

Deprecate `bridge.ts` after remaining non-nvim inventory and replacement planning. Do not expand it with new product semantics. Nvim/pinvim now lives in `pinvim.ts`; remaining use should move to focused ingress extensions (`hs.ts`, `tmux.ts`, `ntfy.ts`, tell/delegation owner) once `dot-3t42` identifies exact users and risks.
