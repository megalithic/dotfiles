---
id: dot-jgxe
status: closed
deps: []
links: []
created: 2026-05-13T14:28:04Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [web-browser, extensions, docs]
---
# docs(web-browser): rewrite skill documentation for script-based approach

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:
1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

Update SKILL.md for new script-based approach, document all commands


## Notes

**2026-05-15T18:40:22Z**

Replaced legacy 'browser connect 9222' docs with script-based skill: documents start.js lifecycle, browser/profile resolution order (Helium → Brave Nightly → Chrome), nav/eval/screenshot/emulate/pick/dismiss-cookies usage, log handling, and migration notes from old agent-browser CLI. Env vars partially documented; full env-var contract finalized in dot-ol82 (3.7).
