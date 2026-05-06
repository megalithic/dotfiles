---
id: dot-lgky
status: open
deps: [dot-xtug]
links: []
created: 2026-05-06T13:05:19Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: pi-synthetic-provider → fetchurl + stdenvNoCC (v1.1.12), drop obsolete patch

Step 3 of pi-wrapper-fetchfromgithub-extensions plan.

Replace pi-synthetic-provider build with fetchurl (npm registry tarball) + stdenvNoCC.mkDerivation. No runtime deps. Pin version = 1.1.12 (latest on npm).

Drop the synthetic-fallback-glm-5.1.patch entirely — it is obsolete. npm v1.1.12 already includes GLM-5.1, Kimi-K2.6, and NVIDIA Nemotron in the fallback model list (verified).

Delete packages/pi-synthetic-provider/ wrapper directory (also eliminates ^1.1.10 caret bug). Delete patches/synthetic-fallback-glm-5.1.patch. Remove pi-synthetic-provider from PNAME_MAP.

Files:
- home/common/programs/pi-coding-agent/default.nix — replace block, remove patch reference
- home/common/programs/pi-coding-agent/packages/pi-synthetic-provider/ — delete directory
- home/common/programs/pi-coding-agent/patches/synthetic-fallback-glm-5.1.patch — delete
- home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh — remove from PNAME_MAP

New nix block:
pi-synthetic-provider = pkgs.stdenvNoCC.mkDerivation {
  pname = "pi-synthetic-provider"; version = "1.1.12";
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@benvargas/pi-synthetic-provider/-/pi-synthetic-provider-1.1.12.tgz";
    hash = "sha256-…";
  };
  installPhase = ''runHook preInstall; mkdir -p $out; cp -r $src/* $out/; runHook postInstall'';
};

Note: stdenvNoCC + fetchurl on .tgz uses the default unpackPhase. Ensure dontUnpack is NOT set. If extraction fails, add nativeBuildInputs = [pkgs.gnutar pkgs.gzip].

## Acceptance Criteria

1. default.nix pi-synthetic-provider derivation uses stdenvNoCC + fetchurl pinned to v1.1.12 with real hash
2. patches reference for synthetic-fallback-glm-5.1.patch removed from default.nix
3. patches/synthetic-fallback-glm-5.1.patch file deleted
4. packages/pi-synthetic-provider/ directory removed
5. update-npm-pkg.sh PNAME_MAP no longer references pi-synthetic-provider
6. just validate home passes
7. After just home, synthetic-provider extension loads and exposes GLM-5.1 in fallback model list

