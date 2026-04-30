---
id: dot-aq4a
status: open
deps: [dot-v5xw, dot-ltdf]
links: []
created: 2026-04-30T14:17:48Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-wo6i
tags: [browser, migration, bookmarks]
---
# Migration: Export Brave Nightly bookmarks → Helium

One-time migration: Brave Browser Nightly (current source of truth) → Helium (future primary).

User plan: Trial Helium, eventually make it source of truth.

Steps:
1. Export bookmarks from Brave Nightly using sync module
2. Backup existing Helium bookmarks (if any)
3. Import to Helium
4. Verify bookmark structure preserved
5. Enable symlink sharing (Helium as source)
6. Brave/Brave Nightly become symlinks to Helium data

This is the transition from 'Brave Nightly as source' to 'Helium as source'.

Dependency: Requires sync module with Helium support (dot-v5xw) and symlink feature (dot-ltdf)

