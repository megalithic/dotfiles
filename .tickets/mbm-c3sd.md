---
id: mbm-c3sd
status: open
deps: []
links:
  [
    mbm-buez,
    mbm-ju5m,
    mbm-xqjv,
    mbm-m0rs,
    mbm-55qf,
    mbm-9ov0,
    mbm-8afn,
    mbm-qkmx,
  ]
created: 2026-06-22T21:33:36Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Validate 1Password Brew and Aqua ownership for signing and secrets

Prove the mise target for 1Password is safe before removing nix-darwin ownership. Current Nix installs GUI to /Applications and op to /usr/local/bin/op, and git/jj signing uses /Applications/1Password.app/Contents/MacOS/op-ssh-sign. File hints: modules/darwin/\_1password.nix, home/common/programs/git, home/common/programs/jj, home/common/programs/ssh, mise/Brewfile, mise.toml, mise/fnox/config.toml, scripts/mise/render-fnox-files.

## Acceptance Criteria

1. Validate Brew cask installs 1Password.app in /Applications and preserves op-ssh-sign path.
2. Validate the mise/Aqua op CLI can integrate with the GUI and 1Password agent without conflicting with any Brew CLI.
3. Validate git and jj signing config points at a working op-ssh-sign path.
4. Validate fnox/1Password secret access works with the selected op/GUI setup.
5. Document Gatekeeper/Open Anyway behavior if it remains a manual first-launch step.
6. Update lat.md/migration/mise-parity-checklist.md with final status and validation evidence.
