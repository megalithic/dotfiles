---
id: dot-ji0m
status: open
deps: [dot-lgky]
links: [dot-easu]
created: 2026-05-06T13:05:34Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, blocked-upstream]
---
# pi-wrapper migration: pi-internet → fetchFromGitHub + buildNpmPackage (commit-pinned)

## Status: BLOCKED on upstream lockfile fix

Attempted migration 2026-05-06 (commit b4f0230). Upstream `package-lock.json` has malformed entries for two transitive peer deps that lack `resolved` + `integrity` fields:

- `node_modules/unpdf` (v1.4.0) — has optional peer dep `@napi-rs/canvas`, npm wrote bare entry
- `node_modules/zod-to-json-schema` (v3.25.2) — `peer: true` entry, only declares peer dep on zod

Result: `prefetch-npm-deps` skips them → `npm install` runs in `only-if-cached` mode → `ENOTCACHED`.

### Workarounds tested (all failed)

- `npmFlags = ["--legacy-peer-deps"]` — npm still tries to resolve
- `npmDepsFetcherVersion = 2` — same skip behavior
- `makeCacheWritable = true` — cache writable but npm still in offline mode
- `postPatch` w/ `jq` — `nativeBuildInputs` override breaks buildNpmPackage defaults
- `postPatch` w/ inline sed — escape hell broke nix syntax
- Generate fresh lockfile via `npm install --package-lock-only` — sentinel blocks npm install everywhere
- `patches = [./patches/pi-internet-lockfile-fix.patch]` adding resolved/integrity — patch applies, prefetch caches OK, but main drv install phase still failed (deeper ENOTCACHED on different pkg, not investigated)

### Forward path

1. **Best:** Ask JJGO to regenerate package-lock.json upstream (e.g. `rm package-lock.json && npm install --package-lock-only --include=peer`). One-line PR.
2. **Alt:** Fully diagnose remaining ENOTCACHED in install phase, extend lockfile patch to cover all malformed entries.
3. **Alt:** Hybrid — fetchFromGitHub for src, but commit a regenerated lockfile to `home/common/programs/pi-coding-agent/packages/pi-internet/package-lock.json` and override at build time. Goes against plan's "use upstream lockfile" pledge.

## Original spec


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


## Notes

**2026-05-06T14:01:07Z**

BLOCKED on upstream lockfile fix. Upstream package-lock.json (commit b4f0230) has malformed entries for unpdf@1.4.0 and zod-to-json-schema@3.25.2 — both lack resolved/integrity fields (peer dep edge cases). prefetch-npm-deps skips them → npm install fails ENOTCACHED. Tested workarounds: --legacy-peer-deps, npmDepsFetcherVersion=2, makeCacheWritable, postPatch jq/sed, lockfile patch — none fully working. Forward path: file PR at JJGO/pi-internet to regen lockfile. See ticket body for full details.
