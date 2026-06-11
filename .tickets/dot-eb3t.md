---
id: dot-eb3t
status: closed
deps: 4:1:deps: [, dot-tniw]
links: []
created: 2026-06-11T11:38:03Z
type: chore
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Document strict pinvim pairing in lat.md

Update durable architecture docs after implementation. File hints: lat.md/programs/neovim-pinvim.md. Replace broad bidirectional repair wording with strict pair ownership, pairId, automatic resolution rules, Pi claim rules, pimux pair-aware reuse, :PiTarget ownership neutrality, and shade-next fill_prompt no-claim/no-submit semantics.

## Acceptance Criteria

1. lat.md/programs/neovim-pinvim.md matches implemented strict pairing behavior
2. Documentation names config/nvim/lua/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts, and bin/pimux where relevant
3. Manifest discovery is documented as diagnostic/manual only for normal flows
4. lat_check passes
