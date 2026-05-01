---
id: dot-wj6e
status: open
deps: [dot-0srj, dot-o2jq, dot-1lg6]
links: []
created: 2026-05-01T21:21:33Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj, keymaps]
---
# nvim Step 8: Wire all jj/git keymaps + relocate treesj <leader>j → <localleader>J

Wire all the keymaps for jj.nvim, neogit, freed snacks git pickers, the unclash conflicts picker, and relocate treesj to free up the <leader>j prefix.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 8)
Depends on:
- dot-0srj (Step 4 — jj.nvim plugin must be installed before its keymaps fire)
- dot-o2jq (Step 5 — neogit plugin)
- dot-1lg6 (Step 6 — :Diffedit user command)

## What
- Edit 'config/nvim/lua/plugins/treesj.lua': change keymap '<leader>j' → '<localleader>J', update desc accordingly
- Edit 'config/nvim/lua/plugins/jj.lua' (NicolasGB/jj.nvim spec from Step 4): add 'keys' table with lazy keymaps:
  - '<leader>ja' → require('jj.annotate').file (desc 'jj: annotate/blame current file')
  - '<leader>jf' → require('jj.picker').status (desc 'jj: status picker')
  - '<leader>jl' → require('jj.cmd').log (desc 'jj: log')
  - '<leader>jh' → require('jj.picker').file_history (desc 'jj: file history')
  - '<leader>je' → require('utils.jj').diffedit (desc 'jj: diffedit')
  - '<leader>jd' → function() require('jj.diff').open_vdiff{rev='trunk()'} end (desc 'jj: vdiff vs trunk')
- Edit 'config/nvim/lua/plugins/git.lua':
  - In the unclash spec's 'init' or 'keys' (whichever fits the existing shape — currently uses 'init'): add a 'keys' table with { '<leader>fx', function() require('unclash.snacks').pick() end, desc = 'Pick conflicts' }
  - Append to the new neogit spec from Step 5 a 'keys' table:
    - '<leader>gg' → function() require('neogit').open() end (desc 'neogit: open status')
    - '<leader>gS' → function() require('neogit').open() end (desc 'neogit: open status')
    - '<localleader>gc' → function() require('neogit').open({ 'commit', '-v' }) end (desc 'neogit: commit')
- Edit 'config/nvim/lua/plugins/snacks/init.lua' (around lines 487-492 — the commented git pickers):
  - Uncomment '<leader>gs' → Snacks.picker.git_status
  - Uncomment '<leader>gl' → Snacks.picker.git_log (use gl, NOT gc — gc collides with localleader>gc neogit-commit muscle memory)
  - Uncomment '<leader>gb' → Snacks.picker.git_branches
  - Leave '<leader>gd' commented (mini.diff overlay toggle owns it)
  - Leave '<leader>gS' / '<leader>gG' (pickaxe variants) commented for now

## Why
- Free <leader>j prefix for jj.nvim namespace (was treesj single-chord)
- Wire the rich jj.nvim picker/cmd surface
- Restore neogit access via familiar <leader>gg / <leader>gS muscle memory
- <leader>fx for unclash conflict picker matches madmaxieee 0cd8c87

## Acceptance Criteria

1. 'rg "<leader>j\"" config/nvim/lua/plugins/treesj.lua' returns no matches (relocated)
2. 'rg "<localleader>J\"" config/nvim/lua/plugins/treesj.lua' shows the new keymap
3. 'rg "<leader>j[adfehl]" config/nvim/lua/plugins/jj.lua' shows the 6 jj.nvim keymaps
4. 'rg "<leader>fx" config/nvim/lua/plugins/git.lua' shows the unclash pick keymap
5. 'rg "<leader>g[gSc]" config/nvim/lua/plugins/git.lua' shows the neogit keymaps
6. 'rg "<leader>g[slb]" config/nvim/lua/plugins/snacks/init.lua | rg -v "^.*-- "' shows uncommented git_status, git_log, git_branches keymaps
7. Manual in a jj repo: <leader>jf opens jj status picker; <leader>jl opens log; <leader>ja annotate; <leader>je triggers :Diffedit; <leader>jd vdiff vs trunk; <leader>jh file history
8. Manual: <localleader>J on a function/list line triggers treesj split/join
9. Manual: <leader>gg and <leader>gS open Neogit status; <localleader>gc opens commit buffer
10. Manual: <leader>gs opens snacks git_status picker; <leader>gl opens git_log; <leader>gb opens git_branches
11. Manual: in a repo with conflicts, <leader>fx opens unclash snacks picker
12. No regressions: existing <leader>gd (mini.diff toggle), ]h/[h hunk nav, ih textobject, <leader>hr reset, <localleader>c{c,o,i,t,b} unclash accept, ]x/[x conflict nav all still work

