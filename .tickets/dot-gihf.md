---
id: dot-gihf
status: open
deps: []
links: []
created: 2026-05-11T15:15:00Z
type: bug
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Set Tidewave lifecycle to keep-alive in mcp.json

Tidewave's Bandit server times out when pi-mcp-adapter's default lazy lifecycle kills idle connections after 10 minutes. This causes Bandit.TransportError: timeout errors.

Add lifecycle: 'keep-alive' to the tidewave entry in mcp.json so the connection stays alive.

See home/common/programs/pi-coding-agent/mcp.json.

## Acceptance Criteria

1. mcp.json tidewave entry has lifecycle: 'keep-alive'
2. just home applies successfully
3. pi starts and /mcp shows tidewave as connected
4. No Bandit.TransportError: timeout errors after 10+ min idle

