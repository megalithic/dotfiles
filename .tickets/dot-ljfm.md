---
id: dot-ljfm
status: open
deps: [dot-wj6e]
links: []
created: 2026-05-01T21:21:57Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, blink, whichkey]
---
# nvim Step 9: Whichkey groups + enable blink-ripgrep with .jj marker

Add whichkey group labels for the new <leader>j prefix and the relocated <localleader>J. Add 'mikavilpas/blink-ripgrep.nvim' as a blink.cmp source (currently absent in our config — adding from scratch with project_root_marker including .jj).

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 9)
Depends on: dot-wj6e (Step 8 — keymaps must exist before whichkey labels them meaningfully)
Reference for ripgrep spec: ~/.cache/pi-internet/github-repos/iofq/nvim.nix@master/nvim/after/plugin/plugins.lua lines 136-148 (with enabled = true instead of false)

## What

Part A — whichkey:
- Edit 'config/nvim/lua/plugins/whichkey.lua' (around lines 52-67 where group labels live), add:
  - { '<leader>j', group = 'jj' }
  - { '<localleader>J', group = 'split/join' }

Part B — blink-ripgrep:
- Edit 'config/nvim/lua/plugins/blink.lua':
  - Add 'mikavilpas/blink-ripgrep.nvim' to the 'dependencies' list of saghen/blink.cmp (sibling to 'xzbdmw/colorful-menu.nvim')
  - In opts.sources.default: add 'ripgrep' → { 'lsp', 'path', 'snippets', 'ripgrep', 'buffer' }
  - In opts.sources.providers, add a new ripgrep provider:
    ripgrep = {
      enabled = true,
      module = 'blink-ripgrep',
      name = '[rg]',
      score_offset = -10,
      async = true,
      opts = {
        project_root_marker = { '.git', '.jj' },
        backend = { use = 'gitgrep-or-ripgrep' },
      },
    },

## Why
- Discoverability: <leader>j shows 'jj' header in whichkey instead of raw keymap list
- blink-ripgrep adds project-wide grep completion to blink.cmp; works in jj-only repos via .jj marker + gitgrep-or-ripgrep fallback to plain rg

## Acceptance Criteria

1. 'rg "<leader>j\"\s*,\s*group" config/nvim/lua/plugins/whichkey.lua' shows 'jj' group entry
2. 'rg "<localleader>J\"\s*,\s*group" config/nvim/lua/plugins/whichkey.lua' shows 'split/join' group entry
3. 'rg "blink-ripgrep" config/nvim/lua/plugins/blink.lua' shows the new dependency and module references
4. 'rg "project_root_marker" config/nvim/lua/plugins/blink.lua' shows { '.git', '.jj' }
5. ':Lazy install' (or headless) installs mikavilpas/blink-ripgrep.nvim with no errors
6. Manual: 'nvim --headless +"lua print(vim.inspect(require([[blink.cmp]]).config.sources.providers.ripgrep))" +qa' shows enabled = true
7. Manual: in a jj-only repo (no .git/), open a file in insert mode and type a partial word that exists elsewhere in the project — completion menu shows '[rg]'-tagged entries (confirms .jj marker works + gitgrep-or-ripgrep falls back to rg)
8. Manual: pressing <leader>j (no follow-up) shows whichkey popup with 'jj' header listing ja/jf/jl/jh/je/jd
9. Manual: pressing <localleader>J shows 'split/join' label
10. No regressions: blink.cmp still works for lsp/path/snippets/buffer sources

