-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

local execute, fn, cmd, go = vim.api.nvim_command, vim.fn, vim.cmd, vim.o

local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
	execute('!git clone https://github.com/wbthomason/packer.nvim '..install_path)
    execute 'packadd packer.nvim'
end

-- _G["wr"] = require("wr.global")

-- [ loaders.. ] ---------------------------------------------------------

-- cmd "runtime vimrc"
-- go.termguicolors = true

require("settings")
require("plugins")
require("autocmds")
require("keymaps")
--require("p.telescope")
--require("p.treesitter")
-- require("lc.config")
