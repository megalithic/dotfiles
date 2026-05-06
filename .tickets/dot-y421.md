---
id: dot-y421
status: closed
deps: [dot-ji0m]
links: [dot-9i38]
created: 2026-05-06T13:05:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# pi-wrapper migration: pi-mcp-adapter → fetchFromGitHub + buildNpmPackage (v2.5.4) + rewrite claude-settings patch

Step 5 of pi-wrapper-fetchfromgithub-extensions plan.

Replace pi-mcp-adapter wrapper with fetchFromGitHub + buildNpmPackage. Pin to v2.5.4 (latest release tag, 2026-05-05). Upstream removed package-lock.json at v2.5.4 — buildNpmPackage generates one from package.json (works; hash captures full transitive closure). Install phase cp -r . $out/ per otahontas pattern. Delete packages/pi-mcp-adapter/ wrapper. Remove from PNAME_MAP.

Patch — REWRITE for v2.5.4 (do not just re-enable old patch):
- Old claude-settings-support.patch was authored against v2.4.1 config.ts and will NOT apply.
- v2.5.4 restructured config.ts: IMPORT_PATHS changed from Record<ImportKind,string> to Record<ImportKind,string[]> (already includes ~/.claude.json — old path-fix portion is now upstream). Import line changed (dirname removed, getAgentPath added). New types/constants added (ConfigSourceSpec, GENERIC_GLOBAL_CONFIG_PATH, etc.).
- Custom features still ABSENT in v2.5.4 and still needed: (1) loading mcpServers from Claude Code settings.json/settings.local.json, (2) loading mcpServers from project-specific .claude-* directories, (3) readdirSync import.
- Procedure: clone v2.5.4 tag, manually port CLAUDE_USER_PATHS + findClaudeProjectDirs + extractMcpServers + loading blocks into v2.5.4's ConfigSourceSpec architecture, then git diff > patches/claude-settings-support.patch.

Files:
- home/common/programs/pi-coding-agent/default.nix — replace pi-mcp-adapter block, reference rewritten patch
- home/common/programs/pi-coding-agent/patches/claude-settings-support.patch — rewrite for v2.5.4
- home/common/programs/pi-coding-agent/packages/pi-mcp-adapter/ — delete directory
- home/common/programs/pi-coding-agent/scripts/update-npm-pkg.sh — remove from PNAME_MAP

New nix block:
pi-mcp-adapter = pkgs.buildNpmPackage {
  pname = "pi-mcp-adapter"; version = "2.5.4";
  src = pkgs.fetchFromGitHub { owner = "nicobailon"; repo = "pi-mcp-adapter"; rev = "v2.5.4"; hash = "sha256-…"; };
  npmDepsHash = "sha256-…"; dontNpmBuild = true;
  patches = [./patches/claude-settings-support.patch];
  installPhase = ''runHook preInstall; mkdir -p $out; cp -r . $out/; runHook postInstall'';
};

## Acceptance Criteria

1. default.nix pi-mcp-adapter derivation uses buildNpmPackage + fetchFromGitHub at rev v2.5.4 with real src hash and real npmDepsHash
2. patches/claude-settings-support.patch rewritten against v2.5.4 (applies cleanly during nix build, no patch-apply errors)
3. Patch preserves: CLAUDE_USER_PATHS, findClaudeProjectDirs, extractMcpServers, settings.json/settings.local.json loading, .claude-* project dir loading, readdirSync import
4. packages/pi-mcp-adapter/ directory removed
5. update-npm-pkg.sh PNAME_MAP no longer references pi-mcp-adapter
6. just validate home passes
7. After just home, pi-mcp-adapter loads MCP servers from a Claude Code settings.json present in test project

