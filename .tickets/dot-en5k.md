---
id: dot-en5k
status: open
deps: [dot-3fyc]
links: []
created: 2026-04-14T19:46:45Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-kts9
tags: [ready-for-development]
---
# Upgrade pi.lua: persistent connection, cwd discovery, live context sync, compose mode

Major upgrade to config/nvim/after/plugin/pi.lua blending carderne/pi-nvim
features with existing functionality.

## Changes

### Connection (replace nc with vim.uv.new_pipe)
- Persistent bidirectional connection via vim.uv.new_pipe()
- Parse JSON responses from bridge.ts (ok/error handling)
- Auto-reconnect on connection loss
- Connection health via ping/pong

### Discovery (add cwd-based alongside tmux-session)
- Scan /tmp/pi-nvim-sockets/*.info for cwd-based socket discovery
- Prefer cwd match, fall back to tmux-session pattern, then latest
- Keep existing tmux-session pattern as fallback

### Live context sync (new)
- Configurable autocmd events table at top of config:
  config.live_context.events = { 'BufEnter', 'BufWritePost', 'InsertLeave',
    'ModeChanged', 'CursorMoved' }
- config.live_context.enabled = true/false
- config.live_context.debounce_ms = 150
- config.live_context.include_buffer_text = false
- config.live_context.max_buffer_bytes = 200000
- config.live_context.max_selection_bytes = 50000
- Debounced push of editor_state message on configured events
- Sends: file, absFile, filetype, modified, buftype, cursor, selection

### Compose/queue mode (new, from carderne)
- PiAdd command: queue context reference without sending
- PiFlush command: prompt for text, send all queued + prompt
- PiClear command: clear queue
- Queue count shown in statusline

### Raw prompt (new)
- PiPrompt command: send raw prompt string to pi
- No file/selection context, just text

### Auto-reload (new, from carderne)
- checktime polling when connected (1s interval)
- Only when pi socket is reachable

### Retained features (all existing)
- In-process LSP code actions (add to context, send selection, ask pi, send with diagnostics)
- Context tracking with timestamps
- tmux-toggle-pi integration + bell on agent pane
- Statusline component (connected/session/context count)
- Buffer-local targeting (vim.b.pi_target_socket)
- Snacks picker for session selection
- All existing commands and keymaps

## Key files

- config/nvim/after/plugin/pi.lua

## Acceptance Criteria

1. pi.lua uses vim.uv.new_pipe() for socket communication (no nc)
2. pi.lua parses JSON responses and notifies on errors
3. pi.lua discovers sockets via /tmp/pi-nvim-sockets/*.info (cwd match)
4. pi.lua falls back to tmux-session pattern if no cwd match
5. config table at top includes live_context section with events list
6. Editor state synced on configured autocmd events, debounced
7. PiAdd/PiFlush/PiClear commands work for compose mode
8. PiPrompt command sends raw prompt string
9. Auto-reload via checktime when connected
10. All existing features retained: LSP code actions, context tracking, tmux toggle, statusline, buffer-local targeting
11. Ping/pong health check works and reflects in statusline

