---
id: dot-3fyc
status: open
deps: []
links: []
created: 2026-04-14T19:46:04Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-kts9
tags: [ready-for-development]
---
# Enhance bridge.ts: bidirectional JSON-RPC, cwd discovery, new message types

Upgrade bridge.ts to be the unified socket owner with bidirectional communication.

## Changes

- Add JSON response writes back to socket clients (ok/error/pong)
- Add ping/pong message type handling
- Add prompt message type (raw prompt injection via pi.sendUserMessage)
- Add editor_state message type (forward to pinvim.ts via pi.events)
- Write carderne-style .info manifest in /tmp/pi-nvim-sockets/ for cwd-based
  discovery (alongside existing tmux-session socket pattern)
- Clean up .info manifest on session_shutdown

## Key files

- home/common/programs/ai/pi-coding-agent/extensions/bridge.ts

## Protocol additions

Responses (bridge.ts → client):
  { ok: true }
  { ok: true, type: 'pong' }
  { ok: false, error: '...' }

New request types:
  { type: 'ping' }
  { type: 'prompt', message: '...' }
  { type: 'editor_state', state: { file, cursor, selection, filetype, ... } }

Forward editor_state to pinvim.ts:
  pi.events.emit('pinvim:editor_state', state)

## Acceptance Criteria

1. bridge.ts writes JSON response back to socket on every message
2. bridge.ts handles { type: 'ping' } with { ok: true, type: 'pong' }
3. bridge.ts handles { type: 'prompt' } via pi.sendUserMessage
4. bridge.ts handles { type: 'editor_state' } and emits via pi.events
5. bridge.ts writes .info manifest with { cwd, pid, startedAt } to /tmp/pi-nvim-sockets/
6. .info manifest cleaned up on session_shutdown
7. Existing telegram and tell message flows unchanged
8. Existing tmux-session socket pattern unchanged

