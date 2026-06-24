---
id: mbm-ju5m
status: closed
deps: []
links:
  [
    mbm-buez,
    mbm-c3sd,
    mbm-xqjv,
    mbm-m0rs,
    mbm-55qf,
    mbm-9ov0,
    mbm-8afn,
    mbm-qkmx,
  ]
created: 2026-06-22T21:33:34Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Make kanata and kanata-bar migration executable or explicitly Nix-retained

Turn the kanata audit findings into a safe migration implementation or a clear Nix-retained gate. Current Nix owns TCC-sensitive binary copying, daemon launchd, sudoers, mutable active config symlink, TCP port 5829, kanata-bar app/config/launchd, and Hammerspoon switching. File hints: modules/darwin/kanata.nix, home/common/programs/kanata/default.nix, config/kanata, config/hammerspoon, mise.toml, lat.md/migration/mise-parity-checklist.md.

## Acceptance Criteria

1. Document exact behavior that must be preserved before Nix ownership can be removed.
2. Either implement a safe scripts/mise kanata installer/preflight or mark kanata and kanata-bar as explicitly Nix-retained for v1.
3. If implemented, script preserves stable /usr/local/bin/kanata behavior, validates sudoers with visudo, manages launchd safely, and does not break TCC path stability.
4. Validation commands cover /usr/local/bin/kanata --version, launchctl daemon state, TCP port 5829, kanata-bar launch/config, and Hammerspoon config switching.
5. mise bootstrap cannot apply an incomplete kanata path silently.
6. lat.md/migration/mise-parity-checklist.md status is updated from unsafe to safe, partial, or Nix-retained with rationale.

## Notes

**2026-06-23T13:57:12Z**

Decision: kanata and kanata-bar Nix-retained for v1.
10 behaviors that make script migration too fragile:

1. Binary TCC cdhash stability (must copy to /usr/local/bin/kanata, version-aware skip)
2. sudoers for passwordless pkill (requires visudo validation)
3. Privileged launchd daemon (runs via sudo, needs careful unload/reload)
4. Mutable config symlink (~/.config/kanata/kanata.kbd, written by activation script, switched by Hammerspoon)
5. TCP port 5829 for kanata-bar + Hammerspoon communication
6. kanata-bar app download with pinned hash, unzip, config generation
7. kanata-bar config.toml referencing kanata binary path and port
8. kanata-bar launchd agent with /usr/bin/open -a path
9. SF Symbol icons from config/kanata/icons
10. Post-activation service restart (kanata daemon + kanata-bar, timed for TCP readiness)
    Config files already migrated: individual .kbd targets in mise.toml dotfiles.
    Checklist updated: kanata daemon status → Nix-retained, kanata-bar → Nix-retained, both validated.
    lat_check passed. Revisit if upstream kanata provides a Brew cask with stable binary path.
