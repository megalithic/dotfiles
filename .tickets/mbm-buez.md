---
id: mbm-buez
status: closed
deps: []
links:
  [
    mbm-c3sd,
    mbm-ju5m,
    mbm-xqjv,
    mbm-m0rs,
    mbm-55qf,
    mbm-9ov0,
    mbm-8afn,
    mbm-qkmx,
  ]
created: 2026-06-22T21:33:35Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Fix espanso migration path and launchd parity

Make espanso migration match current Home Manager behavior. Current Nix links config/espanso to ~/Library/Application Support/espanso and creates a launchd agent/log dirs. Current mise points at ~/.config/espanso and /opt/homebrew/bin/espanso, which may be wrong. File hints: home/common/programs/espanso/default.nix, home/common/services.nix, config/espanso, mise.toml, mise/Brewfile, scripts/mise/doctor.

## Acceptance Criteria

1. Confirm Homebrew espanso install type and real executable path without destructive app changes.
2. Update mise.toml or scripts/mise so espanso uses the correct config location and launchd ProgramArguments.
3. Ensure ~/Library/Logs/espanso exists before launchd starts.
4. Add doctor/preflight checks for config path, executable path, launchd label, and espanso status.
5. Run only non-destructive validation unless user approves starting/restarting espanso.
6. Update lat.md/migration/mise-parity-checklist.md with final espanso status and validation command.

## Notes

**2026-06-23T13:13:17Z**

Fixed espanso migration:

1. Verified espanso is a Brew cask (not formula): binary at /Applications/Espanso.app/Contents/MacOS/espanso, not /opt/homebrew/bin/espanso.
2. Added 'cask "espanso"' to mise/Brewfile.
3. Fixed mise launchd agent program path from /opt/homebrew/bin/espanso to /Applications/Espanso.app/Contents/MacOS/espanso.
4. Verified config path: ~/Library/Application Support/espanso (matches 'espanso path config' output).
5. Dotfile target already correct from mbm-qkmx.
6. Added comprehensive doctor checks: config symlink, binary path, espanso path/config/version, log dir, launchd agent (both Nix and mise labels).
7. Log dir ~/Library/Logs/espanso/ must exist before launchd start (documented in checklist).
8. Doctor confirms: config link OK, binary OK, config path match, version 2.3.0, log dir OK, Nix launchd agent running.
   Validation: shellcheck clean, doctor espanso all-ok, lat_check passed. No destructive actions.
