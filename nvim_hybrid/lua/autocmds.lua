-- [ autocmds.. ] --------------------------------------------------------------

local utils = require "utils"

local cmd = vim.cmd
local exec = vim.api.nvim_exec

-- autocmd TextYankPost * silent! lua return (not vim.v.event.visual) and require'vim.highlight'.on_yank { higroup = "IncSearch", timeout = 150, on_macro = true }
-- cmd('au TextYankPost * silent! lua vim.highlight.on_yank({ higroup = "HighlightedyankRegion", timeout = 120 })')
