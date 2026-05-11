---
id: dot-kzpl
status: closed
deps: [dot-hgnt, dot-xhzj, dot-vrjs]
links: []
parent: dot-0fjk
created: 2026-05-11T17:39:25Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Remove legacy profile artifacts: ~/.pi/agent-rx, agent-evirts, agent-cspire

From plan: `~/.local/share/pi/plans/.dotfiles/profile-scoped-pi-models_PLAN.md` (Phase 6)

After phases 1-5 verified, remove:
- profiles/hybrid logic from pinvim
- profile multi-pass.json symlinks
- `~/.pi/agent-rx`, `~/.pi/agent-evirts`, `~/.pi/agent-cspire`
- Migrate any remaining auth into global `~/.pi/agent/auth.json`
- Optionally trash stale profile dirs after backup

## Acceptance Criteria
1. ~~`~/.pi/agent-rx` removed (after backup/verification)~~ dropped — dirs stay until user manually cleans up
2. ~~`~/.pi/agent-evirts` removed~~ dropped
3. ~~`~/.pi/agent-cspire` removed if exists~~ dropped
4. All auth migrated to global `~/.pi/agent/auth.json` ✅
5. No pinvim code references profile-specific agent dirs ✅
6. No `/tmp/pi-config-*` artifacts remain ✅
7. `p` in both rx and mega tmux sessions works correctly with single agent dir ✅
8. Session data copied from profile dirs to global ✅

## Notes

**2026-05-11T19:26:46Z**

Copied rx session data to global: 2 dotfiles + 118 strive-rx sessions. No filename collisions. Profile dirs left in place — user has active rx session. Remaining: trash dirs when user confirms ready.
