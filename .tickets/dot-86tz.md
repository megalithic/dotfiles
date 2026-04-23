---
id: dot-86tz
status: open
deps: []
links: []
parent: dot-0fjk
created: 2026-04-14T18:13:31Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Support project-level MCP config via .pi/mcp.json

pi-mcp-adapter already supports project-level .pi/mcp.json (in cwd) that overrides global ~/.pi/agent/mcp.json. But we don't use this yet.

Current state:
- Global mcp.json in ~/.pi/agent/mcp.json has tidewave + paper + context7
- tidewave is rx-specific, paper is canonize-specific
- Neither works reliably because they're global but the servers are project-local

Otahontas pattern (devenv-base ai module):
- Base mcp.json with global servers (context7)
- devenv-base.ai.mcp.extraServers nix option for per-project additions
- enter-shell.sh symlinks merged mcp.json to .pi/mcp.json in project root
- pi-mcp-adapter auto-discovers project .pi/mcp.json in cwd

Implementation:
1. Move tidewave out of global mcp.json into rx repo .pi/mcp.json
2. Move paper out of global mcp.json into canonize repo .pi/mcp.json
3. Keep only truly global servers (context7) in ~/.pi/agent/mcp.json
4. For devenv repos: add .pi/mcp.json generation to devenv.nix or .envrc
5. For flake repos: add .pi/mcp.json to repo directly

See: pi-mcp-adapter config.ts (DEFAULT_CONFIG_PATH, PROJECT_CONFIG_NAME)
See: home/common/programs/ai/pi-coding-agent/mcp.json

## Acceptance Criteria

1. Global mcp.json only contains truly global MCP servers (context7)
2. rx repo has .pi/mcp.json with tidewave server config
3. canonize repo has .pi/mcp.json with paper server config
4. Running /mcp in rx pi session shows tidewave connected (when Phoenix running)
5. Running /mcp in mega pi session does NOT show tidewave
6. Existing global MCP servers still work in all sessions

