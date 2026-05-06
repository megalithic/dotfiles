---
id: dot-0b8c
status: open
deps: [dot-6q75]
links: []
created: 2026-05-06T13:06:22Z
type: chore
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: update AGENT CONTEXT comments + AGENTS.md docs

Step 7 of pi-wrapper-fetchfromgithub-extensions plan.

Update AGENT CONTEXT header comments in default.nix and home/common/programs/pi-coding-agent/AGENTS.md to reflect the new package patterns.

Add documentation for:
- Pattern A: wrapper + buildNpmPackage (when upstream has no usable lockfile or npm-only)
- Pattern B: fetchFromGitHub + buildNpmPackage (when upstream has lockfile or accept generated one)
- Pattern C: fetchFromGitHub or fetchurl + stdenvNoCC (zero-deps packages)

Document the decision tree:
- No deps → fetchFromGitHub/fetchurl + stdenvNoCC
- Has deps + public repo with usable lockfile or accept generated → fetchFromGitHub + buildNpmPackage
- Has deps + private/no repo / npm-only → wrapper + buildNpmPackage

Reference new update-script functions (update_github_npm_package, update_github_no_deps_package, update_fetchurl_package) and GITHUB_PKG_MAP.

Document patch changes:
- synthetic-fallback-glm-5.1.patch DROPPED (obsolete — features now upstream)
- claude-settings-support.patch REWRITTEN for v2.5.4 (config.ts restructured)

Files:
- home/common/programs/pi-coding-agent/default.nix — AGENT CONTEXT header comments
- home/common/programs/pi-coding-agent/AGENTS.md — top-level docs

Depends on step 6 (script functions must exist before being documented).

## Acceptance Criteria

1. default.nix AGENT CONTEXT header comments cover all three patterns (A/B/C) with one-line decision tree
2. AGENTS.md has a section explaining when to use each of patterns A/B/C
3. AGENTS.md references the three new update-script functions and GITHUB_PKG_MAP by name
4. AGENTS.md notes that synthetic-fallback-glm-5.1.patch was dropped (obsolete) and claude-settings-support.patch was rewritten for v2.5.4
5. just validate home passes (docs-only changes do not break build)

