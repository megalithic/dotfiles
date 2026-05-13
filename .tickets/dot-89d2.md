---
id: dot-89d2
status: open
deps: []
links: []
created: 2026-05-13T14:27:58Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [sentinel, extensions, refactor]
---
# sentinel: define typed rule tiers in code (replace JSON)

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:
1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

Convert JSON config to typed rule objects in TypeScript. Add RuleTier and Rule type definitions.

