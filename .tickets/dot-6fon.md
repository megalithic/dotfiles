---
id: dot-6fon
status: closed
deps: 4:1:deps: [, dot-e5sy]
links: []
created: 2026-06-09T15:10:56Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Add shade-next dotfiles module and generated config wiring

In ~/.dotfiles, add home-manager integration for shade-next without replacing current shade. File hints: create home/common/programs/shade-next/default.nix, update package wiring if needed in home/common/packages.nix, and rely on auto-import behavior from home/common/default.nix. Generate ~/.config/shade-next/config.toml and any data-only Hammerspoon fragment paths from Nix using self-based references.

## Acceptance Criteria

1. home/common/programs/shade-next/default.nix exists and follows repo Nix conventions.
2. Home-manager generates ~/.config/shade-next/config.toml or equivalent config path from Nix.
3. Any generated Hammerspoon fragment stays data-only.
4. timeout 600 just validate home passes after changes.
5. Current shade package/module remains usable during transition.
