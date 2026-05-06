---
id: dot-turd
status: open
deps: []
links: []
created: 2026-05-06T13:04:52Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: standardize + bump pi-coding-agent wrapper to v0.73.0

Step 1 of pi-wrapper-fetchfromgithub-extensions plan (~/.local/share/pi/plans/.dotfiles/pi-wrapper-fetchfromgithub-extensions_PLAN.md).

Rewrite packages/pi/package.json to match the otahontas pi-wrapper convention AND bump to upstream v0.73.0.

New content (only these fields):
- name: "pi-wrapper"
- private: true
- version: "0.73.0"
- dependencies: { "@mariozechner/pi-coding-agent": "0.73.0" }

Remove existing fields: description, main, scripts, keywords, author, license, type.

Then regenerate lockfile and update nix hash:
- cd home/common/programs/pi-coding-agent/packages/pi && npm install --package-lock-only
- Update npmDepsHash in default.nix using fake-hash → build-error → real-hash workflow

Retry patches (inline substituteInPlace on agent-session.js maxRetries/baseDelayMs) still apply — verified upstream 0.73.0 has same code, no upstream maxDelayMs/429 handling.

Files:
- home/common/programs/pi-coding-agent/packages/pi/package.json
- home/common/programs/pi-coding-agent/packages/pi/package-lock.json
- home/common/programs/pi-coding-agent/default.nix (npmDepsHash for pi block)

## Acceptance Criteria

1. packages/pi/package.json contains only name (pi-wrapper), private:true, version 0.73.0, and dependencies entry — no description/main/scripts/keywords/author/license/type
2. packages/pi/package-lock.json regenerated and consistent with new package.json
3. default.nix npmDepsHash updated to real hash for pi pkg
4. just validate home passes
5. After just home, pi --version reports 0.73.0
6. Existing retry patches still apply cleanly (no patch-apply errors during build)

