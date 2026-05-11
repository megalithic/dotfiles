---
id: dot-kzpl
status: open
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
1. `~/.pi/agent-rx` removed (after backup/verification)
2. `~/.pi/agent-evirts` removed
3. `~/.pi/agent-cspire` removed if exists
4. All auth migrated to global `~/.pi/agent/auth.json`
5. No pinvim code references profile-specific agent dirs
6. No `/tmp/pi-config-*` artifacts remain
7. `p` in both rx and mega tmux sessions works correctly with single agent dir
