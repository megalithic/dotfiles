---
id: mbm-qkmx
status: closed
deps: 4:1:deps: [, mbm-55qf]
links: [mbm-buez, mbm-c3sd, mbm-ju5m, mbm-xqjv, mbm-m0rs, mbm-55qf, mbm-9ov0, mbm-8afn]
created: 2026-06-22T21:33:33Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Reconcile mise dotfile targets with symlink ownership inventory

Update mise dotfile ownership based on the symlink inventory so mise does not blindly map paths that Home Manager currently generates or maps to different app support locations. This should fix obvious mismatches and document retained/manual/generated cases. File hints: mise.toml, mise/dotfiles/fish, config/espanso, config/kanata, scripts/mise/doctor, lat.md/migration/mise-parity-checklist.md.

## Acceptance Criteria

1. mise.toml [dotfiles] is updated so repo-final targets map to the same final source paths used by current Home Manager.
2. Espanso target decision is explicit: either link ~/Library/Application Support/espanso to config/espanso or document and validate a supported XDG path.
3. Fish is not treated as equivalent to current Home Manager generated fish config unless missing snippets/functions are ported or explicitly deferred.
4. Store-generated and store-flake-source paths from the inventory are not silently overwritten by mise dotfiles.
5. mise bootstrap --dry-run or the new preflight reports no unexpected dotfile conflicts for known repo-final paths.
6. lat.md/migration/mise-parity-checklist.md reflects the final dotfile target decisions.

## Notes

**2026-06-23T12:28:32Z**

Reconciled mise dotfile targets per classifier findings (mbm-55qf):

1. ~/.config/ssh → ~/.ssh/config (individual file, correct path)
2. ~/.config/espanso → ~/Library/Application Support/espanso (app support path)
3. ~/.config/kanata → split into individual .kbd file targets (macbook.kbd, macbook-disabled.kbd)
4. Fish kept as directory target with note about deferred per-file reconciliation (mbm-8afn)
5. Git files kept as-is with store-flake-source note
6. mise config kept with store-generated note
7. mise.toml [dotfiles] section documented with inline comments explaining each group's status and deferral tickets
8. scripts/mise/dotfile-preflight KNOWN_INVENTORY cleared (all now mise.toml targets)
   Preflight summary: safe=11, needs-handling=6, conflicts=0. lat_check passed. shellcheck passed.
