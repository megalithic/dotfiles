---
id: dot-6d1d
status: in_progress
deps: []
links: []
created: 2026-09-15T20:51:28Z
type: feature
priority: 2
assignee: Seth Messer
---
# Tidewave->pi toolbar routing: bridge.ts fixes + tidewaveConnected gate field

Foundational work for routing Tidewave toolbar prompts into the active worktree pi. From code review of bridge.ts + hammerspoon pi.lua:
- PERF: detectTmux() spawns 5 execSync tmux calls; runs at startup (resolveSocket) AND every heartbeat (HEARTBEAT_MS=10s). Batch into a single tmux display-message call.
- DEAD CODE: _getModelShortName (bridge.ts) unused + stale hardcoded model names. Remove.
- NEW FIELD: tidewaveConnected in the pi manifest. Gate proven = selectedTools.includes('mcp__tidewave') captured in before_agent_start (live-connection signal, not config-presence). Cache to manifest; refresh on heartbeat.
- Also: worktree-for-port.sh (inverse of phx-port.sh): port -> {pid,root,worktree,session,pgport} JSON, mise elixir template.

Coordinate with dot-gew8 (edits same bridge.ts socket/manifest layer).

## Acceptance Criteria

1. detectTmux() uses a single tmux subprocess call. 2. _getModelShortName removed. 3. manifest includes tidewaveConnected boolean, set from selectedTools mcp__tidewave presence, refreshed on heartbeat. 4. worktree-for-port.sh emits correct JSON for a running worktree. 5. bridge.ts still passes its _test surface / no regressions in socket lifecycle.

