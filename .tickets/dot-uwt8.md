---
id: dot-uwt8
status: open
deps: [dot-4746]
links: []
created: 2026-04-30T14:17:30Z
type: task
priority: 3
assignee: Seth Messer
parent: dot-wo6i
tags: [safari, chromium, converter, python]
---
# Implement Safari bookmark converter (if GoSuki doesn't support)

Build Safari ↔ Chromium bookmark converter (ONLY if GoSuki research shows no Safari support).

Requirements (from user Q&A):
- Safari is import-only (one-way: Chromium → Safari)
- Purpose: iOS access to bookmarks created in Helium
- Periodic sync is acceptable (cron job)

Implementation:
1. Python script: safari-bookmark-sync
2. Read Chromium Bookmarks JSON (from Helium profile)
3. Convert to Safari plist format
4. Write to ~/Library/Safari/Bookmarks.plist
5. Handle Safari iCloud sync coordination
6. Add to sync module as optional service
7. Launchd agent for periodic execution (daily or manual trigger)

Safety:
- Backup Safari bookmarks before overwrite
- Check if Safari is running (warn user)
- Conflict resolution: Chromium always wins (user confirmed)

Dependency: Blocked on GoSuki research ticket (only implement if needed)

