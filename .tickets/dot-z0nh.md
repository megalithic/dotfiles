---
id: dot-z0nh
status: open
deps: [dot-362h]
links: []
created: 2026-05-06T12:20:11Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Walk all 16 ACs for dot-8arp + file follow-up tickets

Final validation phase for the oMLX migration (dot-8arp). Two parts:

1. Walk all 16 acceptance criteria from dot-8arp and build an evidence checklist mapping each AC to commit hash, command output, or file path. Post as completion evidence.

2. File follow-up tickets for:
   - (a) Full ollama package + models removal once omlx is stable for N days (depends on dot-8arp staying green)
   - (b) Optional menubar app via mkApp for oMLX DMG
   - (c) Shade migration to share oMLX model dir if HF-cache discovery is enabled

Files:
- .tickets/dot-8arp.md — status update with AC evidence
- New tickets under .tickets/ for follow-ups

No code changes in this ticket — validation and documentation only.

## Acceptance Criteria

1. All 16 ACs from dot-8arp have green checkmarks with evidence (commit hash, command output, or file path)
2. Evidence checklist is appended to dot-8arp ticket
3. Follow-up ticket (a) exists for ollama full removal with dep on dot-8arp
4. Follow-up ticket (b) exists for optional oMLX menubar mkApp
5. Follow-up ticket (c) exists for Shade model dir sharing
6. All follow-up tickets have status proposed and deps referencing dot-8arp
7. tk list shows the three new tickets

