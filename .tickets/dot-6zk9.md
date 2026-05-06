---
id: dot-6zk9
status: open
deps: []
links: []
created: 2026-05-06T18:57:52Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Fix chrome-cdp skill and tidewave MCP integration workarounds

During a session on the rx project, the chrome-cdp skill and tidewave MCP tool both failed to work out of the box and required manual workarounds.

**Chrome CDP issues:**
- `cdp.mjs list` fails with 'WebSocket error: error' because the DevToolsActivePort file at ~/Library/Application Support/BraveSoftware/Brave-Browser/DevToolsActivePort contains just '9222' and '/' — the script builds ws://127.0.0.1:9222/ which isn't a valid browser WS endpoint
- Workaround used: curl http://localhost:9222/json/list to discover tabs, then used raw Node.js WebSocket to connect to individual page WS URLs (ws://localhost:9222/devtools/page/<targetId>) for navigation
- The script needs a fallback: when the DevToolsActivePort path yields a bad WS URL, try the /json/version HTTP endpoint to get the real webSocketDebuggerUrl

**Tidewave MCP issues:**
- pi's MCP gateway prefixes tool names with 'tidewave_' (e.g. tidewave_project_eval) but the actual Tidewave MCP server exposes them without prefix (e.g. project_eval)
- The MCP gateway returns empty results silently when using prefixed names — no error
- Workaround used: curl directly to http://localhost:4000/tidewave/mcp with JSON-RPC payloads, calling tools/list to discover real names, then tools/call with the unprefixed name
- The MCP skill or AGENTS.md should document that Tidewave tools use unprefixed names via direct HTTP, or the mcpctl skill should handle the prefix mismatch

**Files to update:**
- home/common/programs/pi-coding-agent/skills/chrome-cdp/SKILL.md — add troubleshooting section and curl-based fallback instructions
- home/common/programs/pi-coding-agent/skills/chrome-cdp/scripts/cdp.mjs — add fallback to /json/version endpoint when DevToolsActivePort yields invalid WS URL
- home/common/programs/pi-coding-agent/skills/mcpctl/SKILL.md — document Tidewave direct HTTP workaround
- Consider adding a tidewave-specific skill or section to AGENTS.md for Elixir/Phoenix projects

## Acceptance Criteria

1. cdp.mjs list works when DevToolsActivePort has minimal content (port + '/') by falling back to /json/version HTTP endpoint
2. chrome-cdp SKILL.md documents the curl http://localhost:9222/json/list fallback for tab discovery
3. chrome-cdp SKILL.md documents raw Node.js WebSocket workaround for page navigation when cdp.mjs fails
4. Tidewave MCP direct HTTP usage is documented (curl to /tidewave/mcp with JSON-RPC, tools/list then tools/call with unprefixed names)

