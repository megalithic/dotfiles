---
id: mbm-8afn
status: closed
deps: []
links:
  [
    mbm-buez,
    mbm-c3sd,
    mbm-ju5m,
    mbm-xqjv,
    mbm-m0rs,
    mbm-55qf,
    mbm-9ov0,
    mbm-qkmx,
  ]
created: 2026-06-22T21:33:34Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Port generated Home Manager config fragments for mise bootstrap

Move or replace Home Manager-generated config fragments that current live configs depend on, using committed static files or small deterministic render scripts. Focus on generated files that are not repo-final symlinks. File hints: home/common/programs/hammerspoon/default.nix, home/common/programs/shade-next/default.nix, home/common/programs/tmux/default.nix, home/common/programs/starship/default.nix, home/common/programs/karabiner/default.nix, home/common/programs/pi-coding-agent/default.nix, scripts/mise/setup-pi, lat.md/migration/mise-parity-checklist.md.

## Acceptance Criteria

1. Required generated fragments are inventoried and assigned target owners: committed file, scripts/mise renderer, manual, or Nix-retained.
2. Hammerspoon fragment parity is handled for nix_path.lua and shade-next.lua without editing generated files at runtime.
3. Tmux nix.conf replacement or retain decision is implemented and documented.
4. Starship, shade, shade-next, karabiner, process-compose, sesame, and 1Password SSH agent generated config decisions are documented and implemented where needed for v1.
5. No launch/app reload occurs except explicitly safe validation commands.
6. lat_check passes after doc updates.

## Notes

**2026-06-23T13:03:08Z**

Implemented fragment porting for mbm-8afn:

1. Created committed static files under mise/fragments/ for 7 generated fragments:
   - mise/fragments/hammerspoon/nix_path.lua (PATH + env vars)
   - mise/fragments/hammerspoon/shade-next.lua (app info, chords, prefills)
   - mise/fragments/tmux/nix.conf (fish shell path → Brew)
   - mise/fragments/shade-next/config.toml (identity, paths, UI, keys)
   - mise/fragments/sesame/config.jsonc (piSessionPaths)
   - mise/fragments/process-compose/shortcuts.yaml
   - mise/fragments/process-compose/theme.yaml
2. Added all fragment targets to mise.toml [dotfiles] as individual file links.
3. Documented full fragment inventory in lat.md/migration/mise-parity-checklist.md:
   - 7 committed static files (implemented)
   - starship/karabiner: already static
   - shade v1, allowed_signers, 1Password SSH: Nix-retained
   - Fish: deferred to per-file reconciliation
   - Bash, surfingkeys, slk, HM plugins: deferred or Nix-retained
4. Preflight confirms all fragments classify correctly (store-flake-source/store-generated → needs-handling).
5. No destructive actions. lat_check passed. Preflight: safe=11, needs-handling=15, conflicts=0.
