---
id: dot-9lr2
status: closed
deps: []
links: []
created: 2026-04-17T17:18:38Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Add auto-version support to update-npm script

The update-npm-pkg.sh script currently requires manually editing package.json before running. It should support two new workflows:

1. `just update-npm pi 0.67.6` — update package.json to specified version, then regenerate lockfile + nix hash
2. `just update-npm pi` (no version) — fetch latest version from npm registry, update package.json, then regenerate lockfile + nix hash

Currently $2 (version arg) is silently ignored by the script.

Relevant files:
- home/common/programs/ai/pi-coding-agent/scripts/update-npm-pkg.sh
- justfile (update-npm recipe)

## Acceptance Criteria

1. `just update-npm pi 0.67.6` updates package.json version to 0.67.6 and regenerates lockfile + hash
2. `just update-npm pi` with no version queries npm registry for latest, updates package.json, regenerates lockfile + hash
3. `just update-npm` (no args, all packages) still works — uses current versions in package.json
4. Script prints which version it resolved/set before proceeding
5. Existing hash-update and lockfile-generation logic unchanged
6. `just update-npm pi 0.67.6` successfully updates the pi package end-to-end (package.json → lockfile → nix hash → `just home` builds)
7. Script accepts both directory name and npm package name — e.g., `just update-npm pi` and `just update-npm pi-coding-agent` both resolve to the `pi` package directory

