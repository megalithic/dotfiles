---
id: dot-mmvc
status: closed
deps: [dot-egiy]
links: [dot-p774]
created: 2026-04-15T16:36:17Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-42gl
tags: [ready-for-development]
---
# Phase 4: Slim sentinel/guardrail sections in GLOBAL

The sentinel extension already enforces guardrails (blocked commands, override protocol).
Having the full protocol written out in GLOBAL is redundant — the extension is the source
of truth. Slim these sections to brief mentions.

Current state:
- Uncommitted changes: ~35 lines with full blocked commands table
- Remote/SSH/Deploy: ~30 lines with examples
- Guardrail override protocol: ~35 lines with full flow diagram
Total: ~100 lines of guardrail content

Target state:
- Uncommitted changes: ~10 lines (core rule + brief note that sentinel enforces)
- Remote/SSH/Deploy: ~5 lines (brief rule, sentinel handles details)
- Guardrail override: ~5 lines (mention it exists, 'retry immediately on override granted')
Total: ~20 lines

Files to edit:
- home/common/programs/ai/pi-coding-agent/sources/GLOBAL_AGENTS.md

## Acceptance Criteria

1. Uncommitted changes section is ≤10 lines
2. Remote/SSH/Deploy section is ≤5 lines
3. Guardrail override section is ≤5 lines
4. Core rules preserved (never discard uncommitted, never push without permission)
5. Sentinel extension referenced as source of truth for enforcement details
6. just validate passes


## Notes

**2026-04-15T17:23:32Z**

New AC: Investigate commit scope guard — automated enforcement that validates edits/commands belong to current commit scope. Options: pi extension (before_tool_call hook), local LLM classification (like stop-hook), or heuristic file-set tracking. Should warn/block when work drifts outside current commit's logical scope unless user opted into single-commit mode.
