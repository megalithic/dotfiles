---
id: dot-lckz
status: closed
deps: []
links: []
created: 2026-06-01T16:47:51Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Improve stop-hook ticket overview anchoring

Improve the stop-hook ticket summary so anchors and recommended-next suggestions stay accurate after ticket transitions. Current behavior can keep an unrelated in-progress ticket as Anchor, duplicate recommended tickets, and miss direct dependents after a ticket is closed (example: dot-0jhu closed should have suggested dot-d7em before unrelated Helium work). Relevant code: home/common/programs/pi-coding-agent/extensions/stop-hook.ts getTicketSummary(), plus any helper logic near ticket parsing/scoring. Keep this work until after the llama.cpp ticket chain is done.

## Acceptance Criteria

1. Stop-hook ticket summary refreshes tk state at stop time and does not rely on stale cached ticket overview data.
2. Anchor selection prefers recent explicit ticket activity/mentions from the current thread, including just-started or just-closed tickets, over unrelated in-progress tickets.
3. After a ticket closes, direct ready dependents rank before unrelated in-progress tickets.
4. Recommended next tickets are de-duplicated by ticket ID.
5. Output separates the active/anchor context from other in-progress tickets when they are unrelated.
6. Verification covers the observed case: after closing dot-0jhu, dot-d7em is recommended before dot-7tgz.
7. Existing Pi extension checks/type checks pass, and lat.md is updated if durable behavior changes are documented.

## Notes

**2026-06-01T16:53:44Z**

User chose to work this before finishing the remaining rxbookpro llama.cpp tuning, so removed dependency on dot-1ijx and started the ticket.

**2026-06-01T16:59:31Z**

Implemented stop-hook ticket summary freshness/ranking fix. getTicketSummary now strips previously injected VCS/Tickets overview text before extracting anchor IDs, parses ticket frontmatter deps from tk show, merges ready sets and de-dupes by ticket ID, ranks active tickets and direct dependents ahead of unrelated in-progress tickets, and splits unrelated in-progress tickets into Other in-progress. Verified extension loads via pi --no-extensions -e stop-hook.ts --help; ran synthetic local regression for dot-0jhu -> dot-d7em before dot-7tgz; just validate home passed; just home --skip-sync applied; lat_check passed.
