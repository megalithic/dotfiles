---
id: dot-u15z
status: closed
deps: [dot-3fyc]
links: []
created: 2026-04-14T19:46:20Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-kts9
tags: [ready-for-development]
---
# Create pinvim.ts extension: nvim intelligence layer with live context injection

New pi extension that provides nvim-aware context injection into agent turns.

## What it does

- Listens for editor state updates from bridge.ts via pi.events bus
- Stores latest editor state (file, cursor, selection, filetype, modified, buftype)
- On before_agent_start, injects [NEOVIM LIVE CONTEXT] hidden message with:
  - Focused file name and filetype
  - Cursor position (line:col)
  - Active visual selection (line range + text if available)
  - File reference (@path for lightweight pointer)
  - Optional: in-memory buffer text for modified/unnamed buffers
- Displays nvim status in pi footer via ctx.ui.setStatus
- Registers /pinvim-info command showing socket path and focused target

## Key files

- home/common/programs/ai/pi-coding-agent/extensions/pinvim.ts (create)

## Architecture

pinvim.ts has no socket. It receives editor state from bridge.ts:
  pi.events.on('pinvim:editor_state', (state) => { ... })

Context injection uses before_agent_start hook (from carderne/pi-nvim):
  pi.on('before_agent_start', async () => {
    return { message: { customType: 'pinvim-live-context', content: formatted, display: false } }
  })

## Format (matches carderne pattern)

[NEOVIM LIVE CONTEXT]
Focused file: init.lua
Filetype: lua
Cursor: L17:C4
Selection: lines 5-12
Reference: @config/nvim/after/plugin/pi.lua

## Acceptance Criteria

1. pinvim.ts listens for pinvim:editor_state events from bridge.ts via pi.events
2. pinvim.ts stores latest editor state in memory
3. before_agent_start injects [NEOVIM LIVE CONTEXT] when editor state available
4. Context includes focused file, filetype, cursor, selection, reference
5. Context message has display: false (hidden from TUI, visible to LLM)
6. Footer status shows nvim: filename L17 (or nvim: -- when disconnected)
7. /pinvim-info command shows socket path and current editor state
8. No socket created by pinvim.ts (bridge.ts owns the socket)

