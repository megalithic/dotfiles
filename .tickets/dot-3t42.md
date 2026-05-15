---
id: dot-3t42
status: open
deps: [dot-klla]
links: []
created: 2026-05-15T14:57:12Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Research bridge.ts deprecation into focused ingress extensions

Inventory every current `bridge.ts` user and propose a migration path away from the monolithic bridge extension. Target architecture: `pinvim.ts` handles only pi↔nvim, possible `hs.ts` handles Hammerspoon↔pi, possible `tmux.ts` handles tmux helper/discovery APIs, possible `ntfy.ts` expands `~/bin/ntfy` integration, and tell/delegation ingress moves to a focused owner.

Relevant files:
- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/notify.ts`
- `home/common/programs/pi-coding-agent/skills/tell/scripts/tell.sh`
- `config/hammerspoon/lib/interop/pi.lua`
- `bin/ntfy`
- `bin/tmux-toggle-pi`
- `bin/ftm`
- `home/common/programs/pi-coding-agent/default.nix`
- `docs/pinvim-bridge-audit.md`

This is research/planning only. Do not delete `bridge.ts` in this ticket.

## Acceptance Criteria

1. `docs/pinvim-bridge-audit.md` or a successor doc lists every `bridge.ts` consumer found by code search: nvim/pinvim, Hammerspoon, Telegram/ntfy, tell/skills, `tmux-toggle-pi`, `ftm`, manifests/session discovery, and any additional users.
2. For each consumer, document current payloads, socket/manifest dependency, pi-coding-agent APIs used, replacement extension/module candidate, and migration risk.
3. Propose focused extension split: `pinvim.ts`, `hs.ts`, `tmux.ts`, `ntfy.ts`, tell/delegation owner, plus any shared socket/manifest utility if needed.
4. Identify which `bridge.ts` behavior can be removed immediately after `dot-klla` and which behavior must remain until replacement tickets land.
5. Create or update follow-up tickets for implementation if research finds clear migration slices.
6. Research-only verification: `rg` confirms documented consumers match code references; `tk dep cycle` has no cycles.
