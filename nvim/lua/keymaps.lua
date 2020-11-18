-- [ keymaps.. ] ---------------------------------------------------------------

local utils = require "utils"

-- local g = vim.g
-- local go = vim.o
-- local bo = vim.bo
-- local wo = vim.wo
-- local cmd = vim.cmd
-- local exec = vim.api.nvim_exec

-- ( telescope.nvim ) ----------------------------------------------------------

-- utils.bmap("n", "<Leader>m", '<cmd>lua require("telescope.builtin").fd()<CR>')
-- utils.bmap("n", "<Leader>f", '<cmd>lua require("telescope.builtin").git_files()<CR>')
-- utils.bmap("n", "<Leader>a", '<cmd>lua require("telescope.builtin").live_grep()<CR>')
utils.bmap("c", "<c-r><c-r>", "<Plug>(TelescopeFuzzyCommandSearch)", {noremap = false, nowait = true})
