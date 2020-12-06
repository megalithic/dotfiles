-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

-- vim.g.mapleader = ","
-- vim.g.maplocalleader = ","
-- vim.fn.nvim_set_keymap('n',' ','',{noremap = true})
-- vim.fn.nvim_set_keymap('x',' ','',{noremap = true})

_G["mg"] = require("global")

-- function createdir()
--   local data_dir = {
--     global.cache_dir..'backup',
--     global.cache_dir..'session',
--     global.cache_dir..'swap',
--     global.cache_dir..'tags',
--     global.cache_dir..'undo'
--   }
--   -- There only check once that If cache_dir exists
--   -- Then I don't want to check subs dir exists
--   if not fs.isdir(global.cache_dir) then
--     os.execute("mkdir -p " .. global.cache_dir)
--     for _,v in pairs(data_dir) do
--       if not global.isdir(v) then
--         os.execute("mkdir -p " .. v)
--       end
--     end
--   end
-- end

require("settings")
require("plugins")
require("autocmds")
require("keymaps")

-- [ plugins.. ] ---------------------------------------------------------------

-- require("p.fzf")
-- require("p.telescope")
-- require("p.colorizer")
-- require("p.golden_ratio")
-- require("p.treesitter")

-- [ lsp.. ] -------------------------------------------------------------------

--require("lc.config")
