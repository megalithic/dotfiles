---
id: dot-ks5d
status: open
deps: 4:1:deps: 4:1:deps: [, dot-k4o7, dot-0v6y]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Preserve explicit target and shade-next ownership neutrality

Keep escape hatches explicit while strict pairing is enforced. File hints: config/nvim/lua/pinvim.lua (:PiTarget, target_command, send paths) and home/common/programs/pi-coding-agent/extensions/pinvim.ts (fill_prompt handling, peer acceptance, lastHello/pair state).

## Acceptance Criteria

1. :PiTarget <socket> sends as a manual target without rewriting Nvim registry or Pi pair ownership
2. Live mismatched target sockets reject with a clear reason when strict rules require it
3. :PiTarget clear returns to the current Nvim own-pair path
4. shade-next fill_prompt fills prompt text without auto-submit
5. fill_prompt does not change lastHello, pairId, or claim state
6. Existing pinvim behavior still validates with devenv shell -- just validate home
