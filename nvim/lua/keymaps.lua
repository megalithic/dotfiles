-- [ keymaps.. ] --------------------------------------------------------------

local utils = require "utils"

-- local g = vim.g
-- local go = vim.o
-- local bo = vim.bo
-- local wo = vim.wo
-- local cmd = vim.cmd
-- local exec = vim.api.nvim_exec

utils.bmap("n", "<Leader>ff", '<cmd>lua require("telescope.builtin").find_files()<CR>')
