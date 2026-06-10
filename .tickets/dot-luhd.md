---
id: dot-luhd
status: closed
deps: []
links: []
created: 2026-05-13T14:28:04Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [web-browser, extensions, cdp]
---

# feat(web-browser): implement navigation, eval, screenshot scripts

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

Core CDP scripts for navigation, JS eval, screenshots

## Notes

**2026-05-15T18:36:56Z**

Copied cdp.js, nav.js, eval.js, screenshot.js from upstream mitsuhiko/agent-stuff verbatim. Added local stub modules (emulation-state.js, devices.js) so imports resolve — real impls land in dot-ezbp (3.4). Runtime requires 'ws' npm module; node_modules wiring deferred (nix-store skill dir is read-only — needs buildNpmPackage or runtime cache install, likely in 3.7).
