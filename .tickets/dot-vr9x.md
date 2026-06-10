---
id: dot-vr9x
status: closed
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

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

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

## Notes

**2026-05-11T18:18:18Z**

Implemented: kept single global multi-pass.json with rx-anthropic and mega-codex subscriptions plus mega/rx presets; removed profile-specific multi-pass home.file entries and added activation cleanup for old nix-managed profile symlinks. Verified with jq/rg and just validate.

**2026-05-11T18:19:03Z**

Runtime auth consolidation: merged missing google-antigravity and google-gemini-cli entries from profile auth into global ~/.pi/agent/auth.json without overwriting existing global credentials. Backup created at ~/.pi/agent/auth.json.bak.20260511141857.

**2026-05-11T18:20:37Z**

Applied home-manager with 'just home --skip-sync'. Verified runtime profile multi-pass files are absent for ~/.pi/agent-rx, ~/.pi/agent-evirts, and ~/.pi/agent-cspire; global ~/.pi/agent/multi-pass.json remains linked.
