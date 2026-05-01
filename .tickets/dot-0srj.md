---
id: dot-0srj
status: open
deps: []
links: []
created: 2026-05-01T21:20:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj]
---
# nvim Step 4: Replace neojj/neojjit with NicolasGB/jj.nvim

Drop 'krisajenkins/neojj' and 'JulianNymark/neojjit' specs; install 'NicolasGB/jj.nvim' (much richer feature set: pickers, annotate, vdiff, log, file_history). Spec stays minimal — keymaps land in Step 8.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 4)
Independent of Steps 1–3 (different file).

## What
- Edit 'config/nvim/lua/plugins/jj.lua':
  - Delete the 'krisajenkins/neojj' spec block (the entire { 'krisajenkins/neojj', ... } table including the active <leader>gl keymap on neojj.jj_log)
  - Delete the 'JulianNymark/neojjit' spec block (entire { 'JulianNymark/neojjit', keys = { <leader>gs ... } } table)
  - Uncomment / replace with the 'NicolasGB/jj.nvim' spec already commented at the top of the file:
    {
      'NicolasGB/jj.nvim',
      version = '*',
      config = function() require('jj').setup({}) end,
      -- keys table added in Step 8 (dot-XXXX)
    }
  - Don't add 'keys =' here — Step 8 handles all keymaps

## Why
- neojj is limited (status/log/describe/split only); neojjit is a popup wrapper
- jj.nvim provides full picker.status, picker.file_history, annotate.file, cmd.log, diff.open_vdiff{rev=...} — matches what iofq wires up

## Acceptance Criteria

1. 'rg "neojj|neojjit" config/nvim/' returns no matches (specs and keymaps gone)
2. 'config/nvim/lua/plugins/jj.lua' contains a single active spec for 'NicolasGB/jj.nvim' with config = function() require('jj').setup({}) end
3. ':Lazy install' (or 'nvim --headless +"Lazy! sync" +qa') succeeds installing jj.nvim, no errors
4. Manual: nvim opens cleanly in any directory (no jj.nvim load errors)
5. Manual: 'nvim -c ":lua print(vim.inspect(require([[jj]])))" -c qa' prints jj module table without errors
6. <leader>gl (was neojj log) and <leader>gs (was neojjit) no longer trigger anything (will be rebound in Step 8/9)

