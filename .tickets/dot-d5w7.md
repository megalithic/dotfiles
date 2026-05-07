---
id: dot-d5w7
status: open
deps: []
links: []
created: 2026-05-07T16:46:15Z
type: chore
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Trim preview skill to non-obvious features only

The preview skill (skills/preview/SKILL.md) documents basic usage that /preview --help
already covers. The extension (extensions/preview.ts) provides the runtime. The skill
should only document what the extension help doesn't: HTML mode details, troubleshooting,
browser detection, garbage collection, tmux pane safety.

Remove: basic content type examples, simple flag docs, keyboard shortcuts
Keep: HTML mode (--html), browser targeting, GC, troubleshooting, tmux pane safety rules

Files: home/common/programs/pi-coding-agent/skills/preview/SKILL.md

## Acceptance Criteria

1. Preview skill trimmed to HTML mode, troubleshooting, and non-obvious features
2. Basic usage docs (content types, simple flags) removed from skill
3. /preview still works correctly (smoke test: /preview diff, /preview --html)
4. just validate home passes

