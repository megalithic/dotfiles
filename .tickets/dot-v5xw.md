---
id: dot-v5xw
status: open
deps: [dot-myti]
links: []
created: 2026-04-30T14:17:15Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-wo6i
tags: [nix, browser, sync, chromium]
---
# Add Brave Browser + Helium support to sync module

Extend sync module to support all Chromium browsers:
- Brave Browser (currently missing)
- Helium Browser (currently missing)
- Brave Browser Nightly (already exists)

All use identical JSON format for bookmarks.

Implementation:
1. Add app profiles for brave-browser and helium-browser
2. Mirror brave-nightly profile structure
3. Include: Bookmarks, Preferences, Cookies, History, Login Data
4. Support conditional flags: cookies, history, logins (user already wants these)
5. Test export/import from each browser

