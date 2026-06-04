---
id: dot-sv2l
status: closed
deps: 4:1:deps: [, dot-ds0s]
links: []
created: 2026-06-03T20:11:26Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add Pi→Nvim editor API methods (context, refresh, open/reveal/reload)

Plan Step 11. Implement minimal methods: status, context.current, diagnostics.current, open_file, reveal_file, reload_buffer, refresh_diagnostics, checktime. Keep current explicit_send path. Add token/auth checks if transport is anything beyond trusted local socket/server. Add clean pre-prompt query hook so Pi can ask Nvim for context before every user-origin turn without awkward chat injection. Files: config/nvim/lua/pinvim.lua or config/nvim/lua/pinvim/editor_service.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Pi fetches current buffer context without tmux guessing
2. Pi can request open/reveal/reload via API
3. /pinvim-status includes editor-service status
4. just home passes
5. Other local extensions can reuse the same query path
