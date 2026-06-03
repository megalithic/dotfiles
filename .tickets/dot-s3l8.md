---
id: dot-s3l8
status: closed
deps: [dot-l8f0]
links: []
created: 2026-05-14T11:57:20Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# Remove temporary nvim↔pi protocol compatibility shims

Implement post-rollout cleanup for the staged nvim↔pi protocol migration after the immediate `live_context`/`editor_state` removal and bridge deprecation research land. After handshake, ranked discovery, MRU restore, structured envelope, review bundle, and policy tickets are complete, remove remaining rollout-only compatibility code between `config/nvim/lua/pinvim.lua`, `home/common/programs/pi-coding-agent/extensions/pinvim.ts`, and any temporary `bridge.ts` forwarding kept only for migration. Audit temporary legacy upgrade paths for pre-`hello`/`hello_ack` metadata, ad-hoc pre-envelope payloads, and dual-schema peer state.

Scope: remove nvim↔pi migration shims only. Do not break still-supported non-nvim clients such as Hammerspoon, Telegram, tell, or explicit prompt senders unless they are migrated in the same change.

## Acceptance Criteria

1. Rollout-only upgrade/fallback paths for legacy nvim peer-handshake or pre-envelope context payloads are removed from `pinvim.lua`, `pinvim.ts`, and any temporary `bridge.ts` forwarding once canonical `hello`/`hello_ack` and structured envelopes are in place.
2. Any shimmed bridge handling rejects unsupported legacy nvim protocol payloads gracefully with a clear response or log path instead of silently upgrading them.
3. Temporary dual-schema peer metadata state added for rollout is removed, and in-file docs/comments describe canonical `pinvim.lua` ↔ `pinvim.ts` ownership only.
4. `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and `bin/pinvim-protocol-smoke` all pass after cleanup.
5. Manual smoke test confirms explicit send, compose/queue, and review-bundle flows still work with only canonical primary protocol enabled.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

## Notes

**2026-06-03T19:40:18Z**

Deprecated: superseded by pinvim rewrite plan at ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md. Closing for posterity; architecture is being rebooted.
