---
id: dot-wl77
status: closed
deps: [dot-0kut]
links: []
created: 2026-04-15T16:35:56Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-42gl
tags: [ready-for-development]
---
# Phase 2: Deduplicate GLOBAL and repo AGENTS.md

Remove sections that appear word-for-word in both GLOBAL_AGENTS.md and repo AGENTS.md.
Keep each section in exactly one place.

Duplicated sections to resolve:
- Uncommitted changes (~35 lines) → keep in GLOBAL (universal rule), remove from repo
- Push/deploy/SSH restrictions (~30 lines) → keep in GLOBAL (universal), remove from repo
- Guardrail override protocol (~35 lines) → slim to brief mention in GLOBAL, remove from repo (sentinel extension is source of truth)
- Nix/dotfiles relationship (~50 lines) → keep in repo AGENTS.md (system-specific), remove from GLOBAL
- VCS aliases + interactive commands (~50 lines) → keep jj aliases in repo AGENTS.md (repo-specific aliases), keep interactive commands table in GLOBAL

Files to edit:
- home/common/programs/ai/pi-coding-agent/sources/GLOBAL_AGENTS.md
- AGENTS.md (repo root)

## Acceptance Criteria

1. rg across both files shows no duplicated sections (same content in both)
2. Uncommitted changes rules in GLOBAL only
3. Push/deploy/SSH rules in GLOBAL only
4. Guardrail protocol slimmed in GLOBAL, removed from repo
5. Nix/dotfiles relationship in repo AGENTS.md only
6. jj aliases in repo AGENTS.md only
7. Interactive commands table in GLOBAL only
8. just validate passes

