---
id: dot-vr9x
status: open
deps: []
links: []
parent: dot-0fjk
created: 2026-05-11T17:38:16Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Consolidate multi-pass config: merge all subscriptions/presets into one global multi-pass.json

From plan: `~/.local/share/pi/plans/.dotfiles/profile-scoped-pi-models_PLAN.md` (Phase 1)

Keep one `~/.pi/agent/multi-pass.json` with all subscriptions and presets:
- subscriptions: rx-anthropic, mega-codex, any future accounts
- presets: mega, rx, cspire if needed

Currently subscriptions may be split across profile dirs. Merge into single file. Preserve existing auth in global `~/.pi/agent/auth.json`.

## Acceptance Criteria
1. All subscriptions consolidated into single `~/.pi/agent/multi-pass.json`
2. Presets defined for mega, rx (and cspire if applicable)
3. Auth credentials all in global `~/.pi/agent/auth.json`
4. No profile-specific multi-pass.json files remain
5. `just validate` passes after nix changes

