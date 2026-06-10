---
id: dot-uhnq
status: closed
deps: []
links: []
created: 2026-05-13T14:28:04Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [web-browser, extensions, browser-mgmt]
---

# feat(web-browser): implement start.js with Helium + profile copying

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

Launch browser (Helium or Chrome) with remote debugging, manage profile cache, copy Brave Nightly profile

## Notes

**2026-05-15T18:34:51Z**

Adapted upstream start.js: WEB_BROWSER_PATH + WEB_BROWSER_PROFILE env vars, defaults Helium → Brave Nightly → Chrome, isolated cache at ~/.cache/agent-web/browser/, state.json includes binary path, conditional watch.js spawn.
