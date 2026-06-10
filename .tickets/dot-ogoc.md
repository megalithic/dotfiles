---
id: dot-ogoc
status: closed
deps: []
links: []
created: 2026-05-13T14:28:04Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [web-browser, extensions, utility]
---

# feat(web-browser): add cookie, logging, network analysis scripts

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

Cookie dismissal, background logging, network summary

## Notes

**2026-05-15T18:38:55Z**

Copied auxiliary scripts from upstream: dismiss-cookies.js, watch.js (background log watcher), logs-tail.js, net-summary.js, pick.js (element picker). All 13 .js scripts now in place; runtime still needs ws install (deferred to 3.7).
