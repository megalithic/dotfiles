---
id: dot-vrjs
status: closed
deps: [dot-3bt7]
links: []
parent: dot-0fjk
created: 2026-05-11T17:39:24Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Apply model scope at startup: research pi hook + patch for PI_MODEL_SCOPE

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

From plan: `~/.local/share/pi/plans/.dotfiles/profile-scoped-pi-models_PLAN.md` (Phase 5)

Need small research/patch step to find best hook:

- Preferred: pi core reads `PI_MODEL_SCOPE`, loads `enabledModelScopes[scope]`, uses it instead of `enabledModels` before scoped model selector initializes
- Alternative: extension API to set session-only enabled model IDs after providers register
- Fallback: local pi patch in nix package around `settings.enabledModels` resolution

Critical ordering: multi-pass must register `rx-anthropic` before `enabledModelScopes.rx` is validated, or rx scope will warn "No models match pattern".

## Acceptance Criteria

1. Research which hook/approach works (core, extension API, or local patch)
2. Implement chosen approach
3. `PI_MODEL_SCOPE=rx` → Ctrl-P shows only rx-anthropic models
4. `PI_MODEL_SCOPE=mega` → Ctrl-P shows all mega-scoped models
5. No "No models match pattern" warnings when provider registration precedes scope validation
6. Document approach and any upstream patches needed

## Notes

**2026-05-11T18:57:40Z**

Implemented Approach 3: pinvim passes --models from enabledModelScopes[scope]. PI_MODEL_SCOPE env var overrides, AUTH_PROFILE auto-detection is default. No pi source patches. Uses existing --models CLI flag. Documented in AGENTS.md.
