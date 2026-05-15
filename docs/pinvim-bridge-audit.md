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

`pinvim.ts` is better place for nvim semantics because it can own:

- live editor context state
- `before_agent_start` context injection
- footer/status rendering
- peer metadata (`hello`, `hello_ack`, `heartbeat`)
- user-facing pinvim commands
- transport-independent behavior

This keeps transport concerns separate from product semantics.

## Recommended ownership split

### `pinvim.ts`

Primary pi-side nvim extension.

Owns:

- editor state in memory
- live context injection
- status/footer display
- peer handshake state
- migration path from legacy bus to future direct transport

### `bridge.ts`

Temporary transport shim.

Owns:

- socket lifecycle
- manifest writing
- request/response framing
- Telegram ingress
- tell ingress
- forwarding legacy `editor_state` / `editor_disconnect`

Should not own:

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
2. `dot-3t42`: inventory all `bridge.ts` users and plan focused replacements.

Target split:

- `pinvim.ts`: strictly pi↔nvim behavior, explicit send/queue/review/policy payloads.
- possible `hs.ts`: Hammerspoon↔pi ingress.
- possible `tmux.ts`: tmux helper/session discovery APIs.
- possible `ntfy.ts`: richer pi-side counterpart to `~/bin/ntfy`; Telegram only matters through current ntfy usage.
- tell/delegation owner: focused task delegation ingress instead of shared bridge monolith.
- shared utility only if needed: socket/manifest helpers without product semantics.

Research must enumerate every current bridge consumer before removal: nvim/pinvim, Hammerspoon, Telegram/ntfy, tell/skills, tmux-toggle-pi, ftm, manifests/session discovery, and any additional socket clients found by code search.

## Deprecation paths for `bridge.ts`

### Path A — keep bridge, narrow scope

Keep `bridge.ts`, but only as transport shim.

Good if:

- Telegram and tell still need same socket entrypoint
- Hammerspoon still depends on current socket contract
- nvim transport still wants same Unix socket

### Path B — deprecate bridge for nvim only

Move nvim transport elsewhere, keep `bridge.ts` only for Telegram/tell.

Good if:

- pinvim gets direct transport separate from chat ingress
- nvim protocol evolves faster than Telegram/tell protocol

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
- keep `bridge.ts` transport-only for now
- leave final `bridge.ts` deprecation decision for later, after transport direction is clearer

## Updated decision

Deprecate `bridge.ts` after inventory and replacement planning. Do not expand it with new product semantics. Any current use should either move to `pinvim.ts` (nvim only) or to a focused ingress extension (`hs.ts`, `tmux.ts`, `ntfy.ts`, tell/delegation owner) once `dot-3t42` identifies exact users and risks.
