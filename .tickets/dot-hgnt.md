---
id: dot-hgnt
status: open
deps: [dot-vr9x, dot-3bt7]
links: []
parent: dot-0fjk
created: 2026-05-11T17:39:22Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Simplify pinvim: remove profile-borrowing and /tmp/pi-config-* creation

From plan: `~/.local/share/pi/plans/.dotfiles/profile-scoped-pi-models_PLAN.md` (Phase 3)

New `pinvim` should:
1. Load agenix env
2. Clear conflicting AWS env
3. Map Brave env vars
4. Detect profile: explicit `--profile` > tmux session name > default `mega`
5. Export: `PI_SESSION`, `PI_PROFILE`, `PI_MULTI_PASS_PRESET`, `PI_MODEL_SCOPE`, socket env vars
6. Execute `pi` with normal global `~/.pi/agent`

Must NOT:
- Set `PI_CODING_AGENT_DIR`
- Create `/tmp/pi-config-*`
- Read `~/.pi/agent-*`

## Acceptance Criteria
1. pinvim no longer sets `PI_CODING_AGENT_DIR`
2. No `/tmp/pi-config-*` dirs created on launch
3. Exports `PI_PROFILE`, `PI_MULTI_PASS_PRESET`, `PI_MODEL_SCOPE`
4. Profile detection: `--profile` flag > tmux session > default `mega`
5. Works in both rx and mega tmux sessions
6. `just validate` passes
