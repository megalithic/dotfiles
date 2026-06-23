---
id: dot-p3kz
status: open
deps: []
links: []
created: 2026-06-23T20:16:51Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add guh.nvim for GitHub PR review scopes

Add Justin Keyes' GitHub review plugin (`justinmk/guh.nvim`) to the Nix-managed Neovim config so pinvim review workflows can use it for PR/remote GitHub review scope.

Relevant files:

- config/nvim/lua/plugins/ (new github/pr plugin file or existing git plugin file)
- home/common/packages.nix or existing package config if `gh` CLI is not already available
- lat.md/programs/neovim-pinvim.md for durable workflow notes

This is only for GitHub PR review. Local uncommitted/unpushed review continues to use CodeDiff plus existing pinvim `gpc` / `:PiFlush` annotation flow.

## Acceptance Criteria

1. `justinmk/guh.nvim` is declared in the Neovim plugin config and lazy-loads on `:Guh`.
2. At least one keymap or discoverable command path opens `:Guh` for current repo / PR context.
3. `gh auth status` is documented as a prerequisite or verified in the workflow notes.
4. Existing local diff tools (`CodeDiff`, pinvim `gpc`, `:PiFlush`) remain unchanged.
5. `devenv shell -- just home` succeeds.
6. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
7. Relevant lat.md section documents that `guh.nvim` handles PR scope while CodeDiff handles local scopes, and `lat_check` passes.
