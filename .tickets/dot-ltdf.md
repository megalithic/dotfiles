---
id: dot-ltdf
status: open
deps: [dot-v5xw]
links: []
created: 2026-04-30T14:17:15Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-wo6i
tags: [nix, browser, sync, chromium, symlink]
---
# Implement Chromium browser shared data via symlinks

Enable shared bookmarks/cookies/history/logins between Chromium browsers.

Approach: Designate one browser as source (Helium after migration), symlink others to it.

Implementation:
1. Add sync.chromiumSharedData option (browsers = [brave brave-nightly helium], source = helium)
2. Create activation script to symlink:
   - Bookmarks → source/Bookmarks
   - Cookies → source/Cookies (if enabled)
   - History → source/History (if enabled)
   - Login Data → source/Login Data (if enabled)
3. Handle first-time setup (backup existing files)
4. Add safety check: error if any browser is running
5. Document caveats (browsers must be closed for initial setup)

Dependency: Requires dot-myti (module relocation) complete first

