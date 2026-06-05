---
id: dot-kwhh
status: closed
deps: 4:1:deps: 4:1:deps: 4:1:deps: 4:1:deps: [, dot-fsqm, dot-nknd, dot-m3c1, dot-xe1y]
links: []
created: 2026-06-03T20:11:43Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Document pinvim rewrite in lat.md and curated docs

Plan Step 16. Document Nvim-owned lifecycle, registry precedence, child sessions, editor service, and removed ephemeral auto-resume. Update any existing lat.md/ sections touched by implementation. Files: lat.md/ if present, plus curated docs only if existing docs mention old lifecycle.

## Acceptance Criteria

1. Docs match new behavior
2. lat_check passes if available
3. Any reference to old ephemeral/tmux lifecycle is removed or updated
