-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

local execute, fn, cmd, go = vim.api.nvim_command, vim.fn, vim.cmd, vim.o

local install_path = fn.stdpath('data')..'/site/pack/paqs/opt/paq-nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    print "paq-nvim is NOT installed.."
    execute('!git clone https://github.com/savq/paq-nvim.git '..install_path)
    execute 'packadd paq-nvim'
else
    -- print "paq-nvim is installed.."
end

-- _G["wr"] = require("wr.global")

-- [ required.. ] --------------------------------------------------------------

require("settings")
require("plugins")
require("autocmds")
require("keymaps")

-- [ plugins.. ] ---------------------------------------------------------------

require("p.nova")
require("p.fzf")
--require("p.colorizer")
--require("p.golden_ratio")
--require("p.telescope")
--require("p.treesitter")

-- [ lsp.. ] -------------------------------------------------------------------

--require("lc.config")
