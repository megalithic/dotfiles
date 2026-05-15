---
id: dot-ol82
status: closed
deps: []
links: []
created: 2026-05-13T14:28:05Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [web-browser, extensions, config]
---
# feat(web-browser): add Helium + Brave Nightly profile env vars

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:
1. Simple extensions/skills: Auto-load (no build step).
2. npm-dependent extensions: Use Nix `buildNpmPackage` patterns (A, B, C, D).
3. Need ad-hoc tools? Use `nix run nixpkgs#nodejs -- npm install` or `nix shell nixpkgs#pnpm`.

Document and test WEB_BROWSER_PATH, WEB_BROWSER_PROFILE, BRAVE_PROFILE_PATH env vars


## Notes

**2026-05-15T18:42:26Z**

Added WEB_BROWSER_PATH (Helium binary) + WEB_BROWSER_PROFILE (Brave Nightly profile dir) to home.sessionVariables in pi-coding-agent/default.nix. Documented full env-var contract in SKILL.md. Verified: vars exported in hm-session-vars.{sh,fish}, both Helium binary + Brave Nightly profile dir resolve on disk. Initiative 3 (web-browser rewrite) complete.
