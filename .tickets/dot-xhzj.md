---
id: dot-xhzj
status: closed
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

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

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

## Notes

**2026-05-11T18:28:55Z**

Implemented: multi-sub.ts now reads PI_MULTI_PASS_PRESET on session_start and activates matching enabled preset using shared preset activation logic. Status stays preset:<name> after activation; unset env keeps default status/model behavior. Verified PI_MULTI_PASS_PRESET=rx and =mega in tmux-started pi sessions, plus unset fallback; ran just validate and just home --skip-sync.
