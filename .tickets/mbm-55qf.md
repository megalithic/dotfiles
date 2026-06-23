---
id: mbm-55qf
status: closed
deps: []
links:
  [
    mbm-buez,
    mbm-c3sd,
    mbm-ju5m,
    mbm-xqjv,
    mbm-m0rs,
    mbm-9ov0,
    mbm-8afn,
    mbm-qkmx,
  ]
created: 2026-06-22T21:33:33Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Implement mise dotfile symlink classifier preflight

Build a read-only preflight used by the mise bootstrap migration to inspect each target in mise.toml [dotfiles] before any link/adopt operation. It must follow symlink chains like ~/.config/ghostty -> /nix/store/...home-manager-files -> /nix/store/...hm_ghostty -> ~/.dotfiles/config/ghostty and classify final ownership. File hints: mise.toml, scripts/mise/doctor, scripts/mise/bootstrap-final, lat.md/migration/mise-parity-checklist.md, home/common/lib.nix.

## Acceptance Criteria

1. A script or doctor subcommand reads every mise.toml [dotfiles] target and prints a dry-run table with installed path, symlink chain, final target, and class.
2. Classes include repo-final, store-flake-source, store-generated, external-final, real-directory, real-file, missing, and conflict/unknown.
3. The script never mutates filesystem state and exits nonzero only for true conflicts or unreadable paths.
4. The report correctly identifies repo-final paths documented in lat.md/migration/mise-parity-checklist.md, including ghostty, hammerspoon, nvim, tmux, kitty, kanata macbook files, SSH config, and espanso app-support path.
5. lat.md/migration/mise-parity-checklist.md is updated if classification names or behavior change.
6. Existing validation still passes: lat_check and relevant shell lint/format checks.

## Notes

**2026-06-22T21:47:36Z**

Implemented read-only scripts/mise/dotfile-preflight and wired scripts/mise/doctor plus mise task dotfiles:preflight. Classifier reads mise.toml [dotfiles], follows full symlink chains, reports target/source/final/class/status, and exits nonzero only on unknown/conflict. Validation run found safe repo-final targets: ghostty, hammerspoon, kitty, nvim, tmux, ~/bin; missing safe targets: fnox config, ~/.config/ssh, ~/.config/espanso; needs handling: generated mise config, real fish/kanata/.local/bin dirs, store-flake git files. Also confirmed mise targets for SSH and espanso are wrong vs current ~/.ssh/config and ~/Library/Application Support/espanso ownership. Checks: scripts/mise/dotfile-preflight, --json, shellcheck doctor/bootstrap-final, lat_check. scripts/mise/doctor still exits 1 because fnox command missing on this host, unrelated to classifier.

**2026-06-22T21:48:53Z**

Follow-up: added inventory-only checks for documented repo-final paths not yet represented correctly in mise.toml: ~/.ssh/config, ~/Library/Application Support/espanso, and ~/.config/kanata/macbook\*.kbd. Latest preflight summary: safe=13, needs-handling=7, conflicts=0.
