---
id: mbm-xqjv
status: closed
deps: []
links:
  [
    mbm-buez,
    mbm-c3sd,
    mbm-ju5m,
    mbm-m0rs,
    mbm-55qf,
    mbm-9ov0,
    mbm-8afn,
    mbm-qkmx,
  ]
created: 2026-06-22T20:32:31Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Audit mise migration parity against nix configuration

Compare the initial mise bootstrap files against current nix-darwin/Home Manager ownership so the migration does not silently drop important behavior. Produce/update a durable checklist that maps Nix-managed programs, services, secrets, dotfiles, macOS defaults, and special apps to mise/bootstrap/Brew/fnox/script ownership.

Context: initial migration session /Users/seth/.pi/agent/sessions/--Users-seth-.dotfiles--/2026-06-21T21-36-04-449Z_019eec1c-b361-7336-903a-78a13c758ea8.jsonl. Migration model is documented in lat.md/migration/mise-bootstrap.md.

File hints: flake.nix, hosts/, home/common/, modules/, config/, bin/, pkgs/, mise.toml, mise/, scripts/mise/, ~/.local/share/pi/docs/.dotfiles/mise-bootstrap-migration.md.

## Acceptance Criteria

1. Current nix-darwin/Home Manager owned areas are inventoried by category: packages/apps, dotfiles, fish/shell, launchd/services, secrets, macOS defaults, custom packages/apps, Pi tooling, project environments.
2. Each category has a target owner: mise bootstrap, mise dotfiles, Brew/MAS, fnox, scripts/mise, or explicitly keep under Nix for now.
3. Gaps and intentionally-deferred items are listed with rationale; settings-sync remains deferred for v1.
4. Durable docs are updated in lat.md/migration/ or ~/.local/share/pi/docs/.dotfiles/ as appropriate.
5. No bootstrap commands are applied to the host during the audit.
6. `lat_check` passes if lat.md files changed.

## Notes

**2026-06-22T21:17:35Z**

Added durable parity checklist at lat.md/migration/mise-parity-checklist.md and linked it from lat.md/migration/migration.md. Checklist covers host requirements, one-command bootstrap goals, Nix/darwin/HM responsibilities, risky apps, launchd, secrets, macOS defaults, program module backlog, and cutover blockers. No destructive bootstrap/apply/install commands run. lat_check passed.

**2026-06-22T21:29:28Z**

Updated symlink research: added symlink ownership inventory to lat.md/migration/mise-parity-checklist.md and clarified lat.md/architecture.md. Confirmed Home Manager has three distinct cases: live out-of-store config links that visually pass through /nix/store but resolve to ~/.dotfiles/config, store-backed flake source links, and generated Nix store files. Added adoption rule: follow symlink chain and classify repo-final/store-flake-source/store-generated/external-final/real-directory/real-file/missing before mise adopts any path. lat_check passed.

**2026-06-22T21:34:05Z**

Created follow-up migration tickets: mbm-55qf symlink classifier, mbm-qkmx dotfile reconciliation, mbm-8afn generated fragments, mbm-ju5m kanata/kanata-bar, mbm-buez espanso, mbm-m0rs Okta Verify, mbm-c3sd 1Password validation, mbm-9ov0 one-command bootstrap. Linked them to this audit and added deps from mbm-s5i1/mbm-nhdu where classifier/reconcile blocks safe dry-run hardening.

**2026-06-24T01:09:47Z**

Audit closeout:

- 8 of 10 cutover blockers now checked (previously 3).
- Remaining 2 are explicitly deferred:
  - Complex defaults renderer (symbolic hotkeys/text replacements) — deferred, script exists
  - Workbookpro partial-install repair — deferred, depends on mbm-z03i hostname config
- All 15 closed migration tickets implemented and validated.
- Checklist rows reflect current state: safe/Nix-retained/deferred status for all items.
- lat_check passes.
