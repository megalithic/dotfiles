---
id: dot-s5lq
status: open
deps: [dot-en5k]
links: []
created: 2026-04-16T15:46:35Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-kts9
tags: [code-review, ready-for-development]
---
# Code review pi.lua: holistic audit including dot-en5k additions

Thorough code review of config/nvim/after/plugin/pi.lua — both the existing
~1200 lines AND the new code from dot-en5k (persistent connection, cwd
discovery, live context sync, compose mode, auto-reload). Review the file as a
complete whole after all changes land, not just the pre-expansion state.

## Scope

### Architecture
- Map all sections and their responsibilities
- Identify dead code, unused functions, stale references
- Evaluate monolithic vs modular structure (should this be split into pi/init.lua + pi/socket.lua, pi/compose.lua, pi/live_context.lua?)
- Document all global state and mutation patterns

### Socket communication
- Review vim.uv.new_pipe(true) IPC implementation (replaces nc)
- Verify bidirectional JSON-RPC: request/response parsing, error handling
- Review auto-reconnect logic: exponential backoff, max retries, message queuing during reconnect
- Verify ping/pong health check and statusline reflection
- Document all message types (existing + new: editor_state, prompt, ping)
- Review socket discovery: cwd-based (/tmp/pi-nvim-sockets/*.info) + tmux-session fallback
- Check connection lifecycle: connect, reconnect, graceful shutdown

### LSP integration
- Review in-process LSP server implementation
- Check code action handlers for correctness
- Verify diagnostic inclusion logic

### Tmux integration
- Review tmux-toggle-pi integration
- Check bell notification logic
- Verify pane targeting safety

### Context tracking
- Review context_files state management
- Check for memory leaks (unbounded growth)
- Verify timestamp handling

### Statusline
- Review statusline component for correctness
- Check for race conditions in async state updates
- Verify compose queue count display
- Verify connection state (connected/reconnecting/disconnected) display

### Live context sync (new from dot-en5k)
- Review debounce implementation (timer lifecycle, cancellation)
- Evaluate autocmd event list — CursorMoved traffic vs CursorHold alternative
- Verify include_buffer_text defaults false, max_buffer_bytes/max_selection_bytes caps enforced
- Check editor_state message format matches bridge.ts expectations
- Review performance: payload size on hot path, GC pressure from frequent table creation

### Compose/queue mode (new from dot-en5k)
- Review PiAdd/PiFlush/PiClear command implementations
- Check queue state management (unbounded growth? clear on flush?)
- Verify PiFlush prompt input UX (vim.ui.input? cmdline?)
- Review PiPrompt raw prompt flow

### Auto-reload (new from dot-en5k)
- Review checktime polling interval (should be configurable, default 5s)
- Verify only polls when connected and socket has recent activity
- Check interaction with existing buffer modification detection

### Keymaps & commands
- Catalog all user commands and keymaps
- Check for conflicts or dead bindings
- Verify which-key integration

### Code quality
- Identify duplicated patterns that could be extracted
- Check error handling consistency
- Review vim.schedule usage for thread safety
- Identify any blocking operations on main loop

## Deliverable

Markdown report with:
- Section-by-section findings for the complete file (existing + new)
- Bugs, edge cases, race conditions found
- Recommendations for each concern
- Decision on monolithic vs modular (with proposed module boundaries if splitting)
- Priority-ordered action items

Report goes in ~/.local/share/pi/plans/ for reference during implementation.
