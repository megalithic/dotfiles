local oil = require("oil")

vim.opt.conceallevel = 3
vim.opt.concealcursor = "n"
vim.opt.list = false
vim.opt.wrap = false
vim.opt.signcolumn = "no"

nnoremap("q", "<cmd>q<cr>", { desc = "oil: quit", buffer = 0 })
nnoremap("<leader>ed", "<cmd>q<cr>", { desc = "oil: quit", buffer = 0 })
nnoremap("<BS>", function() require("oil").open() end, { desc = "oil: goto parent dir", buffer = 0 })

local function find_files()
  local dir = oil.get_current_dir()
  if vim.api.nvim_win_get_config(0).relative ~= "" then vim.api.nvim_win_close(0, true) end
  mega.find_files({ cwd = dir, hidden = true })
end

local function grep()
  local dir = oil.get_current_dir()
  if vim.api.nvim_win_get_config(0).relative ~= "" then vim.api.nvim_win_close(0, true) end
  mega.grep({ cwd = dir })
end

nnoremap("<localleader>ff", find_files, "oil: find files in dir")
nnoremap("<localleader>a", grep, "oil: grep files in dir")
