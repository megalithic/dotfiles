---
id: dot-fsqm
status: open
deps: 4:1:deps: [, dot-sv2l]
links: []
created: 2026-06-03T20:11:43Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add dirty-buffer safety for Pi file-change notifications

Plan Step 12. When Pi file/tool write hooks are available, notify Nvim about changed files through editor service. Nvim runs checktime only for unmodified buffers. Modified buffers get conflict warning, stay dirty, never get clobbered. Merge/conflict here = keep buffer content, compare to on-disk state, surface mismatch; UI can be refined later. Files: config/nvim/lua/pinvim.lua or config/nvim/lua/pinvim/editor_service.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Dirty buffer remains dirty after external write triggered by Pi tool
2. Clean buffer reloads or prompts normally
3. Manual: dirty edit + external mutate + notification confirms no clobber
