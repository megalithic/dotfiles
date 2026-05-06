---
id: dot-xtug
status: open
deps: [dot-turd]
links: []
created: 2026-05-06T13:05:05Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: pi-multi-pass → fetchFromGitHub + stdenvNoCC (v1.3.0)

Step 2 of pi-wrapper-fetchfromgithub-extensions plan.

Replace pi-multi-pass build with fetchFromGitHub + stdenvNoCC.mkDerivation. Zero npm deps — buildNpmPackage is unnecessary overhead. Pin rev = v1.3.0 (only release on GitHub, also latest).

Keep the substituteInPlace fix for the upstream extensions-path bug ("./extensions" → "./extensions/multi-sub.ts"). Verified bug still present in v1.3.0.

Delete entire packages/pi-multi-pass/ wrapper directory. Remove pi-multi-pass from PNAME_MAP in scripts/update-npm-pkg.sh.

Files:
- home/common/programs/pi-coding-agent/default.nix — replace pi-multi-pass block
- home/common/programs/pi-coding-agent/packages/pi-multi-pass/ — delete directory
- home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh — remove from PNAME_MAP

New nix block (fill hash from build error):
pi-multi-pass = pkgs.stdenvNoCC.mkDerivation {
  pname = "pi-multi-pass"; version = "1.3.0";
  src = pkgs.fetchFromGitHub { owner = "hjanuschka"; repo = "pi-multi-pass"; rev = "v1.3.0"; hash = "sha256-…"; };
  installPhase = ''
    runHook preInstall; mkdir -p $out; cp -r $src/* $out/
    substituteInPlace "$out/package.json" --replace-fail '"./extensions"' '"./extensions/multi-sub.ts"'
    runHook postInstall
  '';
};

## Acceptance Criteria

1. default.nix pi-multi-pass derivation uses stdenvNoCC + fetchFromGitHub at rev v1.3.0 with real hash
2. substituteInPlace for extensions path bug retained in installPhase
3. packages/pi-multi-pass/ directory removed
4. update-npm-pkg.sh PNAME_MAP no longer references pi-multi-pass
5. just validate home passes
6. After just home, multi-pass extension still loads in pi (entry path resolves to extensions/multi-sub.ts)

