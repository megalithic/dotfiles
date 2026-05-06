---
id: dot-6q75
status: open
deps: [dot-xtug, dot-lgky, dot-ji0m, dot-y421]
links: []
created: 2026-05-06T13:06:10Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: extend update-npm-pkg.sh with fetchFromGitHub + fetchurl dispatch

Step 6 of pi-wrapper-fetchfromgithub-extensions plan.

Add three update functions to scripts/update-npm-pkg.sh, modeled on otahontas's update-manual-packages.sh:

1. update_github_npm_package() — for GitHub packages with npm deps (pi-mcp-adapter). Uses gh api repos/.../releases/latest for tag, nix-prefetch-url for src hash, nix build with fake hash for npmDepsHash.
2. update_github_no_deps_package() — for GitHub packages without npm deps (pi-multi-pass). Uses gh api releases/latest + nix-prefetch-url for src hash only. No npmDepsHash.
3. update_fetchurl_package() — for npm tarball packages without deps (pi-synthetic-provider). Uses npm view for latest version, nix-prefetch-url for tarball hash. No npmDepsHash.

Add a GITHUB_PKG_MAP associative array mapping package name → update-type + GitHub owner/repo. Update main dispatch logic to route to the right function based on package name.

Keep pi-internet as manual-only (no release tags). Document in script comments.

Verify deleted wrapper packages (pi-multi-pass, pi-synthetic-provider, pi-internet, pi-mcp-adapter) are removed from PNAME_MAP (already done in steps 2-5; confirm).

Files:
- home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh — add 3 functions + GITHUB_PKG_MAP + dispatch

Depends on steps 2-5 (those packages must already be migrated).

## Acceptance Criteria

1. update-npm-pkg.sh defines update_github_npm_package, update_github_no_deps_package, update_fetchurl_package functions
2. GITHUB_PKG_MAP associative array maps pi-mcp-adapter, pi-multi-pass, pi-synthetic-provider to their update types and (for github ones) owner/repo
3. Main dispatch routes pi-mcp-adapter through update_github_npm_package, pi-multi-pass through update_github_no_deps_package, pi-synthetic-provider through update_fetchurl_package
4. just update-npm pi still works (existing pi-coding-agent wrapper path unchanged)
5. just update-npm pi-mcp-adapter exits 0 and updates rev/src-hash/npmDepsHash in default.nix (or reports already-latest)
6. just update-npm pi-multi-pass exits 0 and updates rev/hash (or reports already-latest)
7. just update-npm pi-synthetic-provider exits 0 and updates url/hash (or reports already-latest)
8. just update-npm (no arg) iterates over all manageable packages without errors and skips pi-internet with a clear 'manual-only' note

