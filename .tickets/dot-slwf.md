---
id: dot-slwf
status: open
deps: 4:1:deps: [, dot-fiq5]
links: []
created: 2026-06-03T20:11:26Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Make nested Pi safe by default; no peer stealing

Plan Step 7. If Pi starts inside existing parent context without explicit child role, do not steal active Nvim peer. Default to isolated attach-only mode or explicit child mode; never auto-promote or replace active main link. Exact parent/workspace/session identity gates acceptance before scoring fallback. Nested state visible in status/doctor output. Files: home/common/programs/pi-coding-agent/extensions/pinvim.ts.

## Acceptance Criteria

1. Starting pinvim inside Pi does not switch original Nvim link
2. /pinvim-health explains attach-only/child/no-parent state
3. just home passes
4. Manual: gps/gpa from original Nvim still routes to original Pi after nested pinvim launch
