---
id: dot-kts9
status: open
deps: []
links: []
created: 2026-04-14T19:36:06Z
type: epic
priority: 1
assignee: Seth Messer
tags: [ready-for-development]
---
# Unify nvim↔pi communication: pinvim.ts + bridge.ts refactor + pi.lua upgrade

Blend best of carderne/pi-nvim and our bridge.ts/pi.lua into a unified architecture.

## Background

Investigated cperalt/pi-nvim (fork of carderne/pi-nvim) and compared with our
bridge.ts extension + config/nvim/after/plugin/pi.lua. Each has features the
other lacks. Goal: merge the best of both.

## Architecture

**bridge.ts (enhanced socket owner):**
- Keeps unix socket (tmux-session pattern for Hammerspoon/tell compatibility)
- ALSO writes carderne-style .info manifest in /tmp/pi-nvim-sockets/ for
  cwd-based discovery by nvim
- Upgrades to bidirectional JSON-RPC (responses back to clients)
- Handles all message types: nvim (selection, cursor, file, editor_state,
  prompt, ping), telegram, tell
- Forwards nvim editor_state to pinvim.ts via pi.events bus
- Idle-aware delivery (existing: steer vs followUp based on ctx.isIdle())

**pinvim.ts (new extension — nvim intelligence layer):**
- No socket of its own
- Listens for editor state updates from bridge.ts via pi.events
- Uses before_agent_start hook to inject [NEOVIM LIVE CONTEXT] (from carderne)
- Formats editor state: focused file, cursor, selection, filetype, references
- Registers /pinvim-info command
- Status display in pi footer (nvim: filename L17 sel 5-12)
- Configurable: live context on/off, include buffer text, max bytes

**pi.lua (upgraded nvim plugin):**
- Replace nc fire-and-forget with vim.uv.new_pipe() persistent bidirectional
  connection (like carderne uses)
- Add carderne-style cwd-based socket discovery alongside existing tmux-session
  pattern discovery
- Add live editor context sync: debounced push of buffer/cursor/selection/
  filetype on configurable autocmd events
- Add configurable sync events table at top of file (default: BufEnter,
  BufWritePost, InsertLeave, ModeChanged, CursorMoved — user can tune)
- Add ping/pong health check
- Add raw prompt message type (send prompt string directly to pi)
- Add compose/queue mode (PiAdd → PiFlush pattern from carderne)
- Keep ALL existing features: in-process LSP code actions, context tracking
  with timestamps, tmux-toggle-pi integration, bell on agent pane, statusline
  component, buffer-local targeting, Snacks picker for sessions
- Enhance LSP code actions to leverage live context (e.g. sync-to-pi action)
- Add auto-reload buffers when pi modifies files (checktime polling when
  connected, from carderne)

**Hammerspoon pi.lua (updated):**
- Replace nc/io.popen with hs.socket.new() for persistent bidirectional
  connection to bridge.ts socket
- Keep existing: session targeting, Telegram forwarding, socket discovery

## Key files

- home/common/programs/ai/pi-coding-agent/extensions/bridge.ts (modify)
- home/common/programs/ai/pi-coding-agent/extensions/pinvim.ts (create)
- config/nvim/after/plugin/pi.lua (modify)
- config/hammerspoon/lib/interop/pi.lua (modify)

## Protocol

Bidirectional JSON-RPC over unix socket. All messages are newline-delimited JSON.

Requests (client → bridge.ts):
  { type: 'ping' }
  { type: 'prompt', message: '...' }
  { type: 'editor_state', state: { file, cursor, selection, filetype, ... } }
  { type: 'selection', file, range, selection, language, lsp, task }
  { type: 'file', file, content, ... } (existing nvim payloads)
  { type: 'file_reference', file, ... } (existing nvim payloads)
  { type: 'cursor', file, range, selection, language, lsp, task }
  { type: 'telegram', text, source, timestamp }
  { type: 'tell', text, from, timestamp }

Responses (bridge.ts → client):
  { ok: true }
  { ok: true, type: 'pong' }
  { ok: false, error: '...' }

## Future state (not in scope)

- HTTP/SSE server as transport (replace unix socket entirely)
- ACP (Agent Context Protocol) for multi-agent orchestration
- Tidewave Web MCP integration (nvim + pi + tidewave runtime intelligence)
  Tidewave provides: project_eval, get_docs, get_source_location, get_logs,
  execute_sql_query, get_ecto_schemas, search_package_docs via MCP at
  http://localhost:PORT/tidewave/mcp. Future ticket to integrate this with
  pi via MCP client in extension or skill.

## Acceptance Criteria

1. bridge.ts writes .info manifest alongside socket for cwd-based discovery
2. bridge.ts sends JSON responses back to clients (bidirectional, not fire-and-forget)
3. bridge.ts handles ping/pong, prompt, editor_state message types
4. bridge.ts forwards editor_state to pinvim.ts via pi.events
5. pinvim.ts injects [NEOVIM LIVE CONTEXT] via before_agent_start hook when editor state available
6. pinvim.ts shows nvim status in pi footer (file, cursor, selection)
7. pi.lua uses vim.uv.new_pipe() instead of nc for socket communication
8. pi.lua discovers sockets via cwd-based .info manifests (carderne pattern)
9. pi.lua syncs editor state on configurable autocmd events (debounced)
10. pi.lua config table at top of file includes sync event list
11. pi.lua supports compose/queue mode (PiAdd/PiFlush commands)
12. pi.lua supports raw prompt sending (PiPrompt or similar)
13. pi.lua retains all existing features: LSP code actions, context tracking, tmux toggle, statusline, buffer-local targeting
14. Hammerspoon pi.lua uses hs.socket.new() instead of nc/io.popen
15. All existing Telegram and tell message flows still work unchanged
16. Existing tmux-session socket pattern still works (backward compatible)

