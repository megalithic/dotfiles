---
id: dot-egiy
status: open
deps: [dot-wl77]
links: []
created: 2026-04-15T16:36:08Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-42gl
tags: [ready-for-development]
---
# Phase 3: Add core principles to GLOBAL_AGENTS.md

Add behavioral principles as the opening section of GLOBAL_AGENTS.md.
These are universal rules that prevent common agent failures (like skipping context files).
Inspired by HazAT's pi-config AGENTS.md.

Principles to add (each 2-4 lines max):
1. Read before you edit — read file, inline comments, check AGENTS.md in directory
2. Try before asking — don't ask if tool installed, run it
3. Verify before claiming done — run command, show output, confirm claim
4. Investigate before fixing — observe → hypothesize → verify → fix
5. Investigate means only investigate — when user says check/inspect, report only
6. Clean up after yourself — remove debug artifacts before committing
7. Only fix what's asked — no bonus improvements, KISS/YAGNI
8. Respect convention files — AGENTS.md, CLAUDE.md, .cursorrules, inline AGENT CONTEXT

This section should come BEFORE the Tools section — principles first, mechanics second.

Reference: https://github.com/HazAT/pi-config/blob/main/AGENTS.md (Core Principles section)

Files to edit:
- home/common/programs/ai/pi-coding-agent/sources/GLOBAL_AGENTS.md

## Acceptance Criteria

1. GLOBAL_AGENTS.md opens with Core Principles section (before Tools)
2. All 8 principles listed with concise explanations
3. Each principle is 2-4 lines (not verbose essays)
4. 'Read before you edit' explicitly mentions inline comments and AGENTS.md
5. 'Respect convention files' lists known formats (AGENTS.md, CLAUDE.md, .cursorrules)
6. Total GLOBAL file is ~150 lines or less
7. just validate passes

