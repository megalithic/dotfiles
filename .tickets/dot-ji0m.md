---
id: dot-ji0m
status: open
deps: [dot-lgky]
links: []
created: 2026-05-06T13:05:34Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: pi-internet → fetchFromGitHub + buildNpmPackage (commit-pinned)

Step 4 of pi-wrapper-fetchfromgithub-extensions plan.

Replace pi-internet wrapper with fetchFromGitHub + buildNpmPackage. Upstream has its own package-lock.json — wrapper unnecessary. Pin to commit hash b4f0230ceabe7a30ea08e814eba27a65e66707ec (latest main as of 2026-05-06; no release tags exist on JJGO/pi-internet). Hardcode version = "0.1.0".

Remove makeCacheWritable (not needed with fetchFromGitHub — upstream lockfile used directly). Install phase cp -r . $out/ per otahontas pattern.

Delete packages/pi-internet/ wrapper directory. Remove from PNAME_MAP. (pi-internet stays manual-only in update script — commit hash bumps require gh api repos/JJGO/pi-internet/commits/main.)

Files:
- home/common/programs/pi-coding-agent/default.nix — replace pi-internet block
- home/common/programs/pi-coding-agent/packages/pi-internet/ — delete directory
- home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh — remove from PNAME_MAP

New nix block (fill src + npmDepsHash from build errors):
pi-internet = pkgs.buildNpmPackage {
  pname = "pi-internet"; version = "0.1.0";
  src = pkgs.fetchFromGitHub { owner = "JJGO"; repo = "pi-internet"; rev = "b4f0230ceabe7a30ea08e814eba27a65e66707ec"; hash = "sha256-…"; };
  npmDepsHash = "sha256-…";
  dontNpmBuild = true;
  installPhase = ''runHook preInstall; mkdir -p $out; cp -r . $out/; runHook postInstall'';
};

Peer deps (pi-ai, pi-coding-agent, pi-tui, typebox) resolve via host pi installation — buildNpmPackage handles transitive npm deps via lockfile hash.

## Acceptance Criteria

1. default.nix pi-internet derivation uses buildNpmPackage + fetchFromGitHub pinned to commit b4f0230… with real src hash
2. npmDepsHash filled with real hash from upstream lockfile
3. makeCacheWritable removed
4. installPhase uses cp -r . $out/
5. packages/pi-internet/ directory removed
6. update-npm-pkg.sh PNAME_MAP no longer references pi-internet
7. just validate home passes
8. After just home, pi-internet extension loads in pi without missing-dependency errors

