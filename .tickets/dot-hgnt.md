---
id: dot-hgnt
status: closed
deps: [dot-vr9x, dot-3bt7]
links: []
parent: dot-0fjk
created: 2026-05-11T17:39:22Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Simplify pinvim: remove profile-borrowing and /tmp/pi-config-\* creation

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

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

## Notes

**2026-05-11T19:01:40Z**

Removed: profile-borrowing (AUTO_PROFILE, AUTH_PROFILE, PI_CODING_AGENT_DIR), hybrid dirs (/tmp/pi-config-\*), sharedConfigItems. Added: PI_PROFILE + PI_MULTI_PASS_PRESET + PI_MODEL_SCOPE exports. Profile detection: --profile flag > tmux session name. Single exec path, no branching. Net -48/+10 lines.
