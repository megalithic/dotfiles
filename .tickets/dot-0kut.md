---
id: dot-0kut
status: closed
deps: []
links: []
created: 2026-04-15T16:35:47Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-42gl
tags: [ready-for-development]
---
# Phase 1: Relocate system-specific content out of GLOBAL_AGENTS.md

Move system-specific sections from GLOBAL_AGENTS.md to their proper homes.
These sections are loaded into every pi session but only relevant to specific contexts.

Relocations:
- Hammerspoon rules (~40 lines) → config/hammerspoon/AGENTS.md (create new file)
- Telegram interaction + bridge debugging (~60 lines) → home/common/programs/ai/pi-coding-agent/AGENTS.md
- IEx scripts (~20 lines) → create skill or keep for Elixir project AGENTS.md files
- Nix environment basics (~10 lines) → already in repo AGENTS.md, just remove from GLOBAL
- Pi agent directory detection (~30 lines) → repo AGENTS.md
- Ntfy telegram formatting → bin/ntfy inline comments or help text

Files to create:
- config/hammerspoon/AGENTS.md
Files to edit:
- home/common/programs/ai/pi-coding-agent/sources/GLOBAL_AGENTS.md (remove relocated sections)
- home/common/programs/ai/pi-coding-agent/AGENTS.md (receive Telegram content)
- AGENTS.md (receive Pi agent directory detection if not already there)

Acceptance criteria verifiable by checking line counts and content.

## Acceptance Criteria

1. config/hammerspoon/AGENTS.md exists with Hammerspoon rules from GLOBAL
2. Telegram/bridge content moved to pi-coding-agent/AGENTS.md
3. IEx content removed from GLOBAL (placed in skill or project-level file)
4. Nix environment section removed from GLOBAL (exists in repo AGENTS.md)
5. Pi agent directory detection removed from GLOBAL (exists in repo AGENTS.md)
6. GLOBAL_AGENTS.md no longer contains system-specific sections
7. just validate passes
8. No content lost — all relocated sections findable via rg

