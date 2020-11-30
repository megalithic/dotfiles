-- [ autocmds.. ] --------------------------------------------------------------

local utils = require "utils"
local cmd = vim.cmd

-- ( non-specific autocmds )
utils.augroup(
  "mega.general",
  function()
    -- cmd [[autocmd! * <buffer>]]
    cmd [[autocmd!]]

    -- toggle colorcolumn when in insert-mode only
    cmd [[autocmd InsertEnter * silent set colorcolumn=81]]
    cmd [[autocmd InsertLeave * if &filetype != "markdown" | silent set colorcolumn="" | endif]]

    -- flash yanked text
    cmd [[autocmd TextYankPost * silent! lua return (not vim.v.event.visual) and vim.highlight.on_yank { higroup = "IncSearch", timeout = 150, on_macro = true }]]
  end
)
