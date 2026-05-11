---
id: dot-xhzj
status: open
deps: [dot-vr9x]
links: []
parent: dot-0fjk
created: 2026-05-11T17:39:23Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Auto-activate multi-pass preset from PI_MULTI_PASS_PRESET env var

From plan: `~/.local/share/pi/plans/.dotfiles/profile-scoped-pi-models_PLAN.md` (Phase 4)

Patch/extend `multi-sub.ts`:
- On session start, read `PI_MULTI_PASS_PRESET`
- If set and preset exists, activate it automatically
- Status shows `preset:rx` / `preset:mega`
- No manual `/mp-preset` command needed after launch

Equivalent to running `/mp-preset rx` but automatic.

## Acceptance Criteria
1. `PI_MULTI_PASS_PRESET=rx` → pi starts with rx preset active
2. `PI_MULTI_PASS_PRESET=mega` → pi starts with mega preset active
3. Multi-pass status shows correct preset on launch
4. Unset var falls back to default behavior
5. No manual `/mp-preset` needed after launch
