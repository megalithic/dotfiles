---
id: dot-p774
status: open
deps: []
links: [dot-mmvc]
created: 2026-04-15T17:26:36Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Investigate commit scope guard for pi-coding-agent

Agent frequently forgets to create new commits for new logical work. Changes pile up
in one commit. Splitting after the fact is painful and sometimes the agent refuses.

Need automated enforcement that checks before each edit/bash tool call whether:
1. The change belongs to the current commit's scope
2. A new commit was already created for this work
3. User explicitly opted into single-commit mode

Implementation options to investigate:
- Pi extension (before_tool_call hook) that checks commit scope
- Local LLM classification (like stop-hook pattern) — classify 'does this change match current commit message?'
- Heuristic: track which files/directories the current commit touches, warn when editing outside that set
- Hybrid: heuristic for obvious cases, LLM for ambiguous ones

Reference: sentinel extension pattern for blocking/overriding dangerous commands.
Reference: stop-hook extension for local LLM integration pattern.

Files to study:
- home/common/programs/ai/pi-coding-agent/extensions/sentinel.ts
- home/common/programs/ai/pi-coding-agent/extensions/stop-hook.ts

## Acceptance Criteria

1. Document at least 3 approaches with pros/cons
2. Prototype the most promising approach (or explain why none are viable yet)
3. If viable: create implementation ticket(s)
4. If not viable: document blockers and what would unblock

