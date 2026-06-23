---
id: mbm-m0rs
status: open
deps: []
links:
  [
    mbm-buez,
    mbm-c3sd,
    mbm-ju5m,
    mbm-xqjv,
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

# Add Okta Verify privileged pkg installer plan for mise migration

Replace the placeholder Okta Verify comment with a safe plan or implementation that preserves current nix-darwin behavior: use the official .pkg and /usr/sbin/installer so privileged postinstall installs LaunchDaemons and SecurityAgentPlugin. File hints: modules/darwin/okta-verify.nix, home/common/programs/okta-verify/default.nix, mise/Brewfile, scripts/mise, lat.md/system-config.md, lat.md/migration/mise-parity-checklist.md.

## Acceptance Criteria

1. Current pinned Okta version/build/hash and pkg receipt behavior are captured from modules/darwin/okta-verify.nix.
2. A scripts/mise implementation or explicit Nix-retained decision exists; Brew cask/MAS extraction is not treated as equivalent.
3. Implementation, if added, is idempotent on pkgutil receipt version and uses /usr/sbin/installer only with explicit user approval or documented bootstrap phase.
4. Validation covers pkgutil receipt, expected LaunchDaemons, SecurityAgentPlugin, and app presence.
5. mise bootstrap reports Okta as blocked/manual/Nix-retained rather than silently skipping it.
6. lat.md/migration/mise-parity-checklist.md and lat.md/system-config.md are updated if ownership changes.
