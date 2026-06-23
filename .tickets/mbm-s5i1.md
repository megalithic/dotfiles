---
id: mbm-s5i1
status: open
deps: 4:1:deps: 4:1:deps: [, mbm-55qf, mbm-qkmx]
links: []
created: 2026-06-22T20:32:02Z
type: bug
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Make mise bootstrap dry-run pass

The mise bootstrap migration worktree currently has initial files under mise.toml, mise/, scripts/mise/, and lat.md/migration/. `mise bootstrap --dry-run` fails before any useful validation because the Homebrew formula lookup for `brew:yubikey-manager` returns 404. Fix package identifiers and any other first-pass bootstrap schema/package issues so dry-run reaches a complete plan or the next actionable error.

Context: primary migration session /Users/seth/.pi/agent/sessions/--Users-seth-.dotfiles--/2026-06-21T21-36-04-449Z_019eec1c-b361-7336-903a-78a13c758ea8.jsonl; continuation /Users/seth/.pi/agent/sessions/--Users-seth-.dotfiles--/2026-06-22T13-47-12-380Z_019eef95-cc7c-7fb9-b93e-27171f74fe8e.jsonl.

File hints: mise.toml [bootstrap.packages], mise/Brewfile, scripts/mise/doctor, lat.md/migration/mise-bootstrap.md.

## Acceptance Criteria

1. `mise bootstrap --dry-run` no longer fails on missing Homebrew formula `yubikey-manager`.
2. Homebrew package identifiers in `mise.toml` are verified against current Homebrew formula/cask names; invalid names are replaced or moved to the right installer path.
3. `mise tasks ls` still lists the migration tasks.
4. `scripts/mise/doctor` reports the new package-name validation or documents why validation remains manual.
5. `lat.md/migration/mise-bootstrap.md` is updated if ownership, package manager, or validation flow changes.
6. `lat_check` passes.
