---
id: dot-1e3z
status: open
deps: []
links: []
created: 2026-04-30T14:17:48Z
type: task
priority: 3
assignee: Seth Messer
parent: dot-wo6i
tags: [nix, syncthing, sync, multi-device]
---
# Add syncthing support to sync module

Add syncthing as sync backend option (alongside iCloud).

User goal: Sync data between laptops, NAS, phone (mix of backup + 2-way sync).

Implementation:
1. Add programs.syncthing config to home-manager
2. Declarative folder configuration
3. Device ID management (per-host)
4. Integration with sync module:
   - syncDir can point to syncthing folder
   - Auto-create syncthing folders for enabled apps
5. Document setup process (device pairing, folder sharing)
6. Launchd service for syncthing daemon

Note: Syncthing itself available in nixpkgs, just needs declarative config.

Lower priority than Chromium sync, but foundation for future NAS/phone sync.

