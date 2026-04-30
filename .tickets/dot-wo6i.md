---
id: dot-wo6i
status: open
deps: []
links: []
created: 2026-04-30T14:07:29Z
type: epic
priority: 2
assignee: Seth Messer
tags: [nix, browser, settings-sync, safari, chromium]
---
# Cross-browser bookmark sync: Brave/Brave Nightly/Helium/Safari

Research and implement bookmark synchronization across Brave Browser, Brave Browser Nightly, Helium Browser, and Safari (macOS + iOS). Prefer declarative nix/home-manager configuration. Extend existing settings-sync.nix module.

Key requirements:
- Sync bookmarks across all 4 browsers
- Safari iOS integration via iCloud
- Shared session/cookies/logins between Chromium browsers (secondary goal)
- Avoid vendor lock-in to browser-specific sync services
- Declarative configuration where possible

Current state:
- Brave Browser Nightly is source of truth
- settings-sync.nix exists but unused
- Chromium browsers use identical JSON format (easy win)
- Safari uses binary plist (requires converter)

Research document: ~/.local/share/pi/preview/20260430-100611-bookmark-sync-research.html

Solutions evaluated:
1. GoSuki (extension-free, multi-browser, unknown Safari support)
2. Syncthing (file-level, no format conversion)
3. Extend settings-sync.nix (simple Chromium-only approach)
4. Custom converter service (complex but complete)

Next steps pending user Q&A response in research document.


## Notes

**2026-04-30T14:07:39Z**

Research phase complete. Interactive Q&A document opened in browser with 10 clarifying questions covering:
- Safari sync priority (equal/secondary/minimal)
- Real-time vs periodic sync preference
- Browser state during sync (close vs live)
- Conflict resolution strategy
- Complexity tolerance
- Syncthing usage
- Shared sessions/cookies priority
- iOS Safari importance
- Migration plan from Brave Nightly source
- Next research steps

Awaiting user responses before implementation phase.

**2026-04-30T14:14:50Z**

User responses from Q&A:

Q1 (Safari priority): Safari is secondary - mainly for iOS access to bookmarks created/edited in Helium
Q5 (Complexity): Willing to improve settings-sync.nix module. Chromium ↔ Safari converter may be necessary.
Q6 (Syncthing): Future goal - sync various things between laptops, NAS, phone (mix of backup + 2-way sync)
Q7 (Shared sessions/cookies/logins): YES - high priority for Chromium browsers
Q9 (Source of truth): Eventually Helium will become source of truth after trial period as daily driver

Key insights:
- Helium = future primary browser
- Brave Nightly = current source, transitioning to Helium
- Safari = import-only for iOS access (one-way sync likely sufficient)
- All Chromium browsers should share: bookmarks, cookies, history, logins

**2026-04-30T14:16:33Z**

Additional context from user:

Goal: Improve/rewrite settings-sync.nix module
- Rename to sync.nix
- Relocate from home/common/modules/settings-sync.nix → home/common/programs/sync/default.nix
- Emphasis on making this a robust, general-purpose sync solution

Cross-repo coordination required:
- Create tickets in both ~/.dotfiles and ~/code/megadots
- Keep tickets linked and synced for progress tracking from either side
- Both repos should know about this work

**2026-04-30T14:18:32Z**

Cross-repo coordination established:

Megadots tickets:
- meg-am5n: Mirror epic for cross-repo tracking
- meg-oqfq: App backup/sync module (linked)
- meg-nrxy: Settings-sync evaluation (linked)

All tickets updated with cross-references and coordination notes.

Child tickets created in ~/.dotfiles:
- dot-myti: Refactor/rename module
- dot-v5xw: Add Brave/Helium support  
- dot-ltdf: Chromium shared data symlinks
- dot-4746: GoSuki Safari research
- dot-uwt8: Safari converter (conditional)
- dot-1e3z: Syncthing integration
- dot-aq4a: Brave Nightly → Helium migration

Dependencies configured. Ready for implementation.
