---
id: dot-g91k
status: closed
deps: []
links: [dot-86tz]
created: 2026-04-15T14:29:27Z
type: feature
priority: 2
assignee: Seth Messer
---
# Add mcpctl skill for managing MCP server configs (global + project)

Skill for managing MCP server configurations — add, remove, list, inspect, and troubleshoot MCP servers across global and project scopes.

Reference: HazAT/pi-config add-mcp-server skill (https://github.com/HazAT/pi-config/blob/main/skills/add-mcp-server/SKILL.md)

Current state:
- Global mcp.json at ~/.pi/agent/mcp.json has all servers (context7, tidewave, paper)
- pi-mcp-adapter supports project-level .pi/mcp.json (auto-discovered in cwd, overrides global)
- pi-mcp-adapter supports imports feature: `{ "imports": ["vscode", "cursor", "claude-code"] }` merges from other tools' configs
- No skill exists to help pi manage MCP servers
- Related: dot-86tz (restructure global vs project config) — not a hard blocker, but mcpctl's "list" output is cleaner once global only has global servers. Can be done in either order.

Operations the skill should support:
- **Add**: determine scope + server type, gather config, merge into correct file, verify
- **Remove**: remove server from global or project config
- **List**: show all configured servers (global + project + imported), indicate which are connected
- **Inspect**: show server config, available tools, connection status
- **Troubleshoot**: verify endpoint reachable, check config syntax, test connection

Server types:
- stdio (command + args + env + cwd)
- HTTP (url + headers + auth + bearerToken/bearerTokenEnv)

Config options: lifecycle (lazy/eager/keep-alive), idleTimeout, debug

Adaptation needed from HazAT's version:
- Our global mcp.json is nix-managed (source: home/common/programs/ai/pi-coding-agent/mcp.json)
- Global changes need `just rebuild` — skill should edit nix source, not the symlinked file
- Project .pi/mcp.json is NOT nix-managed — can be written directly
- Document the imports feature for cross-tool compat (vscode, cursor, claude-code, codex, windsurf)
- Document pi-mcp-adapter load order: global → imports → project (project wins)

Key files:
- home/common/programs/ai/pi-coding-agent/mcp.json (global, nix-managed)
- home/common/programs/ai/pi-coding-agent/skills/ (skill destination)
- home/common/programs/ai/pi-coding-agent/default.nix (auto-discovers skills)

## Acceptance Criteria

1. mcpctl skill exists in skills/mcpctl/ directory
2. Skill supports add, remove, list, inspect, and troubleshoot operations
3. Skill handles global scope (edits nix source file, notes `just rebuild` required)
4. Skill handles project scope (writes .pi/mcp.json directly in project root)
5. Skill supports stdio servers (command + args + env)
6. Skill supports HTTP servers (url + headers + auth)
7. Skill includes verification step (reload + connect + list tools)
8. Skill documents pi-mcp-adapter load order and imports feature
9. Skill warns before overwriting existing server with same name
10. just validate passes after adding the skill


## Notes

**2026-04-15T17:57:57Z**

Created mcpctl skill at skills/mcpctl/SKILL.md. Covers all 5 operations (add/remove/list/inspect/troubleshoot), both scopes (global nix-managed + project direct), both server types (stdio/HTTP), imports feature, load order docs. Auto-discovered by nix. just validate home passes.
