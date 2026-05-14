---
id: dot-s3l8
status: open
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

Implement post-rollout cleanup for the staged nvim↔pi protocol migration. After the handshake, ranked discovery, MRU restore, structured envelope, review bundle, and policy tickets are complete, remove rollout-only compatibility code between config/nvim/after/plugin/pi.lua, home/common/programs/pi-coding-agent/extensions/bridge.ts, and home/common/programs/pi-coding-agent/extensions/pinvim.ts. Audit temporary legacy upgrade paths for pre-`hello`/`hello_ack` metadata, ad-hoc pre-envelope editor payloads, and dual-schema peer state.

Scope: remove nvim↔pi migration shims only. Do not break still-supported non-nvim clients such as explicit prompt senders unless they are migrated in the same change.

## Acceptance Criteria

1. Rollout-only upgrade/fallback paths for legacy nvim peer-handshake or editor-context payloads are removed from pi.lua, bridge.ts, and pinvim.ts once canonical `hello`/`hello_ack` and structured envelopes are in place.
2. Bridge rejects unsupported legacy nvim protocol payloads gracefully with a clear response or log path instead of silently upgrading them.
3. Temporary dual-schema peer metadata state added for rollout is removed, and in-file docs/comments describe the canonical protocol only.
4. `nvim --headless "+lua print('nvim ok')" +qa` and `just validate home` both pass after cleanup.
5. Manual smoke test confirms live sync, explicit send, and review bundle flows still work with only the canonical protocol enabled.

