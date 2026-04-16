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
- bin/tmux-toggle-pi
- home/common/programs/ai/pi-coding-agent/extensions/bridge.ts
- home/common/programs/ai/pi-coding-agent/default.nix

## Acceptance Criteria

1. pi.lua uses vim.uv.new_pipe(true) (IPC mode) for socket communication (no nc)
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
12. Auto-reconnect uses exponential backoff (1s/2s/4s/8s, max 30s), notifies user on give-up after 5 retries
13. Messages queued during reconnect, flushed on reconnection (or dropped with notification if queue > 50)
14. Compose mode queue count visible in statusline component
15. include_buffer_text defaults to false; enabling it respects max_buffer_bytes cap
16. CursorMoved in default events list documented as high-traffic; CursorHold recommended as alternative
17. checktime interval configurable (default 5s, not 1s); only polls when pi socket has had recent activity
18. toggle_panel() is async (jobstart, not vim.fn.system)
19. tmux-toggle-pi accepts --socket flag to target specific pi pane by socket path
20. toggle_panel() passes targeted socket to tmux-toggle-pi so pane matches socket
21. Socket discovery skips stale sockets (validates .info manifest pid is alive)
22. Duplicate commands removed: PiToggle removed (PiPanel kept), duplicate keymap <ll>pt removed
23. Bell ringing and --ensure target the pane matching the active socket, not first π pane
24. PiHealth checks for stale sockets and reports them
25. bridge.ts auto-detects tmux session/window for socket path (no pinvim shell setup needed)
26. PI_SOCKET env var still works as override for explicit control
27. Raw `pi` binary works for socket comms when run inside tmux (pinvim only needed for API keys/profiles)

## Validation & Testing

### Connection (vim.uv.new_pipe)
- Open nvim with pi running → `:PiStatus` shows connected with session name
- Kill pi process → statusline updates to disconnected within ~5s
- Restart pi → auto-reconnect restores connection (watch `:messages` for reconnect notifications)
- `:PiPing` returns "pong" confirmation
- Send selection while disconnected → queued message notification, delivered on reconnect

### Discovery (cwd-based)
- `cat /tmp/pi-nvim-sockets/*.info` — verify manifest exists with correct cwd
- Open nvim in same cwd as pi → auto-discovers correct socket (`:PiStatus`)
- Open nvim in different cwd → falls back to tmux-session pattern
- Multiple pi sessions running → correct one selected by cwd match
- No pi sessions → graceful "not connected" in statusline

### Live context sync
- Enable: confirm `config.live_context.enabled = true` in config block
- Switch buffers → bridge.ts receives `editor_state` (check pi debug log or add temp log)
- Save file → editor_state sent with updated modified flag
- Rapid typing → debounce prevents flood (should not see >~7 messages/sec at 150ms debounce)
- Disable: set `config.live_context.enabled = false` → no editor_state messages sent

### Compose mode (PiAdd/PiFlush/PiClear)
- `:PiAdd` in visual mode → "Queued 1 item" notification, statusline shows queue count
- `:PiAdd` on multiple selections → queue count increments
- `:PiFlush` → prompts for text, sends all queued items + prompt to pi, queue clears
- `:PiClear` → clears queue, statusline count resets to 0
- `:PiFlush` with empty queue → sends just the prompt text

### Raw prompt (PiPrompt)
- `:PiPrompt hello` → sends "hello" directly to pi (appears in pi conversation)
- `:PiPrompt` (no args) → prompts for input, then sends
- Empty input → no message sent

### Auto-reload (checktime)
- Pi edits a file open in nvim → buffer reloads automatically (no manual `:e!`)
- Disconnect pi → checktime polling stops (no wasted cycles)
- Verify interval: should poll every 5s (not 1s) — check with `:lua print(vim.inspect(config))`

### Statusline
- Connected: icon + session name + context count + queue count visible
- Disconnected: dimmed icon only
- Reconnecting: icon with "..." or similar indicator

### Tmux toggle integration
- `<localleader>pp` toggles pi pane that matches active socket target
- If no pi exists for target → creates new one
- If pi.lua targets `pi-mega-agent.sock` → toggle shows agent window pane (not random π pane)
- `:PiSessions` changes socket target → next toggle shows that pi's pane
- Toggle is non-blocking (nvim stays responsive)
- Stale sockets (dead pid) skipped in discovery, reported by `:PiHealth`

### Retained features (regression check)
- `<localleader>ps` (visual) → sends selection with task prompt
- `<localleader>pf` → adds file to context
- `<localleader>pp` → toggles pi tmux pane
- `<localleader>pn` → opens session picker
- `:PiLspStart` / `:PiLspAttach` → code actions appear in LSP menu
- `vim.b.pi_target_socket = "/tmp/pi-other.sock"` → overrides auto-discovery for that buffer

