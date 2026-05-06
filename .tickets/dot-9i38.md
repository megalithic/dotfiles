---
id: dot-9i38
status: open
deps: []
links: [dot-y421]
created: 2026-05-06T14:08:27Z
type: task
priority: 3
assignee: Seth Messer
tags: [pi-wrapper, patch-rewrite]
---
# Rewrite claude-settings-support.patch for pi-mcp-adapter v2.5.4 ConfigSourceSpec architecture

The claude-settings-support.patch was disabled in default.nix since v2.4.1 ("TODO: patch needs path adjustment for npm package layout") and never re-enabled. v2.5.4 restructured config.ts further:

- IMPORT_PATHS changed from Record<ImportKind, string> to Record<ImportKind, string[]> (already includes ~/.claude.json)
- Import line changed (dirname removed, getAgentPath added)
- New types/constants: ConfigSourceSpec, GENERIC_GLOBAL_CONFIG_PATH

Custom features still ABSENT in v2.5.4 and need rewrite:
1. Loading mcpServers from ~/.claude/settings.json + settings.local.json (settings.json files have different schema vs IMPORT_PATHS targets)
2. Loading mcpServers from project-specific .claude-* directories (e.g., .claude-rx, .claude-cspire)
3. extractMcpServers helper for nested mcpServers extraction
4. readdirSync import

Procedure:
1. Clone v2.5.4 tag locally
2. Port CLAUDE_USER_PATHS, findClaudeProjectDirs, extractMcpServers into v2.5.4's ConfigSourceSpec architecture
3. Update both loadMcpConfig and the provenance-tracking code path
4. Generate patch via git diff > home/common/programs/pi-coding-agent/patches/claude-settings-support.patch
5. Re-enable patches = [./patches/claude-settings-support.patch] in default.nix pi-mcp-adapter block

Acceptance: patch applies cleanly during nix build, claude settings.json + .claude-* dir loading works at runtime.

