---
id: mbm-buez
status: open
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
