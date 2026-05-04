---
id: dot-o2jq
status: closed
deps: []
links: []
created: 2026-05-01T21:20:18Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, git]
---
# nvim Step 5: Port neogit from nvim_legacy to git.lua

Bring back NeogitOrg/neogit using the spec from 'config/nvim_legacy/lua/plugins/git.lua:307-340' as the template. Keymaps wired in Step 8 (this ticket only adds the spec).

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 5)
Reference: 'config/nvim_legacy/lua/plugins/git.lua' lines 307-340
Independent of Steps 1–4.

## What
- Edit 'config/nvim/lua/plugins/git.lua', append a new spec block (next to the existing gitsigns/gitlinker/unclash specs):
  {
    'NeogitOrg/neogit',
    cmd = 'Neogit',
    branch = 'master',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      disable_signs = false,
      disable_hint = true,
      disable_commit_confirmation = true,
      disable_builtin_notifications = true,
      disable_insert_on_commit = false,
      fetch_after_checkout = true,
      signs = {
        section = { '', '' },
        item = { '▸', '▾' },
        hunk = { '󰐕', '󰍴' },
      },
      integrations = {
        diffview = true,
        mini_pick = true,
      },
      graph_style = 'kitty',
      process_spinner = 'true',
    },
    config = function(_, opts) require('neogit').setup(opts) end,
  }
- Do NOT port the legacy NeogitPushComplete Augroup; revisit if needed
- Do NOT add keymaps here — Step 8 handles them

## Why
- We dropped neogit when migrating from nvim_legacy; user wants it back as the porcelain UI alongside snacks pickers (snacks for fuzzy pick, neogit for full porcelain)

## Acceptance Criteria

1. 'config/nvim/lua/plugins/git.lua' contains a NeogitOrg/neogit spec with cmd = 'Neogit'
2. ':Lazy install' (or headless equivalent) installs neogit + plenary.nvim
3. Manual: in a git repo, ':Neogit' opens the status buffer
4. Manual: 'q' inside the Neogit buffer closes it cleanly
5. No errors on nvim startup ('nvim --headless +qa' clean exit)
6. Existing gitsigns / gitlinker / unclash specs unchanged (verify by running existing keymaps: ]x conflict nav, <leader>gco merge editor, etc.)

