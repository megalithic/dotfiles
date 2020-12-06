-- [ autocmds.. ] --------------------------------------------------------------

local utils = require "utils"

local cmd = vim.cmd
local exec = vim.api.nvim_exec

-- flash a highlight for yanked content
cmd('au TextYankPost * silent! lua return (not vim.v.event.visual) and lua vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })')

-- open multiple files into vertical splits
cmd([[
  if argc() > 1
    silent vertical all
  endif
  ]])
